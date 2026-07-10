import '../repositories/dashboard_repository.dart';

class ConfirmTransferReceiptUseCase {
  final DashboardRepository repository;

  ConfirmTransferReceiptUseCase(this.repository);

  Future<void> call(String transferId, List<String> serials) async {
    return await repository.confirmTransferReceipt(transferId, serials);
  }
}
