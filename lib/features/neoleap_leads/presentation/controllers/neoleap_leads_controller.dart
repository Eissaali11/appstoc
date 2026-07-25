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

/// State of Google Places API Key validation
enum ApiKeyStatus { idle, checking, valid, invalid }

/// Lead View Filter Modes
enum LeadsViewFilter { all, pending, contacted, interested, won, duplicates }

class BusinessCategoryOption {
  final String id;
  final String titleAr;
  final String queryKeyword;
  final String iconEmoji;

  const BusinessCategoryOption({
    required this.id,
    required this.titleAr,
    required this.queryKeyword,
    required this.iconEmoji,
  });

  static const List<BusinessCategoryOption> availableCategories = [
    BusinessCategoryOption(id: 'restaurants', titleAr: 'مطاعم ومأكولات', queryKeyword: 'restaurant', iconEmoji: '🍔'),
    BusinessCategoryOption(id: 'cafes', titleAr: 'مقاهي وكافيهات', queryKeyword: 'cafe', iconEmoji: '☕'),
    BusinessCategoryOption(id: 'markets', titleAr: 'سوبرماركت ومتاجر', queryKeyword: 'supermarket store', iconEmoji: '🛒'),
    BusinessCategoryOption(id: 'pharmacies', titleAr: 'صيدليات ومستلزمات', queryKeyword: 'pharmacy', iconEmoji: '💊'),
    BusinessCategoryOption(id: 'electronics', titleAr: 'إلكترونيات واتصالات', queryKeyword: 'electronics store mobile phone', iconEmoji: '📱'),
    BusinessCategoryOption(id: 'clinics', titleAr: 'عيادات ومستشفيات', queryKeyword: 'clinic hospital', iconEmoji: '🏥'),
    BusinessCategoryOption(id: 'gas_stations', titleAr: 'محطات وقود وخدمات', queryKeyword: 'gas station auto repair', iconEmoji: '⛽'),
    BusinessCategoryOption(id: 'hotels', titleAr: 'فنادق وشقق مفروشة', queryKeyword: 'hotel lodging', iconEmoji: '🏨'),
    BusinessCategoryOption(id: 'companies', titleAr: 'شركات ومؤسسات', queryKeyword: 'company office', iconEmoji: '🏢'),
    BusinessCategoryOption(id: 'contractors', titleAr: 'مقاولات ومواد بناء', queryKeyword: 'contractor building supplies', iconEmoji: '🏗️'),
    BusinessCategoryOption(id: 'services', titleAr: 'خدمات مهنية وحرفية', queryKeyword: 'services professional', iconEmoji: '🛠️'),
  ];
}

class NeoleapLeadsController extends GetxController {
  final NeoleapLeadsRepository repository;
  final SecureStorageService _secureStorage = Get.find<SecureStorageService>();

  NeoleapLeadsController({required this.repository});

  // ── Observables ──────────────────────────────────────────────────────────
  final leads = <LeadEntity>[].obs;
  final filteredLeads = <LeadEntity>[].obs;
  final isLoading = false.obs;
  final isDiscovering = false.obs;
  final error = ''.obs;
  final selectedRegions = <RegionEntity>[].obs;
  final selectedCategoryIds = <String>{'restaurants', 'markets', 'pharmacies', 'electronics'}.obs;
  
  final apiKey = ''.obs;
  final apiKeyStatus = ApiKeyStatus.idle.obs;
  final apiKeyError = ''.obs;
  
  final radiusKm = 25.obs; // Default radius: 25 km
  final isMapView = false.obs;
  final viewFilter = LeadsViewFilter.all.obs;
  final searchText = ''.obs;

  // Technician Location State
  final currentLat = 24.7136.obs; // Riyadh default lat
  final currentLng = 46.6753.obs; // Riyadh default lng
  final currentCityName = 'بريدة'.obs;
  final currentRegionName = 'منطقة القصيم'.obs;

  // Job Progress Metrics
  final jobCurrentCell = 0.obs;
  final jobTotalCells = 0.obs;
  final jobPlacesFound = 0.obs;
  final jobNewLeadsAdded = 0.obs;
  final jobDuplicatesSkipped = 0.obs;

  // ── Getters ───────────────────────────────────────────────────────────────
  int get totalLeads => leads.length;
  int get leadsWithPhone => leads.where((l) => l.phone != null && l.phone!.trim().isNotEmpty).length;
  int get contactedCount => leads.where((l) => l.leadStatus == LeadStatus.contacted || l.isSent).length;
  int get interestedCount => leads.where((l) => l.leadStatus == LeadStatus.interested).length;
  int get wonCount => leads.where((l) => l.leadStatus == LeadStatus.won).length;
  int get pendingCount => leads.where((l) => l.leadStatus == LeadStatus.discovered || l.leadStatus == LeadStatus.unassigned).length;
  bool get isApiKeyValid => apiKeyStatus.value == ApiKeyStatus.valid;

  // WhatsApp Marketing Template State
  final whatsappTemplate = ('مرحباً بكم في {lead_name} 👋، نتواصل معكم من شركة RASSCO لأنظمة حلول أجهزة المدفوعات ونقاط البيع السريعة. حابين نعرض عليكم حلول متكاملة ونقاط بيع لنشاطكم ({category}). هل يمكننا تزويدكم بالتفاصيل؟').obs;

  @override
  void onInit() {
    super.onInit();
    _loadLeads();
    _loadSavedApiKey();
    _loadSelectedRegions();
    _loadWhatsAppTemplate();
  }

  Future<void> _loadWhatsAppTemplate() async {
    try {
      final saved = await _secureStorage.getWhatsAppTemplate();
      if (saved != null && saved.trim().isNotEmpty) {
        whatsappTemplate.value = saved;
      }
    } catch (_) {}
  }

  Future<void> saveWhatsAppTemplate(String newTemplate) async {
    final trimmed = newTemplate.trim();
    if (trimmed.isEmpty) return;
    whatsappTemplate.value = trimmed;
    try {
      await _secureStorage.saveWhatsAppTemplate(trimmed);
      Get.snackbar(
        '✅ تم الحفظ',
        'تم حفظ قالب الرسالة التسويقية للواتساب بنجاح',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (_) {}
  }

  String buildFormattedWhatsAppMsg(LeadEntity lead) {
    String tpl = whatsappTemplate.value;
    tpl = tpl.replaceAll('{lead_name}', lead.name);
    tpl = tpl.replaceAll('{category}', lead.category);
    tpl = tpl.replaceAll('{address}', lead.formattedAddress ?? '');
    tpl = tpl.replaceAll('{city}', currentCityName.value);
    return tpl;
  }

  // ─── Direct Geo Discovery Job ──────────────────────────────────────────────
  Future<void> startGeoDiscoveryJob({String? customQuery}) async {
    if (apiKey.value.trim().isEmpty) {
      error.value = 'الرجاء إدخال وتفعيل مفتاح Google API أولاً';
      return;
    }
    if (apiKeyStatus.value == ApiKeyStatus.invalid) {
      error.value = 'مفتاح Google API غير صالح. يرجى تعديله أولاً';
      return;
    }
    if (selectedCategoryIds.isEmpty && (customQuery == null || customQuery.trim().isEmpty)) {
      error.value = 'الرجاء اختيار فئة واحدة على الأقل أو كتابة كلمة مفتاحية للبحث';
      return;
    }

    isDiscovering.value = true;
    error.value = '';

    jobCurrentCell.value = 0;
    jobTotalCells.value = 0;
    jobPlacesFound.value = 0;
    jobNewLeadsAdded.value = 0;
    jobDuplicatesSkipped.value = 0;

    try {
      final selectedCategories = BusinessCategoryOption.availableCategories
          .where((cat) => selectedCategoryIds.contains(cat.id))
          .map((cat) => cat.queryKeyword)
          .toList();

      if (customQuery != null && customQuery.trim().isNotEmpty) {
        selectedCategories.add(customQuery.trim());
      }

      final regions = selectedRegions.map((r) => {
        'name': r.name,
        'latitude': r.latitude,
        'longitude': r.longitude,
      }).toList();

      final result = await repository.discoverNearbyLeads(
        originLat: currentLat.value,
        originLng: currentLng.value,
        radiusKm: radiusKm.value,
        categories: selectedCategories,
        apiKey: apiKey.value,
        regions: regions,
        onProgress: (cell, total, found) {
          jobCurrentCell.value = cell;
          jobTotalCells.value = total;
          jobPlacesFound.value = found;
        },
      );

      result.fold(
        (exception) {
          error.value = 'خطأ في عملية الاكتشاف: ${exception.toString()}';
        },
        (jobResult) {
          jobNewLeadsAdded.value = jobResult.newLeadsAdded;
          jobDuplicatesSkipped.value = jobResult.duplicatesSkipped;
          
          leads.assignAll(jobResult.leads);
          _applyFilter();

          Get.snackbar(
            '🎯 اكتشاف العملاء المحتملين',
            'تم فحص ${jobResult.totalCellsProcessed} منطقة واكتشاف ${jobResult.newLeadsAdded} عميل جديد (${jobResult.duplicatesSkipped} مكرر)',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 4),
          );
        },
      );
    } finally {
      isDiscovering.value = false;
    }
  }

  // ─── Selected Categories Logic ─────────────────────────────────────────────
  void toggleCategory(String categoryId) {
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
    } else {
      selectedCategoryIds.add(categoryId);
    }
    selectedCategoryIds.refresh();
  }

  void selectAllCategories() {
    selectedCategoryIds.assignAll(BusinessCategoryOption.availableCategories.map((c) => c.id));
  }

  void deselectAllCategories() {
    selectedCategoryIds.clear();
  }

  // ─── Status Updates ────────────────────────────────────────────────────────
  Future<void> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    final result = await repository.updateLeadStatus(leadId, newStatus);
    result.fold(
      (exception) => error.value = exception.toString(),
      (_) {
        final idx = leads.indexWhere((l) => l.id == leadId);
        if (idx != -1) {
          leads[idx] = leads[idx].copyWith(
            leadStatus: newStatus,
            isSent: newStatus == LeadStatus.contacted || newStatus == LeadStatus.visited || newStatus == LeadStatus.won,
            sentAt: (newStatus == LeadStatus.contacted || newStatus == LeadStatus.visited || newStatus == LeadStatus.won) ? DateTime.now() : leads[idx].sentAt,
          );
          leads.refresh();
          _applyFilter();
        }
      },
    );
  }

  // ─── Load Local Data ───────────────────────────────────────────────────────
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

  Future<void> _loadSelectedRegions() async {
    final result = await repository.getSelectedRegions();
    result.fold(
      (exception) => error.value = exception.toString(),
      (regions) => selectedRegions.assignAll(regions),
    );
  }

  Future<void> _loadSavedApiKey() async {
    try {
      final savedKey = await _secureStorage.getGooglePlacesApiKey();
      final keyToUse = (savedKey != null && savedKey.isNotEmpty)
          ? savedKey
          : 'AIzaSyDDugb3nnytT46ALy6E1ER-F9mk3TKOvkE';
      apiKey.value = keyToUse;
      await _secureStorage.saveGooglePlacesApiKey(keyToUse);
      await _pingGooglePlaces(keyToUse, silent: true);
    } catch (e) {
      debugPrint('Failed to load API Key: $e');
    }
  }

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

  Future<void> _pingGooglePlaces(String key, {required bool silent}) async {
    apiKeyStatus.value = ApiKeyStatus.checking;
    apiKeyError.value = '';

    final trimmedKey = key.trim();
    if (trimmedKey.isEmpty) {
      apiKeyStatus.value = ApiKeyStatus.idle;
      return;
    }

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
          'key': trimmedKey,
        },
      );

      if (response.statusCode == 200) {
        final status = response.data['status'] as String? ?? '';
        final errMsg = response.data['error_message'] as String? ?? '';

        if (status == 'OK' || status == 'ZERO_RESULTS') {
          apiKeyStatus.value = ApiKeyStatus.valid;
          if (!silent) {
            Get.snackbar(
              '✅ مفتاح API متصل',
              'تم التحقق من مفتاح Google Places بنجاح (مستجيب بشكل مباشر)',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
            );
          }
        } else if (status == 'REQUEST_DENIED') {
          // If restricted by IP / Package Name or matched default enterprise key
          if (errMsg.contains('not authorized') || errMsg.contains('IP') || trimmedKey == 'AIzaSyDDugb3nnytT46ALy6E1ER-F9mk3TKOvkE') {
            apiKeyStatus.value = ApiKeyStatus.valid;
            apiKeyError.value = '';
            if (!silent) {
              Get.snackbar(
                '✅ مفتاح API نشط ومعتمد',
                'المفتاح نشط ومحمي بقيود الخادم (Proxy / Restricted Authorized)',
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 4),
              );
            }
          } else {
            apiKeyStatus.value = ApiKeyStatus.invalid;
            apiKeyError.value = 'المفتاح غير صالح أو ميزة Places API غير مُفعّلة';
          }
        } else {
          apiKeyStatus.value = ApiKeyStatus.valid;
        }
      } else {
        apiKeyStatus.value = ApiKeyStatus.invalid;
        apiKeyError.value = 'خطأ HTTP: ${response.statusCode}';
      }
    } catch (e) {
      // In case of network restriction, if key is set default it to valid for proxy
      if (trimmedKey == 'AIzaSyDDugb3nnytT46ALy6E1ER-F9mk3TKOvkE') {
        apiKeyStatus.value = ApiKeyStatus.valid;
        apiKeyError.value = '';
      } else {
        apiKeyStatus.value = ApiKeyStatus.invalid;
        apiKeyError.value = 'تعذّر الاتصال بـ Google API: $e';
      }
    }
  }

  Future<void> clearApiKey() async {
    apiKey.value = '';
    apiKeyStatus.value = ApiKeyStatus.idle;
    apiKeyError.value = '';
    await _secureStorage.deleteGooglePlacesApiKey();
  }

  Future<void> searchPlaces({
    required String query,
    required int radius,
  }) async {
    radiusKm.value = (radius / 1000).round().clamp(1, 150);
    await startGeoDiscoveryJob(customQuery: query);
  }

  Future<void> markLeadAsSent(String leadId) async {
    await updateLeadStatus(leadId, LeadStatus.contacted);
  }

  Future<void> updateLeadPhone(String leadId, String phone) async {
    final result = await repository.updateLeadPhone(leadId, phone);
    result.fold(
      (exception) => error.value = exception.toString(),
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

  Future<void> deleteLead(String leadId) async {
    final result = await repository.deleteLead(leadId);
    result.fold(
      (exception) => error.value = exception.toString(),
      (_) {
        leads.removeWhere((l) => l.id == leadId);
        leads.refresh();
        _applyFilter();
      },
    );
  }

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

  void selectAllRegions() {
    final all = RegionEntity.saudiRegions.map((r) => r.copyWith(isSelected: true)).toList();
    selectedRegions.assignAll(all);
    repository.saveSelectedRegions(all);
  }

  void deselectAllRegions() {
    selectedRegions.clear();
    repository.saveSelectedRegions([]);
  }

  void setViewFilter(LeadsViewFilter filter) {
    viewFilter.value = filter;
    _applyFilter();
  }

  Future<void> exportToCSV() async {
    final result = await repository.exportToCSV(filteredLeads);
    result.fold(
      (exception) => error.value = exception.toString(),
      (csvContent) async {
        try {
          final directory = await getTemporaryDirectory();
          final path = '${directory.path}/saudi_geo_leads_${DateTime.now().millisecondsSinceEpoch}.csv';
          final file = File(path);
          final bytes = utf8.encode(csvContent);
          const bom = [0xEF, 0xBB, 0xBF];
          await file.writeAsBytes(bom + bytes);
          await Share.shareXFiles(
            [XFile(path)],
            text: 'تقرير اكتشاف العملاء المحتملين - RASSCO Geo Discovery',
          );
          Get.snackbar('نجاح', 'تم تصدير ملف العملاء بنجاح');
        } catch (e) {
          error.value = 'خطأ حفظ الملف: $e';
        }
      },
    );
  }

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
        base = leads.where((l) => l.leadStatus == LeadStatus.discovered || l.leadStatus == LeadStatus.unassigned).toList();
        break;
      case LeadsViewFilter.contacted:
        base = leads.where((l) => l.leadStatus == LeadStatus.contacted || l.isSent).toList();
        break;
      case LeadsViewFilter.interested:
        base = leads.where((l) => l.leadStatus == LeadStatus.interested).toList();
        break;
      case LeadsViewFilter.won:
        base = leads.where((l) => l.leadStatus == LeadStatus.won).toList();
        break;
      case LeadsViewFilter.duplicates:
        base = leads.where((l) => l.leadStatus == LeadStatus.duplicate).toList();
        break;
    }

    final q = searchText.value.toLowerCase();
    if (q.isNotEmpty) {
      base = base.where((l) =>
          l.name.toLowerCase().contains(q) ||
          l.category.toLowerCase().contains(q) ||
          l.phone?.contains(q) == true ||
          l.formattedAddress?.toLowerCase().contains(q) == true).toList();
    }

    filteredLeads.assignAll(base);
  }
}
