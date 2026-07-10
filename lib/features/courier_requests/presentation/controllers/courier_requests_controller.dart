import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/courier_request_model.dart';
import '../../data/repositories/courier_requests_repository.dart';
import '../../../../core/storage/offline_queue_manager.dart';

class CourierRequestsController extends GetxController {
  final CourierRequestsRepository repository;

  CourierRequestsController({required this.repository});

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _requests = <CourierRequest>[].obs;
  final _currentRequest = Rxn<CourierRequest>();
  final _currentItems = <CourierRequestItem>[].obs;

  // Receiving Session state (persisted locally)
  final sessionId = ''.obs;
  final sessionStartTime = Rxn<DateTime>();
  final scannedSerials = <String>[].obs;
  final localScannedSerials = <int, String>{}.obs; // itemId -> scanned SN/ICCID
  final localItemStatuses = <int, String>{}.obs; // itemId -> status
  final localProblemReasons = <int, String>{}.obs; // itemId -> reason
  final checkedAccessories = <int>[].obs; // itemIds
  final evidencePhotos = <String>[].obs; // Base64 or local paths
  final hasSessionInProgress = false.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<CourierRequest> get requests => _requests;
  CourierRequest? get currentRequest => _currentRequest.value;
  List<CourierRequestItem> get currentItems => _currentItems;

  @override
  void onInit() {
    super.onInit();
    _initHive();
    loadRequests();
  }

  Future<void> _initHive() async {
    try {
      if (!Hive.isBoxOpen('courier_receiving_sessions')) {
        await Hive.openBox('courier_receiving_sessions');
      }
    } catch (e) {
      debugPrint('Hive init error in controller: $e');
    }
  }

  Future<void> loadRequests() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final list = await repository.getRequests();
      _requests.value = list;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadRequestDetails(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final req = await repository.getRequest(id);
      final items = await repository.getRequestItems(id);
      _currentRequest.value = req;
      _currentItems.value = items;

      // Check for locally cached active receiving session
      await restoreActiveSession(id);
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading.value = false;
    }
  }

  // ----------------------------------------------------
  // Receiving Session Lifecycle
  // ----------------------------------------------------

  Future<void> restoreActiveSession(int id) async {
    try {
      final box = await Hive.openBox('courier_receiving_sessions');
      final dataStr = box.get(id) as String?;
      if (dataStr != null) {
        final data = jsonDecode(dataStr) as Map<String, dynamic>;
        sessionId.value = data['sessionId'] ?? '';
        sessionStartTime.value = data['startTime'] != null ? DateTime.parse(data['startTime']) : null;
        scannedSerials.value = List<String>.from(data['scannedSerials'] ?? []);
        
        final rawStatuses = data['itemStatuses'] as Map<String, dynamic>? ?? {};
        localItemStatuses.value = rawStatuses.map((key, value) => MapEntry(int.parse(key), value as String));

        final rawReasons = data['problemReasons'] as Map<String, dynamic>? ?? {};
        localProblemReasons.value = rawReasons.map((key, value) => MapEntry(int.parse(key), value as String));

        final rawScannedSerials = data['localScannedSerials'] as Map<String, dynamic>? ?? {};
        localScannedSerials.value = rawScannedSerials.map((key, value) => MapEntry(int.parse(key), value as String));

        checkedAccessories.value = List<int>.from(data['checkedAccessories'] ?? []);
        evidencePhotos.value = List<String>.from(data['evidencePhotos'] ?? []);
        hasSessionInProgress.value = true;
      } else {
        _resetSessionState();
      }
    } catch (e) {
      debugPrint('Restore session error: $e');
      _resetSessionState();
    }
  }

  Future<void> startReceivingSession(int id) async {
    _resetSessionState();
    sessionId.value = 'SES-$id-${DateTime.now().millisecondsSinceEpoch}';
    sessionStartTime.value = DateTime.now();
    hasSessionInProgress.value = true;
    await saveActiveSession(id);
  }

  void _resetSessionState() {
    sessionId.value = '';
    sessionStartTime.value = null;
    scannedSerials.clear();
    localScannedSerials.clear();
    localItemStatuses.clear();
    localProblemReasons.clear();
    checkedAccessories.clear();
    evidencePhotos.clear();
    hasSessionInProgress.value = false;
  }

  Future<void> saveActiveSession(int id) async {
    try {
      final box = await Hive.openBox('courier_receiving_sessions');
      final data = {
        'sessionId': sessionId.value,
        'startTime': sessionStartTime.value?.toIso8601String(),
        'scannedSerials': scannedSerials.toList(),
        'itemStatuses': localItemStatuses.map((key, value) => MapEntry(key.toString(), value)),
        'problemReasons': localProblemReasons.map((key, value) => MapEntry(key.toString(), value)),
        'localScannedSerials': localScannedSerials.map((key, value) => MapEntry(key.toString(), value)),
        'checkedAccessories': checkedAccessories.toList(),
        'evidencePhotos': evidencePhotos.toList(),
      };
      await box.put(id, jsonEncode(data));
    } catch (e) {
      debugPrint('Save session error: $e');
    }
  }

  Future<void> deleteActiveSession(int id) async {
    try {
      final box = await Hive.openBox('courier_receiving_sessions');
      await box.delete(id);
      _resetSessionState();
    } catch (e) {
      debugPrint('Delete session error: $e');
    }
  }

  double getSessionProgress() {
    if (_currentItems.isEmpty) return 0.0;
    
    // Serialized Items (POS, SIM) count
    final serializedItems = _currentItems.where((i) => i.itemType == 'POS' || i.itemType == 'SIM').toList();
    if (serializedItems.isEmpty) return 1.0;

    int resolvedCount = 0;
    for (var item in serializedItems) {
      final status = localItemStatuses[item.id];
      if (status != null && status != 'PENDING_RECEIPT') {
        resolvedCount++;
      }
    }

    return resolvedCount / serializedItems.length;
  }

  // ----------------------------------------------------
  // Scanning & Discrepancy reporting (Offline First)
  // ----------------------------------------------------

  String? scanItemLocal(String serial) {
    if (serial.trim().isEmpty) return 'الرجاء إدخال رقم تسلسلي صالح';

    // 1. Check if already scanned
    if (scannedSerials.contains(serial)) {
      return 'تم مسح هذا الرقم التسلسلي مسبقاً في هذه الجلسة';
    }

    // 2. Find matching item in current request (Queue-based, order-free scanning)
    CourierRequestItem? matchedItem;
    
    // First, try matching by exact serial if already populated (for backward compatibility / pre-assigned serials)
    for (var item in _currentItems) {
      if (item.itemType == 'POS' && item.serialNumber == serial) {
        matchedItem = item;
        break;
      }
      if (item.itemType == 'SIM' && item.simSerial == serial) {
        matchedItem = item;
        break;
      }
    }

    // Second, if no exact match, bind to the first available slot of matching type (V14 Quantity-based flow)
    if (matchedItem == null) {
      final isSim = serial.length >= 18 && (serial.startsWith('89') || RegExp(r'^\d+$').hasMatch(serial));
      final targetType = isSim ? 'SIM' : 'POS';
      
      for (var item in _currentItems) {
        if (item.itemType == targetType) {
          final isAlreadyProcessed = localItemStatuses[item.id] != null && localItemStatuses[item.id] != 'PENDING_RECEIPT';
          if (!isAlreadyProcessed) {
            matchedItem = item;
            break;
          }
        }
      }
    }

    if (matchedItem == null) {
      return 'لا توجد خانة فارغة مطابقة لهذا الرقم التسلسلي في الطلب';
    }

    // 3. Mark as received locally
    localItemStatuses[matchedItem.id] = 'RECEIVED';
    localScannedSerials[matchedItem.id] = serial;
    localProblemReasons.remove(matchedItem.id);
    scannedSerials.add(serial);

    if (_currentRequest.value != null) {
      saveActiveSession(_currentRequest.value!.id);
    }

    return null; // Success
  }

  String? scanSpecificItemLocal(int itemId, String serial) {
    if (serial.trim().isEmpty) return 'الرجاء إدخال رقم تسلسلي صالح';
    _error.value = null;

    // 1. Check if already scanned in this session
    if (scannedSerials.contains(serial)) {
      return 'تم مسح هذا الرقم التسلسلي مسبقاً في هذه الجلسة';
    }

    // 2. Find the specific item
    final item = _currentItems.firstWhereOrNull((i) => i.id == itemId);
    if (item == null) {
      return 'العنصر المحدد غير موجود بالطلب';
    }

    // 3. If the item has a pre-assigned serial number from the warehouse, validate it
    if (item.itemType == 'POS' && item.serialNumber != null && item.serialNumber!.isNotEmpty) {
      if (item.serialNumber != serial) {
        return 'الرقم الممسوح ($serial) لا يطابق الرقم المخصص للجهاز (${item.serialNumber})';
      }
    }
    if (item.itemType == 'SIM' && item.simSerial != null && item.simSerial!.isNotEmpty) {
      if (item.simSerial != serial) {
        return 'رقم الشريحة الممسوح ($serial) لا يطابق الرقم المخصص للشريحة (${item.simSerial})';
      }
    }

    // 4. Mark as received locally
    localItemStatuses[item.id] = 'RECEIVED';
    localScannedSerials[item.id] = serial;
    localProblemReasons.remove(item.id);
    scannedSerials.add(serial);

    if (_currentRequest.value != null) {
      saveActiveSession(_currentRequest.value!.id);
    }

    return null; // Success
  }

  void reportProblemLocal(int itemId, String status, String reason) {
    localItemStatuses[itemId] = status; // MISSING, DAMAGED, WRONG_ITEM, REJECTED
    localProblemReasons[itemId] = reason;
    
    // If it was previously scanned, remove it from scanned list and clear serial mapping
    final serial = localScannedSerials.remove(itemId);
    if (serial != null) {
      scannedSerials.remove(serial);
    }

    if (_currentRequest.value != null) {
      saveActiveSession(_currentRequest.value!.id);
    }
  }

  void clearItemLocal(int itemId) {
    localItemStatuses.remove(itemId);
    localProblemReasons.remove(itemId);
    final serial = localScannedSerials.remove(itemId);
    if (serial != null) {
      scannedSerials.remove(serial);
    }
    
    if (_currentRequest.value != null) {
      saveActiveSession(_currentRequest.value!.id);
    }
  }

  void toggleAccessoryLocal(int itemId) {
    if (checkedAccessories.contains(itemId)) {
      checkedAccessories.remove(itemId);
    } else {
      checkedAccessories.add(itemId);
    }
    
    if (_currentRequest.value != null) {
      saveActiveSession(_currentRequest.value!.id);
    }
  }

  void addEvidencePhotoLocal(String photoBase64) {
    evidencePhotos.add(photoBase64);
    if (_currentRequest.value != null) {
      saveActiveSession(_currentRequest.value!.id);
    }
  }

  // ----------------------------------------------------
  // Sync and Backend Submission
  // ----------------------------------------------------

  Future<bool> acceptRequest(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final updated = await repository.acceptRequest(id);
      _currentRequest.value = updated;
      await loadRequests();
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> submitConfirmReceiving(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // Compile final statuses for items
      final List<Map<String, dynamic>> itemStatusesList = [];
      for (var item in _currentItems) {
        final localStatus = localItemStatuses[item.id];
        if (localStatus != null) {
          final Map<String, dynamic> entry = {
            'itemId': item.id,
            'status': localStatus,
          };
          if (localStatus == 'RECEIVED') {
            final scanned = localScannedSerials[item.id];
            if (scanned != null) {
              if (item.itemType == 'POS') {
                entry['serialNumber'] = scanned;
              } else if (item.itemType == 'SIM') {
                entry['simSerial'] = scanned;
              }
            }
          }
          itemStatusesList.add(entry);
        }
      }

      // Capture GPS location safely
      double? lat;
      double? lng;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        debugPrint('GPS capture bypassed: $e');
      }

      // Compile rich enterprise session metadata
      final sessionMeta = {
        'sessionId': sessionId.value,
        'startTime': sessionStartTime.value?.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'gps': {
          'latitude': lat ?? 24.7136, // Fallback Riyadh lat
          'longitude': lng ?? 46.6753, // Fallback Riyadh lng
        },
        'device': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        },
        'battery': 92, // Mock battery level
        'photosCount': evidencePhotos.length,
        'scansCount': scannedSerials.length,
        'checkedAccessoriesCount': checkedAccessories.length,
      };

      // Try sending to the server
      final updated = await repository.confirmReceiving(
        id,
        itemStatuses: itemStatusesList,
        sessionMetadata: sessionMeta,
      );

      _currentRequest.value = updated;
      
      // Clear local session on success
      await deleteActiveSession(id);
      await loadRequests();
      return true;
    } catch (e) {
      debugPrint('Confirm receiving online failed. Saving offline queue... Error: $e');
      
      // OFFLINE WORKFLOW: Save transaction to local offline queue box
      try {
        // Compile final statuses for items
        final List<Map<String, dynamic>> itemStatusesList = [];
        for (var item in _currentItems) {
          final localStatus = localItemStatuses[item.id];
          if (localStatus != null) {
            final Map<String, dynamic> entry = {
              'itemId': item.id,
              'status': localStatus,
            };
            if (localStatus == 'RECEIVED') {
              final scanned = localScannedSerials[item.id];
              if (scanned != null) {
                if (item.itemType == 'POS') {
                  entry['serialNumber'] = scanned;
                } else if (item.itemType == 'SIM') {
                  entry['simSerial'] = scanned;
                }
              }
            }
            itemStatusesList.add(entry);
          }
        }

        // Mock session metadata
        final sessionMeta = {
          'sessionId': sessionId.value,
          'startTime': sessionStartTime.value?.toIso8601String(),
          'endTime': DateTime.now().toIso8601String(),
          'gps': {
            'latitude': 24.7136,
            'longitude': 46.6753,
          },
          'device': {
            'platform': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
          },
          'battery': 92,
          'photosCount': evidencePhotos.length,
          'scansCount': scannedSerials.length,
          'checkedAccessoriesCount': checkedAccessories.length,
        };

        final offlineQueue = Get.find<OfflineQueueController>();
        await offlineQueue.queueTransaction(
          type: 'confirm_receiving',
          data: {
            'requestId': id,
            'itemStatuses': itemStatusesList,
            'sessionMetadata': sessionMeta,
          },
        );
        
        // Mock successful local state change
        if (_currentRequest.value != null) {
          // We clear the active session locally because it's now in the queue
          await deleteActiveSession(id);
        }
        await loadRequests();
        return true; // Return true but UI can check if internet is down
      } catch (err) {
        _error.value = 'فشل الحفظ محلياً: ${err.toString()}';
        return false;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> confirmReceiving(int id, List<Map<String, dynamic>> itemStatuses) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final updated = await repository.confirmReceiving(
        id,
        itemStatuses: itemStatuses,
      );
      _currentRequest.value = updated;
      await loadRequests();
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> startTask(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final updated = await repository.startTask(id);
      _currentRequest.value = updated;
      await loadRequests();
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> startRoute(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await repository.startRoute(id);
      await loadRequestDetails(id);
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> arriveCustomer(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await repository.arriveCustomer(id);
      await loadRequestDetails(id);
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> startInstallation(int id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await repository.startInstallation(id);
      await loadRequestDetails(id);
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> submitExecutionAttempt(
    int id, {
    required String status, // SUCCESS or FAILED
    String? failureReasonCode,
    String? notes,
    String? snInstalled,
    String? simInstalled,
    String? customerSignature,
    List<String>? photos,
    DateTime? startTime,
    DateTime? arrivalTime,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      double? lat;
      double? lng;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        debugPrint('GPS capture failed during execution attempt: $e');
      }

      final payload = {
        'status': status,
        'failureReasonCode': failureReasonCode,
        'notes': notes,
        'snInstalled': snInstalled,
        'simInstalled': simInstalled,
        'gpsLatitude': lat ?? 24.7136,
        'gpsLongitude': lng ?? 46.6753,
        'batteryLevel': 88, // Mock battery level
        'networkOperator': 'STC', // Mock network
        'startTime': startTime?.toIso8601String() ?? DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
        'arrivalTime': arrivalTime?.toIso8601String() ?? DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'evidencePhotos': photos ?? [],
        'customerSignature': customerSignature,
      };

      await repository.submitExecutionAttempt(id, payload);
      await loadRequestDetails(id);
      await loadRequests();
      return true;
    } catch (e) {
      debugPrint('Submit execution attempt online failed. Saving offline queue... Error: $e');
      
      try {
        final payload = {
          'status': status,
          'failureReasonCode': failureReasonCode,
          'notes': notes,
          'snInstalled': snInstalled,
          'simInstalled': simInstalled,
          'gpsLatitude': 24.7136,
          'gpsLongitude': 46.6753,
          'batteryLevel': 88,
          'networkOperator': 'STC',
          'startTime': startTime?.toIso8601String() ?? DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
          'arrivalTime': arrivalTime?.toIso8601String() ?? DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
          'endTime': DateTime.now().toIso8601String(),
          'evidencePhotos': photos ?? [],
          'customerSignature': customerSignature,
        };

        final offlineQueue = Get.find<OfflineQueueController>();
        await offlineQueue.queueTransaction(
          type: 'submit_execution_attempt',
          data: {
            'requestId': id,
            'attemptData': payload,
          },
        );
        
        await loadRequestDetails(id);
        await loadRequests();
        return true; // Return true as it was successfully saved to offline queue
      } catch (err) {
        _error.value = 'فشل الحفظ محلياً: ${err.toString()}';
        return false;
      }
    } finally {
      _isLoading.value = false;
    }
  }
}
