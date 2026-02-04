import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/routing/app_pages.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../data/models/received_device.dart';

class DevicesController extends GetxController {
  final DevicesRepository repository;

  DevicesController({required this.repository});

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _devices = <ReceivedDevice>[].obs;
  final _pendingCount = 0.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<ReceivedDevice> get devices => _devices;
  int get pendingCount => _pendingCount.value;

  @override
  void onInit() {
    super.onInit();
    loadDevices();
  }

  Future<void> loadDevices() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final list = await repository.getReceivedDevices();
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

  Future<void> submitDevice(ReceivedDevice device) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      await repository.submitDevice(device);
      
      Get.snackbar(
        'نجح',
        'تم إرسال بيانات الجهاز بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
      // بعد نجاح الإرسال نعيد تحميل قائمة الأجهزة
      await loadDevices();

      // التوجيه إلى صفحة الأجهزة المستلمة
      if (Get.currentRoute == Routes.submitDevice) {
        Get.offNamed(Routes.receivedDevices);
      } else {
        Get.toNamed(Routes.receivedDevices);
      }
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'خطأ',
        _error.value ?? 'فشل إرسال بيانات الجهاز',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
