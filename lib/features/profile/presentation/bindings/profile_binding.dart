import 'package:get/get.dart';

import '../../../../core/api/api_client.dart';
import '../../data/datasources/employee_profile_remote_data_source.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeeProfileRemoteDataSource>(
      () => EmployeeProfileRemoteDataSource(Get.find<ApiClient>()),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(Get.find<EmployeeProfileRemoteDataSource>()),
    );
  }
}
