import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/devices_repository.dart';
import '../models/received_device.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  Dio get _dio => Get.find<Dio>();

  @override
  Future<void> submitDevice(ReceivedDevice device) async {
    try {
      await _dio.post(
        ApiEndpoints.receivedDevices,
        data: device.toJson(),
      );
    } catch (e) {
      throw Exception('فشل إرسال بيانات الجهاز: ${e.toString()}');
    }
  }

  @override
  Future<List<ReceivedDevice>> getReceivedDevices() async {
    try {
      final response = await _dio.get(ApiEndpoints.receivedDevices);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => ReceivedDevice.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب الأجهزة المستلمة: ${e.toString()}');
    }
  }

  @override
  Future<int> getPendingReceivedDevicesCount() async {
    try {
      final response =
          await _dio.get(ApiEndpoints.receivedDevicesPendingCount);
      return (response.data['count'] as int?) ?? 0;
    } catch (e) {
      throw Exception('فشل جلب عدد الأجهزة المعلقة: ${e.toString()}');
    }
  }
}
