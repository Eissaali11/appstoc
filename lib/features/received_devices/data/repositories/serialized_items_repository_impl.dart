import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/serialized_items_repository.dart';
import '../models/serialized_item.dart';

class SerializedItemsRepositoryImpl implements SerializedItemsRepository {
  final ApiClient apiClient;
  static const String _draftBoxName = 'serialized_items_drafts';

  SerializedItemsRepositoryImpl(this.apiClient);

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_draftBoxName)) {
      return await Hive.openBox(_draftBoxName);
    }
    return Hive.box(_draftBoxName);
  }

  @override
  Future<SerializedItem> scanIn({
    required String serialNumber,
    required String itemTypeId,
    String? carrierName,
    String? simPackageType,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.scanIn,
        data: {
          'serialNumber': serialNumber,
          'itemTypeId': itemTypeId,
          if (carrierName != null) 'carrierName': carrierName,
          if (simPackageType != null) 'simPackageType': simPackageType,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        return SerializedItem.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('استجابة غير صالحة من السيرفر');
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<SerializedItem> scanOut({
    required String serialNumber,
    required String receiverName,
    required String orderNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.scanOut,
        data: {
          'serialNumber': serialNumber,
          'receiverName': receiverName,
          'orderNumber': orderNumber,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      if (response.data != null && response.data['data'] != null) {
        return SerializedItem.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      throw Exception('استجابة غير صالحة من السيرفر');
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }

  @override
  Future<SerializedItem?> lookup(String serialNumber) async {
    try {
      final response = await apiClient.get(ApiEndpoints.lookup(serialNumber));
      if (response.data != null && response.data['data'] != null) {
        return SerializedItem.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // If 404, we return null (item not found in database)
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(_handleError(e));
    }
  }

  // --- HIVE LOCAL CACHING ---

  @override
  Future<void> cacheScanInDraft(Map<String, dynamic> draft) async {
    final box = await _getBox();
    final List<dynamic> rawList = box.get('scan_in_drafts') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    
    // Check if duplicate serialNumber
    list.removeWhere((item) => item['serialNumber'] == draft['serialNumber']);
    list.add(draft);
    
    await box.put('scan_in_drafts', list);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedScanInDrafts() async {
    final box = await _getBox();
    final List<dynamic> rawList = box.get('scan_in_drafts') ?? [];
    return List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  @override
  Future<void> cacheScanOutDraft(Map<String, dynamic> draft) async {
    final box = await _getBox();
    final List<dynamic> rawList = box.get('scan_out_drafts') ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    
    // Check if duplicate serialNumber
    list.removeWhere((item) => item['serialNumber'] == draft['serialNumber']);
    list.add(draft);
    
    await box.put('scan_out_drafts', list);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedScanOutDrafts() async {
    final box = await _getBox();
    final List<dynamic> rawList = box.get('scan_out_drafts') ?? [];
    return List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  @override
  Future<void> removeDraft(String serialNumber, {required bool isScanIn}) async {
    final box = await _getBox();
    final key = isScanIn ? 'scan_in_drafts' : 'scan_out_drafts';
    final List<dynamic> rawList = box.get(key) ?? [];
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      rawList.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    
    list.removeWhere((item) => item['serialNumber'] == serialNumber);
    await box.put(key, list);
  }

  @override
  Future<void> clearAllDrafts() async {
    final box = await _getBox();
    await box.clear();
  }

  // --- HELPER ERROR HANDLER ---

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response?.data;
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      return 'خطأ في الاتصال بالخادم: ${error.message}';
    }
    return error.toString();
  }
}
