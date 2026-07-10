import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardDataUseCase {
  final DashboardRepository repository;

  GetDashboardDataUseCase(this.repository);

  Future<DashboardData> call(String userId) async {
    return await repository.getDashboardData(userId);
  }
}
