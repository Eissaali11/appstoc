import '../repositories/dashboard_repository.dart';

class RejectTransferUseCase {
  final DashboardRepository repository;

  RejectTransferUseCase(this.repository);

  Future<void> call(String transferId, {String? reason}) async {
    return await repository.rejectTransfer(transferId, reason: reason);
  }
}
