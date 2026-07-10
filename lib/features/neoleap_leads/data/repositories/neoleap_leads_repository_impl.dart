import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
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
      return Right(list);
    } catch (e) {
      return Left(Exception('Failed to load leads: $e'));
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
    try {
      final List<LeadModel> fetchedLeads = [];
      final box = await _openLeadsBox();

      for (final region in regions) {
        final lat = region['latitude'] as double;
        final lng = region['longitude'] as double;

        final response = await dio.get(
          'https://maps.googleapis.com/maps/api/place/textsearch/json',
          queryParameters: {
            'query': query,
            'location': '$lat,$lng',
            'radius': radius,
            'key': apiKey,
          },
          options: Options(
            headers: {
              if (referer != null && referer.isNotEmpty) ...{
                'Referer': referer,
                'Origin': referer,
              },
            },
          ),
        );

        if (response.statusCode == 200) {
          final results = response.data['results'] as List<dynamic>?;
          if (results != null) {
            for (final result in results) {
              final String id = result['place_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
              final String name = result['name'] as String? ?? 'غير معروف';
              final String? address = result['formatted_address'] as String?;
              final double? rating = (result['rating'] as num?)?.toDouble();
              
              final geometry = result['geometry'] as Map<String, dynamic>?;
              final location = geometry?['location'] as Map<String, dynamic>?;
              final double latitude = (location?['lat'] as num? ?? lat).toDouble();
              final double longitude = (location?['lng'] as num? ?? lng).toDouble();

              // Check if we already have it in local DB
              final existingJson = box.get(id);
              if (existingJson != null) {
                // Keep the existing one (preserving 'isSent' and phone number status)
                final jsonMap = jsonDecode(existingJson) as Map<String, dynamic>;
                fetchedLeads.add(LeadModel.fromJson(jsonMap));
              } else {
                final newLead = LeadModel(
                  id: id,
                  name: name,
                  phone: null, // Google text search doesn't return phone number, will be input manually or edited
                  address: address,
                  rating: rating,
                  isSent: false,
                  latitude: latitude,
                  longitude: longitude,
                );
                
                // Save immediately to local DB
                await box.put(id, jsonEncode(newLead.toJson()));
                fetchedLeads.add(newLead);
              }
            }
          }
        } else {
          return Left(Exception('Google API returned status code: ${response.statusCode}'));
        }
      }

      return Right(fetchedLeads);
    } catch (e) {
      return Left(Exception('Places search failed: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> markLeadAsSent(String leadId) async {
    try {
      final box = await _openLeadsBox();
      final jsonStr = box.get(leadId);
      if (jsonStr != null) {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final currentLead = LeadModel.fromJson(jsonMap);
        final updatedLead = currentLead.copyWith(
          isSent: true,
          sentAt: DateTime.now(),
        );
        await box.put(leadId, jsonEncode(LeadModel.fromEntity(updatedLead).toJson()));
      }
      return const Right(null);
    } catch (e) {
      return Left(Exception('Failed to mark lead as sent: $e'));
    }
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
      // Fail silently
    }
  }

  @override
  Future<Either<Exception, String>> exportToCSV(List<LeadEntity> leads) async {
    try {
      final buffer = StringBuffer();
      // CSV Header
      buffer.writeln('ID,Name,Phone,Address,Rating,Is Sent,Sent At,Latitude,Longitude');
      
      for (final lead in leads) {
        final id = _escapeCsv(lead.id);
        final name = _escapeCsv(lead.name);
        final phone = _escapeCsv(lead.phone ?? '');
        final address = _escapeCsv(lead.address ?? '');
        final rating = lead.rating?.toString() ?? '';
        final isSent = lead.isSent ? 'Yes' : 'No';
        final sentAt = lead.sentAt?.toIso8601String() ?? '';
        final lat = lead.latitude.toString();
        final lng = lead.longitude.toString();

        buffer.writeln('$id,$name,$phone,$address,$rating,$isSent,$sentAt,$lat,$lng');
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
