import '../models/courier_request_model.dart';

abstract class CourierRequestsRepository {
  Future<List<CourierRequest>> getRequests({String? status});
  Future<CourierRequest> getRequest(int id);
  Future<List<CourierRequestItem>> getRequestItems(int requestId);
  Future<CourierRequest> acceptRequest(int requestId);
  Future<Map<String, dynamic>> scanRequestItem(int requestId, String serial);
  Future<CourierRequest> confirmReceiving(int requestId, {List<Map<String, dynamic>>? itemStatuses, Map<String, dynamic>? sessionMetadata});
  Future<CourierRequest> startTask(int requestId);
  Future<void> startRoute(int requestId);
  Future<void> arriveCustomer(int requestId);
  Future<void> startInstallation(int requestId);
  Future<Map<String, dynamic>> submitExecutionAttempt(int requestId, Map<String, dynamic> attemptData);
  Future<Map<String, dynamic>> serialLookup(String serial);
}
