import 'package:get/get.dart';
import '../../data/repositories/stock_transfer_repository_impl.dart';
import '../../domain/repositories/stock_transfer_repository.dart';
import '../controllers/stock_transfer_controller.dart';

class StockTransferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockTransferRepository>(
      () => StockTransferRepositoryImpl(),
    );
    Get.lazyPut<StockTransferController>(
      () => StockTransferController(
        repository: Get.find<StockTransferRepository>(),
      ),
    );
  }
}
