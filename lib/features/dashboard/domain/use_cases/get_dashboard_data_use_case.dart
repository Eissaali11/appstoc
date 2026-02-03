import '../repositories/dashboard_repository.dart';

class GetDashboardDataUseCase {
  final DashboardRepository repository;

  GetDashboardDataUseCase(this.repository);

  Future<Map<String, dynamic>> call() async {
    return await repository.getDashboardData();
  }
}
