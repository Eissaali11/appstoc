import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/routing/app_pages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/offline_queue_manager.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/lottie_feedback_dialog.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../data/models/received_device.dart';
import '../../data/models/withdrawn_device.dart';

class DevicesController extends GetxController {
  final DevicesRepository repository;

  DevicesController({required this.repository});

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _devices = <ReceivedDevice>[].obs;
  final _withdrawnDevices = <WithdrawnDevice>[].obs;
  final _itemTypes = <ItemType>[].obs;
  final _pendingCount = 0.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<ReceivedDevice> get devices => _devices;
  List<WithdrawnDevice> get withdrawnDevices => _withdrawnDevices;
  List<ItemType> get itemTypes => _itemTypes;
  int get pendingCount => _pendingCount.value;

  @override
  void onInit() {
    super.onInit();
    loadDevices();
    loadWithdrawnDevices();
    
    // Reactively listen to offline queue sync successes
    if (Get.isRegistered<OfflineQueueController>()) {
      ever(Get.find<OfflineQueueController>().pendingCount, (int count) {
        if (count == 0 && !isLoading) {
          loadDevices();
          loadWithdrawnDevices();
        }
      });
    }
  }

  Future<void> loadDevices() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final results = await Future.wait([
        repository.getReceivedDevices(),
        repository.getItemTypes(),
      ]);

      final list = results[0] as List<ReceivedDevice>;
      _itemTypes.value = results[1] as List<ItemType>;

      // الأحدث أولاً
      list.sort(
        (a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()),
      );
      _devices.value = list;
      _pendingCount.value = list
          .where((d) => (d.status ?? '').toLowerCase() == 'pending')
          .length;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadWithdrawnDevices() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final list = await repository.getWithdrawnDevices();
      
      // الأحدث أولاً
      list.sort(
        (a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()),
      );
      _withdrawnDevices.value = list;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> submitDevice(ReceivedDevice device) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await repository.submitDevice(device);
      
      // بعد نجاح الإرسال نعيد تحميل قائمة الأجهزة
      await loadDevices();

      // إظهار رسم متحرك للنجاح
      await AppLottieFeedback.show(
        isSuccess: true,
        title: 'تم تسجيل التوريد بنجاح',
        message: 'تم إرسال بيانات الجهاز إلى السيرفر وتحديث العهدة الخاصة بك بنجاح',
        onComplete: () {
          // التوجيه إلى صفحة الأجهزة المستلمة
          if (Get.currentRoute == Routes.submitDevice) {
            Get.offNamed(Routes.receivedDevices);
          } else {
            Get.toNamed(Routes.receivedDevices);
          }
        },
      );
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      
      final isNetworkError = e.toString().contains('SocketException') || 
                            e.toString().contains('Connection refused') || 
                            e.toString().contains('Failed host lookup') ||
                            e.toString().contains('timeout');
      
      if (isNetworkError) {
        final bool? saveOffline = await Get.dialog<bool>(
          Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text('مشكلة في الاتصال بالشبكة', style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: Colors.white)),
              content: Text('يبدو أنك غير متصل بالإنترنت حالياً. هل تود حفظ عملية التوريد محلياً ومزامنتها لاحقاً؟', style: TextStyle(fontFamily: 'BeIN', color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('إلغاء', style: TextStyle(fontFamily: 'BeIN', color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('حفظ محلياً', style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        );

        if (saveOffline == true) {
          await Get.find<OfflineQueueController>().queueTransaction(
            type: 'submit_device',
            data: device.toJson(),
          );
          
          await AppLottieFeedback.show(
            isSuccess: true,
            title: 'تم الحفظ محلياً',
            message: 'تمت إضافة العملية إلى قائمة الانتظار للمزامنة اللاحقة.',
            onComplete: () {
              if (Get.currentRoute == Routes.submitDevice) {
                Get.offNamed(Routes.receivedDevices);
              } else {
                Get.toNamed(Routes.receivedDevices);
              }
            },
          );
          return;
        }
      }

      // إظهار رسم متحرك للفشل
      await AppLottieFeedback.show(
        isSuccess: false,
        title: 'فشل تسجيل التوريد',
        message: _error.value ?? 'فشل إرسال بيانات الجهاز. يرجى التحقق من المدخلات والمحاولة مجدداً.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> submitWithdrawnDevice(WithdrawnDevice device) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await repository.submitWithdrawnDevice(device);
      
      // بعد نجاح الإرسال نعيد تحميل قائمة الأجهزة المسحوبة
      await loadWithdrawnDevices();

      // إظهار رسم متحرك للنجاح
      await AppLottieFeedback.show(
        isSuccess: true,
        title: 'تم تسجيل سحب الجهاز بنجاح',
        message: 'تم إرسال بيانات سحب الجهاز من العميل إلى السيرفر بنجاح',
        onComplete: () {
          // العودة للوحة التحكم
          Get.offAllNamed(Routes.dashboard);
        },
      );
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      
      final isNetworkError = e.toString().contains('SocketException') || 
                            e.toString().contains('Connection refused') || 
                            e.toString().contains('Failed host lookup') ||
                            e.toString().contains('timeout');
      
      if (isNetworkError) {
        final bool? saveOffline = await Get.dialog<bool>(
          Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: Text('مشكلة في الاتصال بالشبكة', style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: Colors.white)),
              content: Text('يبدو أنك غير متصل بالإنترنت حالياً. هل تود حفظ عملية السحب محلياً ومزامنتها لاحقاً؟', style: TextStyle(fontFamily: 'BeIN', color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('إلغاء', style: TextStyle(fontFamily: 'BeIN', color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('حفظ محلياً', style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        );

        if (saveOffline == true) {
          await Get.find<OfflineQueueController>().queueTransaction(
            type: 'submit_withdrawn_device',
            data: device.toJson(),
          );
          
          await AppLottieFeedback.show(
            isSuccess: true,
            title: 'تم الحفظ محلياً',
            message: 'تمت إضافة العملية إلى قائمة الانتظار للمزامنة اللاحقة.',
            onComplete: () {
              Get.offAllNamed(Routes.dashboard);
            },
          );
          return;
        }
      }

      // إظهار رسم متحرك للفشل
      await AppLottieFeedback.show(
        isSuccess: false,
        title: 'فشل تسجيل سحب الجهاز',
        message: _error.value ?? 'فشل إرسال بيانات سحب الجهاز. يرجى التحقق من المدخلات والمحاولة مجدداً.',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deliverDeviceByBarcode(String barcode) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await repository.deliverDevice(barcode);

      Get.snackbar(
        'نجح',
        'تم تسليم وتوريد الجهاز بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      await loadDevices();
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'خطأ',
        _error.value ?? 'فشل تسليم الجهاز',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}

