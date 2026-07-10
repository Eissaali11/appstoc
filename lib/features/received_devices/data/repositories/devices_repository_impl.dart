import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../shared/models/item_type.dart';
import '../../domain/repositories/devices_repository.dart';
import '../models/received_device.dart';
import '../models/withdrawn_device.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  final ApiClient apiClient;

  DevicesRepositoryImpl(this.apiClient);

  @override
  Future<void> submitDevice(ReceivedDevice device) async {
    try {
      await apiClient.post(
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
      final response = await apiClient.get(ApiEndpoints.receivedDevices);
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
          await apiClient.get(ApiEndpoints.receivedDevicesPendingCount);
      return (response.data['count'] as int?) ?? 0;
    } catch (e) {
      throw Exception('فشل جلب عدد الأجهزة المعلقة: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemType>> getItemTypes() async {
    try {
      final response = await apiClient.get(ApiEndpoints.activeItemTypes);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب أنواع السلع: ${e.toString()}');
    }
  }

  @override
  Future<void> deliverDevice(String barcode) async {
    try {
      await apiClient.post(
        '/api/received-devices/deliver',
        data: {'barcode': barcode},
      );
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        }
      }
      throw Exception(message);
    }
  }

  @override
  Future<void> submitWithdrawnDevice(WithdrawnDevice device) async {
    try {
      await apiClient.post(
        ApiEndpoints.withdrawnDevices,
        data: device.toJson(),
      );
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        }
      }
      throw Exception('فشل إرسال بيانات سحب الجهاز: $message');
    }
  }

  @override
  Future<List<WithdrawnDevice>> getWithdrawnDevices() async {
    try {
      final response = await apiClient.get(ApiEndpoints.withdrawnDevices);
      if (response.data is List) {
        return (response.data as List)
            .map((e) => WithdrawnDevice.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب الأجهزة المسحوبة: ${e.toString()}');
    }
  }
}

