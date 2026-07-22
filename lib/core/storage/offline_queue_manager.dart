import 'package:hive/hive.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/received_devices/domain/repositories/devices_repository.dart';
import '../../features/received_devices/data/repositories/devices_repository_impl.dart';
import '../../features/received_devices/data/models/received_device.dart';
import '../../features/received_devices/data/models/withdrawn_device.dart';
import '../../features/courier_requests/data/repositories/courier_requests_repository.dart';
import '../../features/courier_requests/data/repositories/courier_requests_repository_impl.dart';
import '../api/api_client.dart';

abstract class OfflineQueueRepository {
  Future<void> queueTransaction({required String type, required Map<String, dynamic> data});
  Future<List<Map<String, dynamic>>> getQueue();
  Future<int> getPendingCount();
  Future<void> removeTransaction(int index);
  Future<void> clearQueue();
  Future<bool> processQueue();
}

class OfflineQueueRepositoryImpl implements OfflineQueueRepository {
  static const String _queueBoxName = 'offline_sync_queue';

  Future<Box> _getBox() async {
    return await Hive.openBox(_queueBoxName);
  }

  @override
  Future<void> queueTransaction({required String type, required Map<String, dynamic> data}) async {
    final box = await _getBox();
    final item = {
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': jsonEncode(data),
    };
    await box.add(item);
  }

  @override
  Future<List<Map<String, dynamic>>> getQueue() async {
    final box = await _getBox();
    final List<Map<String, dynamic>> list = [];
    for (var i = 0; i < box.length; i++) {
      final item = box.getAt(i);
      if (item != null && item is Map) {
        list.add({
          'index': i,
          'type': item['type'],
          'timestamp': item['timestamp'],
          'data': jsonDecode(item['data'] as String),
        });
      }
    }
    return list;
  }

  @override
  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }

  @override
  Future<void> removeTransaction(int index) async {
    final box = await _getBox();
    if (index >= 0 && index < box.length) {
      await box.deleteAt(index);
    }
  }

  @override
  Future<void> clearQueue() async {
    final box = await _getBox();
    await box.clear();
  }

  @override
  Future<bool> processQueue() async {
    final items = await getQueue();
    if (items.isEmpty) return true;

    bool allSuccess = true;

    // Process from oldest to newest
    for (var item in items) {
      final index = item['index'] as int;
      final type = item['type'] as String;
      final data = item['data'] as Map<String, dynamic>;

      try {
        if (type == 'submit_device') {
          if (!Get.isRegistered<DevicesRepository>()) {
            Get.put<DevicesRepository>(DevicesRepositoryImpl(Get.find<ApiClient>()));
          }
          final devicesRepo = Get.find<DevicesRepository>();
          final device = ReceivedDevice.fromJson(data);
          await devicesRepo.submitDevice(device);
        } else if (type == 'submit_withdrawn_device') {
          if (!Get.isRegistered<DevicesRepository>()) {
            Get.put<DevicesRepository>(DevicesRepositoryImpl(Get.find<ApiClient>()));
          }
          final devicesRepo = Get.find<DevicesRepository>();
          final device = WithdrawnDevice.fromJson(data);
          await devicesRepo.submitWithdrawnDevice(device);
        } else if (type == 'handover') {
          // Handover offline sync is not implemented — fail loudly instead of fake success
          throw UnsupportedError(
            'مزامنة التسليم الأوفلاين غير مدعومة حالياً. أعد المحاولة مع اتصال بالشبكة.',
          );
        } else if (type == 'confirm_receiving') {
          final courierRepo = Get.isRegistered<CourierRequestsRepository>()
              ? Get.find<CourierRequestsRepository>()
              : CourierRequestsRepositoryImpl(Get.find<ApiClient>());
          
          final requestId = data['requestId'] as int;
          final itemStatuses = (data['itemStatuses'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final sessionMetadata = data['sessionMetadata'] != null
              ? Map<String, dynamic>.from(data['sessionMetadata'] as Map)
              : null;

          await courierRepo.confirmReceiving(
            requestId,
            itemStatuses: itemStatuses,
            sessionMetadata: sessionMetadata,
          );
        } else if (type == 'submit_execution_attempt') {
          final courierRepo = Get.isRegistered<CourierRequestsRepository>()
              ? Get.find<CourierRequestsRepository>()
              : CourierRequestsRepositoryImpl(Get.find<ApiClient>());

          final requestId = data['requestId'] as int;
          final attemptData = Map<String, dynamic>.from(data['attemptData'] as Map);

          await courierRepo.submitExecutionAttempt(
            requestId,
            attemptData,
          );
        }

        // Remove from queue on success
        await removeTransaction(index);
      } catch (e) {
        debugPrint('❌ Error syncing offline item: $e');
        allSuccess = false;
        break; // Stop processing further items to maintain sequence
      }
    }

    return allSuccess;
  }
}

class OfflineQueueController extends GetxController {
  final OfflineQueueRepository repository;

  OfflineQueueController({required this.repository});

  final pendingCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    updateQueueCount();
  }

  Future<void> updateQueueCount() async {
    pendingCount.value = await repository.getPendingCount();
  }

  Future<void> queueTransaction({required String type, required Map<String, dynamic> data}) async {
    await repository.queueTransaction(type: type, data: data);
    await updateQueueCount();
  }

  Future<bool> syncNow() async {
    if (pendingCount.value == 0) return true;

    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري مزامنة البيانات المعلقة...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final success = await repository.processQueue();
    Get.back(); // close loading dialog

    if (success) {
      Get.snackbar(
        'نجاح المزامنة',
        'تم مزامنة كافة العمليات المعلقة بنجاح مع الخادم',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'فشل المزامنة',
        'فشل مزامنة بعض العمليات. يرجى التحقق من اتصال الشبكة وإعادة المحاولة.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }

    await updateQueueCount();
    return success;
  }

  Future<void> clearQueue() async {
    await repository.clearQueue();
    pendingCount.value = 0;
  }
}
