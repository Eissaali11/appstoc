import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/neoleap_leads_repository.dart';
import '../../data/repositories/neoleap_leads_repository_impl.dart';
import '../controllers/neoleap_leads_controller.dart';

class NeoleapLeadsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NeoleapLeadsRepository>(
      () => NeoleapLeadsRepositoryImpl(dio: Get.find<Dio>()),
    );
    Get.lazyPut<NeoleapLeadsController>(
      () => NeoleapLeadsController(repository: Get.find<NeoleapLeadsRepository>()),
    );
  }
}
