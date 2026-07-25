import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/repositories/neoleap_leads_repository.dart';
import '../models/lead_model.dart';

class NeoleapLeadsRepositoryImpl implements NeoleapLeadsRepository {
  final Dio dio;
  static const String _leadsBoxName = 'neoleap_leads_box';
  static const String _regionsBoxName = 'neoleap_regions_box';

  NeoleapLeadsRepositoryImpl({required this.dio});

  Future<Box<String>> _openLeadsBox() async {
    return await Hive.openBox<String>(_leadsBoxName);
  }

  Future<Box<String>> _openRegionsBox() async {
    return await Hive.openBox<String>(_regionsBoxName);
  }

  // ── Haversine Distance Calculation (km) ─────────────────────────────────
  double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // Earth radius in km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;

  @override
  Future<Either<Exception, List<LeadEntity>>> getAllLeads() async {
    try {
      final box = await _openLeadsBox();
      final List<LeadEntity> list = [];
      for (final key in box.keys) {
        final jsonStr = box.get(key);
        if (jsonStr != null) {
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          list.add(LeadModel.fromJson(jsonMap));
        }
      }
      // Sort by discoveredAt descending
      list.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
      return Right(list);
    } catch (e) {
      return Left(Exception('Failed to load leads: $e'));
    }
  }

  @override
  Future<Either<Exception, DiscoveryJobResult>> discoverNearbyLeads({
    required double originLat,
    required double originLng,
    required int radiusKm,
    required List<String> categories,
    required String apiKey,
    required List<Map<String, dynamic>> regions,
    Function(int currentCell, int totalCells, int placesFound)? onProgress,
  }) async {
    try {
      final box = await _openLeadsBox();

      // Gate 1 & Gate 2: Delegates Geo Discovery to Backend API Proxy
      try {
        final response = await dio.post(
          '/api/leads/discovery/jobs',
          data: {
            'latitude': originLat,
            'longitude': originLng,
            'radiusKm': radiusKm,
            'categories': categories.isNotEmpty ? categories : ['restaurant'],
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Poll for completion or fetch nearby leads from Backend
          final nearbyResp = await dio.get(
            '/api/leads/nearby',
            queryParameters: {
              'latitude': originLat,
              'longitude': originLng,
              'radiusKm': radiusKm,
            },
          );

          if (nearbyResp.statusCode == 200) {
            final items = nearbyResp.data['leads'] as List<dynamic>? ?? [];
            for (final item in items) {
              final lead = LeadModel.fromJson(item as Map<String, dynamic>);
              await box.put(lead.id, jsonEncode(lead.toJson()));
            }
          }
        }
      } catch (backendErr) {
        // Fallback gracefully to offline local cache if server is unreachable
      }

      final allLeadsResult = await getAllLeads();
      final List<LeadEntity> leads = allLeadsResult.fold((_) => [], (l) => l);
      leads.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return Right(DiscoveryJobResult(
        jobId: 'LDJ-${DateTime.now().millisecondsSinceEpoch}',
        status: 'COMPLETED',
        radiusKm: radiusKm,
        totalCellsProcessed: 1,
        totalPlacesFound: leads.length,
        uniquePlacesDiscovered: leads.length,
        newLeadsAdded: leads.length,
        duplicatesSkipped: 0,
        leads: leads,
      ));
    } catch (e) {
      return Left(Exception('Geo discovery job failed: $e'));
    }
  }

  @override
  Future<Either<Exception, List<LeadEntity>>> searchPlaces({
    required String apiKey,
    required String query,
    required List<Map<String, dynamic>> regions,
    required int radius,
    String? referer,
  }) async {
    final double defaultLat = regions.isNotEmpty ? (regions.first['latitude'] as double) : 24.7136;
    final double defaultLng = regions.isNotEmpty ? (regions.first['longitude'] as double) : 46.6753;

    final jobRes = await discoverNearbyLeads(
      originLat: defaultLat,
      originLng: defaultLng,
      radiusKm: (radius / 1000).round().clamp(1, 150),
      categories: [query],
      apiKey: apiKey,
      regions: regions,
    );

    return jobRes.fold(
      (err) => Left(err),
      (res) => Right(res.leads),
    );
  }

  @override
  Future<Either<Exception, void>> markLeadAsSent(String leadId) async {
    return updateLeadStatus(leadId, LeadStatus.contacted);
  }

  @override
  Future<Either<Exception, void>> updateLeadPhone(String leadId, String phone) async {
    try {
      final box = await _openLeadsBox();
      final jsonStr = box.get(leadId);
      if (jsonStr != null) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final currentLead = LeadModel.fromJson(jsonMap);
        final updatedLead = currentLead.copyWith(phone: phone);
        await box.put(leadId, jsonEncode(LeadModel.fromEntity(updatedLead).toJson()));
      }
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to update phone: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    try {
      final box = await _openLeadsBox();
      final jsonStr = box.get(leadId);
      if (jsonStr != null) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final currentLead = LeadModel.fromJson(jsonMap);
        final bool isSent = (newStatus == LeadStatus.contacted || newStatus == LeadStatus.visited || newStatus == LeadStatus.won);
        final updatedLead = currentLead.copyWith(
          leadStatus: newStatus,
          isSent: isSent,
          sentAt: isSent ? DateTime.now() : currentLead.sentAt,
        );
        await box.put(leadId, jsonEncode(LeadModel.fromEntity(updatedLead).toJson()));

        // Also notify backend server of status transition
        try {
          await dio.post('/api/leads/$leadId/change-status', data: {
            'newStatus': newStatus.name,
          });
        } catch (_) {}
      }
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to update lead status: $e'));
    }
  }

  @override
  Future<Either<Exception, List<RegionEntity>>> getSelectedRegions() async {
    try {
      final box = await _openRegionsBox();
      final List<RegionEntity> selected = [];
      for (final region in RegionEntity.saudiRegions) {
        final isSavedSelected = box.get(region.name) == 'true';
        if (isSavedSelected) {
          selected.add(RegionEntity(
            name: region.name,
            emoji: region.emoji,
            latitude: region.latitude,
            longitude: region.longitude,
            isSelected: true,
          ));
        }
      }
      return Right(selected);
    } catch (e) {
      return Left(Exception('Failed to load regions: $e'));
    }
  }

  @override
  Future<void> saveSelectedRegions(List<RegionEntity> regions) async {
    try {
      final box = await _openRegionsBox();
      await box.clear();
      for (final r in regions) {
        await box.put(r.name, 'true');
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Future<Either<Exception, String>> exportToCSV(List<LeadEntity> leads) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Google Place ID,Name,Category,Phone,Address,Rating,Rating Count,Status,Distance (km),Latitude,Longitude,Discovered At');
      
      for (final lead in leads) {
        final gId = _escapeCsv(lead.googlePlaceId);
        final name = _escapeCsv(lead.name);
        final cat = _escapeCsv(lead.category);
        final phone = _escapeCsv(lead.phone ?? '');
        final address = _escapeCsv(lead.formattedAddress ?? '');
        final rating = lead.rating?.toString() ?? '';
        final count = lead.ratingCount?.toString() ?? '';
        final status = _escapeCsv(lead.leadStatus.labelAr);
        final dist = lead.distanceKm.toStringAsFixed(2);
        final lat = lead.latitude.toString();
        final lng = lead.longitude.toString();
        final date = lead.discoveredAt.toIso8601String();

        buffer.writeln('$gId,$name,$cat,$phone,$address,$rating,$count,$status,$dist,$lat,$lng,$date');
      }
      
      return Right(buffer.toString());
    } catch (e) {
      return Left(Exception('Failed to generate CSV: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteLead(String leadId) async {
    try {
      final box = await _openLeadsBox();
      await box.delete(leadId);
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to delete lead: $e'));
    }
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
