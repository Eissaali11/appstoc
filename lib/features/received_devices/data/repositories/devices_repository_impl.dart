import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/devices_repository.dart';
import '../models/received_device.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  @override
  Future<void> submitDevice(ReceivedDevice device) async {
    try {
      final dio = Get.find<Dio>();
      await dio.post(
        ApiEndpoints.receivedDevices,
        data: device.toJson(),
      );
    } catch (e) {
      throw Exception('فشل إرسال بيانات الجهاز: ${e.toString()}');
    }
  }
}
