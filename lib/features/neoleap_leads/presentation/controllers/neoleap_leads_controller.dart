import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../../domain/repositories/neoleap_leads_repository.dart';
import '../../../../core/storage/secure_storage.dart';

/// حالة مفتاح Google Places API
enum ApiKeyStatus { idle, checking, valid, invalid }

/// حالة عرض القائمة
enum LeadsViewFilter { all, pending, contacted }

class NeoleapLeadsController extends GetxController {
  final NeoleapLeadsRepository repository;
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();

  NeoleapLeadsController({required this.repository});

  // ── Observables ──────────────────────────────────────────────────────────
  final leads = <LeadEntity>[].obs;
  final filteredLeads = <LeadEntity>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final selectedRegions = <RegionEntity>[].obs;
  final apiKey = ''.obs;
  final apiKeyStatus = ApiKeyStatus.idle.obs;
  final apiKeyError = ''.obs;
  final viewFilter = LeadsViewFilter.all.obs;
  final searchText = ''.obs;

  // ── Getters ───────────────────────────────────────────────────────────────
  int get totalLeads => leads.length;
  int get leadsWithPhone =>
      leads.where((l) => l.phone != null && l.phone!.trim().isNotEmpty).length;
  int get sentCount => leads.where((l) => l.isSent).length;
  int get pendingCount => leads.where((l) => !l.isSent).length;
  bool get isApiKeyValid => apiKeyStatus.value == ApiKeyStatus.valid;

  @override
  void onInit() {
    super.onInit();
    _loadLeads();
    _loadSavedApiKey();
    _loadSelectedRegions();
  }

  // ─── تحميل المحلات من التخزين المحلي ─────────────────────────────────────
  Future<void> _loadLeads() async {
    final result = await repository.getAllLeads();
    result.fold(
      (exception) => error.value = exception.toString(),
      (loadedLeads) {
        leads.assignAll(loadedLeads);
        _applyFilter();
      },
    );
  }

  // ─── تحميل المناطق المحفوظة ───────────────────────────────────────────────
  Future<void> _loadSelectedRegions() async {
    final result = await repository.getSelectedRegions();
    result.fold(
      (exception) => error.value = exception.toString(),
      (regions) => selectedRegions.assignAll(regions),
    );
  }

  // ─── تحميل مفتاح API المحفوظ والتحقق منه ─────────────────────────────────
  Future<void> _loadSavedApiKey() async {
    try {
      final savedKey = await _secureStorage.getGooglePlacesApiKey();
      if (savedKey != null && savedKey.isNotEmpty) {
        apiKey.value = savedKey;
        await _pingGooglePlaces(savedKey, silent: true);
      }
    } catch (e) {
      debugPrint('Failed to load API Key: $e');
    }
  }

  // ─── حفظ وتحقق من مفتاح API (يُستدعى من الـ UI) ─────────────────────────
  Future<void> saveAndValidateApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      apiKeyStatus.value = ApiKeyStatus.idle;
      apiKeyError.value = '';
      apiKey.value = '';
      await _secureStorage.deleteGooglePlacesApiKey();
      return;
    }

    apiKey.value = trimmed;
    await _secureStorage.saveGooglePlacesApiKey(trimmed);
    await _pingGooglePlaces(trimmed, silent: false);
  }

  // ─── التحقق من صحة المفتاح عبر طلب تجريبي ───────────────────────────────
  Future<void> _pingGooglePlaces(String key, {required bool silent}) async {
    apiKeyStatus.value = ApiKeyStatus.checking;
    apiKeyError.value = '';

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ));

      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/place/textsearch/json',
        queryParameters: {
          'query': 'test',
          'key': key,
        },
      );

      if (response.statusCode == 200) {
        final status = response.data['status'] as String? ?? '';
        if (status == 'OK' || status == 'ZERO_RESULTS') {
          apiKeyStatus.value = ApiKeyStatus.valid;
          if (!silent) {
            Get.snackbar(
              '✅ مفتاح API صالح',
              'تم التحقق من مفتاح Google Places بنجاح',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
            );
          }
        } else if (status == 'REQUEST_DENIED') {
          apiKeyStatus.value = ApiKeyStatus.invalid;
          apiKeyError.value = 'المفتاح غير صالح أو ميزة Places API غير مُفعّلة';
          if (!silent) {
            Get.snackbar(
              '❌ مفتاح غير صالح',
              apiKeyError.value,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 4),
            );
          }
        } else if (status == 'OVER_QUERY_LIMIT') {
          apiKeyStatus.value = ApiKeyStatus.invalid;
          apiKeyError.value = 'تجاوزت حصة الطلبات اليومية للمفتاح';
        } else {
          apiKeyStatus.value = ApiKeyStatus.valid;
        }
      } else {
        apiKeyStatus.value = ApiKeyStatus.invalid;
        apiKeyError.value = 'خطأ HTTP: ${response.statusCode}';
      }
    } on DioException catch (e) {
      apiKeyStatus.value = ApiKeyStatus.invalid;
      apiKeyError.value = 'تعذّر الاتصال بـ Google: ${e.message}';
      debugPrint('Places ping error: $e');
    } catch (e) {
      apiKeyStatus.value = ApiKeyStatus.invalid;
      apiKeyError.value = 'خطأ غير متوقع: $e';
    }
  }

  // ─── حذف المفتاح ─────────────────────────────────────────────────────────
  Future<void> clearApiKey() async {
    apiKey.value = '';
    apiKeyStatus.value = ApiKeyStatus.idle;
    apiKeyError.value = '';
    await _secureStorage.deleteGooglePlacesApiKey();
  }

  // ─── البحث في Google Places ────────────────────────────────────────────────
  Future<void> searchPlaces({
    required String query,
    required int radius,
  }) async {
    if (apiKey.value.trim().isEmpty) {
      error.value = 'الرجاء إدخال مفتاح Google Places API Key أولاً';
      return;
    }
    if (apiKeyStatus.value == ApiKeyStatus.invalid) {
      error.value = 'مفتاح API غير صالح. يرجى إدخال مفتاح صحيح أولاً';
      return;
    }
    if (selectedRegions.isEmpty) {
      error.value = 'اختر مدينة واحدة على الأقل';
      return;
    }
    if (query.trim().isEmpty) {
      error.value = 'أدخل نوع النشاط التجاري المراد البحث عنه';
      return;
    }

    isLoading.value = true;
    error.value = '';

    try {
      final regions = selectedRegions.map((r) => {
        'name': r.name,
        'latitude': r.latitude,
        'longitude': r.longitude,
      }).toList();

      final result = await repository.searchPlaces(
        apiKey: apiKey.value,
        query: query,
        regions: regions,
        radius: radius,
      );

      result.fold(
        (exception) {
          error.value = 'خطأ البحث: ${exception.toString()}';
        },
        (searchedLeads) {
          _loadLeads();
          Get.snackbar(
            '🎯 تم بنجاح',
            'تم الحصول على ${searchedLeads.length} محل مستهدف',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─── تحديث حالة الإرسال ───────────────────────────────────────────────────
  Future<void> markLeadAsSent(String leadId) async {
    final result = await repository.markLeadAsSent(leadId);
    result.fold(
      (exception) {
        error.value = 'خطأ: ${exception.toString()}';
      },
      (_) {
        final index = leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          leads[index] = leads[index].copyWith(
            isSent: true,
            sentAt: DateTime.now(),
          );
          leads.refresh();
          _applyFilter();
        }
      },
    );
  }

  // ─── تحديث رقم الهاتف ────────────────────────────────────────────────────
  Future<void> updateLeadPhone(String leadId, String phone) async {
    final result = await repository.updateLeadPhone(leadId, phone);
    result.fold(
      (exception) {
        error.value = 'خطأ: ${exception.toString()}';
      },
      (_) {
        final index = leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          leads[index] = leads[index].copyWith(phone: phone);
          leads.refresh();
          _applyFilter();
        }
      },
    );
  }

  // ─── حذف عميل محتمل ──────────────────────────────────────────────────────
  Future<void> deleteLead(String leadId) async {
    final result = await repository.deleteLead(leadId);
    result.fold(
      (exception) {
        error.value = 'خطأ الحذف: ${exception.toString()}';
      },
      (_) {
        leads.removeWhere((l) => l.id == leadId);
        leads.refresh();
        _applyFilter();
      },
    );
  }

  // ─── إدارة المناطق ────────────────────────────────────────────────────────
  void toggleRegion(RegionEntity region) {
    final index = selectedRegions.indexWhere((r) => r.name == region.name);
    if (index != -1) {
      selectedRegions.removeAt(index);
    } else {
      selectedRegions.add(region.copyWith(isSelected: true));
    }
    selectedRegions.refresh();
    repository.saveSelectedRegions(selectedRegions.toList());
  }

  bool isRegionSelected(RegionEntity region) {
    return selectedRegions.any((r) => r.name == region.name);
  }

  void selectAllRegions() {
    final all = RegionEntity.saudiRegions
        .map((r) => r.copyWith(isSelected: true))
        .toList();
    selectedRegions.assignAll(all);
    repository.saveSelectedRegions(all);
  }

  void deselectAllRegions() {
    selectedRegions.clear();
    repository.saveSelectedRegions([]);
  }

  // ─── تغيير فلتر العرض ────────────────────────────────────────────────────
  void setViewFilter(LeadsViewFilter filter) {
    viewFilter.value = filter;
    _applyFilter();
  }

  // ─── تصدير CSV ───────────────────────────────────────────────────────────
  Future<void> exportToCSV() async {
    final result = await repository.exportToCSV(leads);
    result.fold(
      (exception) {
        error.value = 'خطأ التصدير: ${exception.toString()}';
      },
      (csvContent) async {
        try {
          final directory = await getTemporaryDirectory();
          final path =
              '${directory.path}/neoleap_leads_${DateTime.now().millisecondsSinceEpoch}.csv';
          final file = File(path);
          final bytes = utf8.encode(csvContent);
          const bom = [0xEF, 0xBB, 0xBF];
          await file.writeAsBytes(bom + bytes);
          await Share.shareXFiles(
            [XFile(path)],
            text: 'تقرير العملاء المستهدفين لـ Neoleap',
          );
          Get.snackbar('نجاح', 'تم تصدير ومشاركة ملف CSV بنجاح');
        } catch (e) {
          error.value = 'خطأ حفظ الملف: $e';
        }
      },
    );
  }

  // ─── فلترة محلية ─────────────────────────────────────────────────────────
  void filterLeads(String query) {
    searchText.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    List<LeadEntity> base = [];

    switch (viewFilter.value) {
      case LeadsViewFilter.all:
        base = leads.toList();
        break;
      case LeadsViewFilter.pending:
        base = leads.where((l) => !l.isSent).toList();
        break;
      case LeadsViewFilter.contacted:
        base = leads.where((l) => l.isSent).toList();
        break;
    }

    final q = searchText.value.toLowerCase();
    if (q.isNotEmpty) {
      base = base.where((l) =>
          l.name.toLowerCase().contains(q) ||
          l.phone?.contains(q) == true ||
          l.address?.toLowerCase().contains(q) == true).toList();
    }

    filteredLeads.assignAll(base);
  }
}

// Extension لـ copyWith في RegionEntity
extension RegionEntityX on RegionEntity {
  RegionEntity copyWith({bool? isSelected}) {
    return RegionEntity(
      name: name,
      emoji: emoji,
      latitude: latitude,
      longitude: longitude,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
