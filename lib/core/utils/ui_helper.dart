import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UIHelper {
  static void showErrorSnackBar(String message, {String title = 'خطأ'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  static void showSuccessSnackBar(String message, {String title = 'نجح'}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}
