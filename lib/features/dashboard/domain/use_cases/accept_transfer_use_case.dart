import '../repositories/dashboard_repository.dart';

class AcceptTransferUseCase {
  final DashboardRepository repository;

  AcceptTransferUseCase(this.repository);

  Future<void> call(String transferId) async {
    return await repository.acceptTransfer(transferId);
  }
}
