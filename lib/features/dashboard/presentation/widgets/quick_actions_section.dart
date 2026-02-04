import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import 'quick_action_button.dart';

class QuickActionsSection extends StatelessWidget {
  final VoidCallback? onRequestInventory;

  const QuickActionsSection({
    super.key,
    this.onRequestInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.flash_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'quick_actions'.tr,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Actions Grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              QuickActionButton(
                icon: Icons.inventory_2,
                label: 'fixed'.tr,
                color: AppColors.primary,
                onTap: () => Get.toNamed('/fixed-inventory'),
              ),
              QuickActionButton(
                icon: Icons.local_shipping,
                label: 'moving'.tr,
                color: AppColors.purpleGradient.first,
                onTap: () => Get.toNamed('/moving-inventory'),
              ),
              QuickActionButton(
                icon: Icons.smartphone,
                label: 'الأجهزة',
                color: AppColors.success,
                onTap: () => Get.toNamed('/submit-device'),
              ),
              QuickActionButton(
                icon: Icons.request_quote,
                label: 'request_stock'.tr,
                color: AppColors.warning,
                onTap: onRequestInventory ?? () => Get.toNamed('/request-inventory'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
