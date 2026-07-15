import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import 'courier_requests_repository.dart';
import '../models/courier_request_model.dart';

class CourierRequestsRepositoryImpl implements CourierRequestsRepository {
  final ApiClient apiClient;

  CourierRequestsRepositoryImpl(this.apiClient);

  @override
  Future<List<CourierRequest>> getRequests({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }
      final response = await apiClient.get('/api/courier/requests', queryParameters: queryParams);
      if (response.data != null && response.data['rows'] is List) {
        return (response.data['rows'] as List)
            .map((e) => CourierRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب الطلبات: ${e.toString()}');
    }
  }

  @override
  Future<CourierRequest> getRequest(int id) async {
    try {
      final response = await apiClient.get('/api/courier/requests/$id');
      return CourierRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل جلب الطلب: ${e.toString()}');
    }
  }

  @override
  Future<List<CourierRequestItem>> getRequestItems(int requestId) async {
    try {
      final response = await apiClient.get('/api/courier/requests/$requestId/items');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => CourierRequestItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب عناصر الطلب: ${e.toString()}');
    }
  }

  @override
  Future<CourierRequest> acceptRequest(int requestId) async {
    try {
      final response = await apiClient.post('/api/courier/requests/$requestId/accept');
      return CourierRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل قبول الطلب: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> scanRequestItem(int requestId, String serial) async {
    try {
      final response = await apiClient.post(
        '/api/courier/requests/$requestId/scan',
        data: {'serial': serial},
      );
      return response.data as Map<String, dynamic>;
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
  Future<CourierRequest> confirmReceiving(
    int requestId, {
    List<Map<String, dynamic>>? itemStatuses,
    Map<String, dynamic>? sessionMetadata,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/courier/requests/$requestId/confirm-receiving',
        data: {
          'itemStatuses': itemStatuses,
          'sessionMetadata': sessionMetadata,
        },
      );
      return CourierRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        }
      }
      throw Exception('فشل تأكيد الاستلام: $message');
    }
  }

  @override
  Future<CourierRequest> startTask(int requestId) async {
    try {
      final response = await apiClient.post('/api/courier/requests/$requestId/start-task');
      return CourierRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        }
      }
      throw Exception('فشل بدء المهمة: $message');
    }
  }

  @override
  Future<void> startRoute(int requestId) async {
    try {
      await apiClient.post('/api/courier/requests/$requestId/start-route');
    } catch (e) {
      throw Exception('فشل بدء التحرك: ${e.toString()}');
    }
  }

  @override
  Future<void> arriveCustomer(int requestId) async {
    try {
      await apiClient.post('/api/courier/requests/$requestId/arrive-customer');
    } catch (e) {
      throw Exception('فشل تأكيد الوصول للعميل: ${e.toString()}');
    }
  }

  @override
  Future<void> startInstallation(int requestId) async {
    try {
      await apiClient.post('/api/courier/requests/$requestId/start-installation');
    } catch (e) {
      throw Exception('فشل تأكيد بدء التركيب: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> submitExecutionAttempt(int requestId, Map<String, dynamic> attemptData) async {
    try {
      final response = await apiClient.post(
        '/api/courier/requests/$requestId/execution-attempts',
        data: attemptData,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        }
      }
      throw Exception('فشل إرسال تقرير الزيارة: $message');
    }
  }

  @override
  Future<Map<String, dynamic>> serialLookup(String serial) async {
    try {
      final response = await apiClient.post(
        '/api/courier/serial-lookup',
        data: {'sn': serial},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      String message = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        }
      }
      throw Exception('فشل الاستعلام عن الرقم التسلسلي: $message');
    }
  }
}
