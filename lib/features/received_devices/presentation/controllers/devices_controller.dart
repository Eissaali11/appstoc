import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../data/models/received_device.dart';

class DevicesController extends GetxController {
  final DevicesRepository repository;

  DevicesController({required this.repository});

  final _isLoading = false.obs;
  final _error = Rxn<String>();

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

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
      
      // Clear form after success
      Get.back();
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
