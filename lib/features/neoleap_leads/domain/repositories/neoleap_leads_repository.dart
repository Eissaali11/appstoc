import '../../../../core/utils/either.dart';
import '../entities/lead_entity.dart';
import '../entities/region_entity.dart';

abstract class NeoleapLeadsRepository {
  Future<Either<Exception, List<LeadEntity>>> getAllLeads();
  
  Future<Either<Exception, List<LeadEntity>>> searchPlaces({
    required String apiKey,
    required String query,
    required List<Map<String, dynamic>> regions,
    required int radius,
    String? referer,
  });

  Future<Either<Exception, void>> markLeadAsSent(String leadId);
  
  Future<Either<Exception, void>> updateLeadPhone(String leadId, String phone);
  
  Future<Either<Exception, List<RegionEntity>>> getSelectedRegions();
  
  Future<void> saveSelectedRegions(List<RegionEntity> regions);
  
  Future<Either<Exception, String>> exportToCSV(List<LeadEntity> leads);

  Future<Either<Exception, void>> deleteLead(String leadId);
}
