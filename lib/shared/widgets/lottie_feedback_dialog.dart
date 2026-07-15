import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class AppLottieFeedback {
  /// Displays a professional Lottie-based dialog for operations feedback.
  /// If the user is offline or the Lottie JSON fails to fetch, it falls back to a clean vector icon.
  static Future<void> show({
    required bool isSuccess,
    required String title,
    required String message,
    VoidCallback? onComplete,
  }) async {
    await Get.dialog(
      Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Animation container
              SizedBox(
                height: 140,
                width: 140,
                child: Lottie.network(
                  isSuccess
                      ? 'https://lottie.host/e6ec7c6b-67e4-4d89-9e8c-8c5f590d645e/8L5F5H8H6Q.json' // Elegant Green Success Check
                      : 'https://lottie.host/9c8b7468-d0df-4d6b-b4a8-d99f7d2bf610/U2H4H5H6Q.json', // Elegant Red Error Cross
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        isSuccess ? Icons.check_circle : Icons.cancel,
                        color: isSuccess ? AppColors.success : AppColors.error,
                        size: 96,
                      ),
                    );
                  },
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // close dialog
                    if (onComplete != null) onComplete();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.success : AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'موافق',
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
