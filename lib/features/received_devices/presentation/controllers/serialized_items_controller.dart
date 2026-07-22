import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/gps_helper.dart';
import '../../domain/repositories/serialized_items_repository.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../data/models/serialized_item.dart';
import '../../../../shared/models/item_type.dart';

class SerializedItemsController extends GetxController {
  final SerializedItemsRepository repository;
  final DevicesRepository devicesRepository;

  SerializedItemsController({
    required this.repository,
    required this.devicesRepository,
  });

  // Loading & Error States
  final _isLoading = false.obs;
  final _isSearchingCustody = false.obs;
  final _error = Rxn<String>();

  bool get isLoading => _isLoading.value;
  bool get isSearchingCustody => _isSearchingCustody.value;
  String? get error => _error.value;

  // Dropdown States for "Add Custody"
  final _selectedCategory = 'devices'.obs; // devices, papers, sim, accessories
  final _selectedDeviceTypeId = Rxn<String>();
  final _selectedSimProvider = Rxn<String>();
  final _selectedPackageType = Rxn<String>();
  final _selectedAccessoryType = Rxn<String>();

  String get selectedCategory => _selectedCategory.value;
  String? get selectedDeviceTypeId => _selectedDeviceTypeId.value;
  String? get selectedSimProvider => _selectedSimProvider.value;
  String? get selectedPackageType => _selectedPackageType.value;
  String? get selectedAccessoryType => _selectedAccessoryType.value;

  // Catalog item types from server
  final _itemTypes = <ItemType>[].obs;
  List<ItemType> get itemTypes => _itemTypes;

  // Lookup results
  final _lookupItem = Rxn<SerializedItem>();
  final _lookupMessage = ''.obs;
  
  SerializedItem? get lookupItem => _lookupItem.value;
  String get lookupMessage => _lookupMessage.value;

  // Local Offline Drafts
  final scanInDrafts = <Map<String, dynamic>>[].obs;
  final scanOutDrafts = <Map<String, dynamic>>[].obs;

  // KSA Telecom Providers
  final List<String> ksaTelecomProviders = [
    'STC',
    'Mobily',
    'Zain',
    'Virgin Mobile',
    'Lebara',
    'Salam',
    'Red Bull Mobile',
  ];

  // SIM Package Types
  final List<String> simPackageTypes = [
    'باقة بيانات مفتوحة (Data)',
    'باقة اتصال مفوترة (Postpaid)',
    'باقة اتصال مسبقة الدفع (Prepaid)',
    'شريحة تتبع مركبات (M2M/IoT)',
  ];

  // Accessories Sub-Types
  final List<String> accessoryTypes = [
    'ملصقات (Stickers / Labels)',
    'بطاقات صرف (Withdrawal Cards)',
  ];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void setCategory(String category) {
    _selectedCategory.value = category;
    _selectedDeviceTypeId.value = null;
    _selectedSimProvider.value = null;
    _selectedPackageType.value = null;
    _selectedAccessoryType.value = null;
    update();
  }

  void selectAccessoryType(String? type) {
    _selectedAccessoryType.value = type;
    update();
  }

  void selectDeviceType(String? typeId) {
    _selectedDeviceTypeId.value = typeId;
    update();
  }

  void selectSimProvider(String? provider) {
    _selectedSimProvider.value = provider;
    update();
  }

  void selectPackageType(String? packageType) {
    _selectedPackageType.value = packageType;
    update();
  }

  /// Load initial data: item types and local drafts
  Future<void> loadData() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // 1. Get item types
      final types = await devicesRepository.getItemTypes();
      _itemTypes.value = types;

      // 2. Load cached drafts
      await loadDraftsFromCache();
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadDraftsFromCache() async {
    final cachedIn = await repository.getCachedScanInDrafts();
    final cachedOut = await repository.getCachedScanOutDrafts();
    scanInDrafts.assignAll(cachedIn);
    scanOutDrafts.assignAll(cachedOut);
  }

  /// Lookup device/item custody status
  Future<void> lookupCustody(String serialNumber) async {
    if (serialNumber.trim().isEmpty) return;

    try {
      _isSearchingCustody.value = true;
      _lookupMessage.value = '';
      _lookupItem.value = null;

      final item = await repository.lookup(serialNumber.trim());
      if (item != null) {
        _lookupItem.value = item;
      } else {
        _lookupMessage.value = 'الرقم التسلسلي غير مسجل في النظام كعهدة نشطة (مادة جديدة/في المستودع)';
      }
    } catch (e) {
      _lookupMessage.value = 'تعذر الاتصال للتحقق: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      _isSearchingCustody.value = false;
    }
  }

  /// Add item to custody (Scan-in)
  Future<bool> addCustody({
    required String serialNumber,
    required String itemTypeId,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // Call API
      final item = await repository.scanIn(
        serialNumber: serialNumber,
        itemTypeId: itemTypeId,
        carrierName: _selectedSimProvider.value,
        simPackageType: _selectedPackageType.value,
      );

      Get.snackbar(
        'نجح',
        'تم إضافة السيريال ${item.serialNumber} لعهدتك النشطة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      // Offline fallback
      final draft = {
        'serialNumber': serialNumber,
        'itemTypeId': itemTypeId,
        'carrierName': _selectedSimProvider.value,
        'simPackageType': _selectedPackageType.value,
        'category': _selectedCategory.value,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await repository.cacheScanInDraft(draft);
      await loadDraftsFromCache();

      Get.snackbar(
        'حفظ كمسودة',
        'تعذر الاتصال بالخادم. تم حفظ العملية كمسودة أوفلاين للمزامنة لاحقاً.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
      return true;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Deliver item to customer (Scan-out)
  Future<bool> deliverCustody({
    required String serialNumber,
    required String receiverName,
    required String orderNumber,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final position = await GpsHelper.getCurrentLocation();
      final double? lat = position?.latitude;
      final double? lng = position?.longitude;

      // Call API
      await repository.scanOut(
        serialNumber: serialNumber,
        receiverName: receiverName,
        orderNumber: orderNumber,
        latitude: lat,
        longitude: lng,
      );

      Get.snackbar(
        'تم التسليم',
        'تم تسليم الجهاز $serialNumber وتحديث المخزون بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      // Offline fallback
      final position = await GpsHelper.getCurrentLocation();
      final draft = {
        'serialNumber': serialNumber,
        'receiverName': receiverName,
        'orderNumber': orderNumber,
        if (position != null) 'latitude': position.latitude,
        if (position != null) 'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await repository.cacheScanOutDraft(draft);
      await loadDraftsFromCache();

      Get.snackbar(
        'حفظ كمسودة تسليم',
        'تم حفظ مسودة التسليم أوفلاين بسبب تعذر الاتصال بالخادم.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      return true;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Synchronize all offline drafts with backend
  Future<void> syncOfflineDrafts() async {
    if (scanInDrafts.isEmpty && scanOutDrafts.isEmpty) {
      Get.snackbar('تنبيه', 'لا توجد مسودات أوفلاين بحاجة للمزامنة');
      return;
    }

    try {
      _isLoading.value = true;
      int successCount = 0;

      // 1. Sync Intake (Scan In) drafts
      final List<Map<String, dynamic>> tempIn = List.from(scanInDrafts);
      for (var draft in tempIn) {
        try {
          await repository.scanIn(
            serialNumber: draft['serialNumber'] as String,
            itemTypeId: draft['itemTypeId'] as String,
            carrierName: draft['carrierName'] as String?,
            simPackageType: draft['simPackageType'] as String?,
          );
          await repository.removeDraft(draft['serialNumber'] as String, isScanIn: true);
          successCount++;
        } catch (_) {
          // ignore individual failures to continue the loop
        }
      }

      // 2. Sync Delivery (Scan Out) drafts
      final List<Map<String, dynamic>> tempOut = List.from(scanOutDrafts);
      for (var draft in tempOut) {
        try {
          await repository.scanOut(
            serialNumber: draft['serialNumber'] as String,
            receiverName: draft['receiverName'] as String,
            orderNumber: draft['orderNumber'] as String,
            latitude: draft['latitude'] as double?,
            longitude: draft['longitude'] as double?,
          );
          await repository.removeDraft(draft['serialNumber'] as String, isScanIn: false);
          successCount++;
        } catch (_) {
          // ignore
        }
      }

      await loadDraftsFromCache();

      Get.snackbar(
        'مزامنة البيانات',
        'تمت مزامنة $successCount عملية/عمليات بنجاح مع الخادم الرئيسي.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete single draft
  Future<void> deleteDraft(String serialNumber, bool isScanIn) async {
    await repository.removeDraft(serialNumber, isScanIn: isScanIn);
    await loadDraftsFromCache();
    Get.snackbar(
      'حذف',
      'تم حذف المسودة بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey[800],
      colorText: Colors.white,
    );
  }
}
