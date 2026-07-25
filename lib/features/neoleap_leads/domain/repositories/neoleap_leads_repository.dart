import '../../../../core/utils/either.dart';
import '../entities/lead_entity.dart';
import '../entities/region_entity.dart';

/// Discovery Job Execution Metrics
class DiscoveryJobResult {
  final String jobId;
  final String status; // COMPLETED, CANCELLED, FAILED
  final int radiusKm;
  final int totalCellsProcessed;
  final int totalPlacesFound;
  final int uniquePlacesDiscovered;
  final int newLeadsAdded;
  final int duplicatesSkipped;
  final List<LeadEntity> leads;

  DiscoveryJobResult({
    required this.jobId,
    required this.status,
    required this.radiusKm,
    required this.totalCellsProcessed,
    required this.totalPlacesFound,
    required this.uniquePlacesDiscovered,
    required this.newLeadsAdded,
    required this.duplicatesSkipped,
    required this.leads,
  });
}

abstract class NeoleapLeadsRepository {
  Future<Either<Exception, List<LeadEntity>>> getAllLeads();
  
  Future<Either<Exception, DiscoveryJobResult>> discoverNearbyLeads({
    required double originLat,
    required double originLng,
    required int radiusKm,
    required List<String> categories,
    required String apiKey,
    required List<Map<String, dynamic>> regions,
    Function(int currentCell, int totalCells, int placesFound)? onProgress,
  });

  Future<Either<Exception, List<LeadEntity>>> searchPlaces({
    required String apiKey,
    required String query,
    required List<Map<String, dynamic>> regions,
    required int radius,
    String? referer,
  });

  Future<Either<Exception, void>> markLeadAsSent(String leadId);
  
  Future<Either<Exception, void>> updateLeadPhone(String leadId, String phone);

  Future<Either<Exception, void>> updateLeadStatus(String leadId, LeadStatus newStatus);
  
  Future<Either<Exception, List<RegionEntity>>> getSelectedRegions();
  
  Future<void> saveSelectedRegions(List<RegionEntity> regions);
  
  Future<Either<Exception, String>> exportToCSV(List<LeadEntity> leads);

  Future<Either<Exception, void>> deleteLead(String leadId);
}
