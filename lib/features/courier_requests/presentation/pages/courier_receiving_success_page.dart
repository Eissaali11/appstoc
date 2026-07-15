import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../controllers/courier_requests_controller.dart';
import '../../../../core/routing/app_pages.dart';

class CourierReceivingSuccessPage extends GetView<CourierRequestsController> {
  const CourierReceivingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = controller.currentRequest;
    if (request == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: NeonButton(
            label: 'العودة للرئيسية',
            onPressed: () => Get.offAllNamed(Routes.dashboard),
          ),
        ),
      );
    }

    final receivedCount = controller.currentItems.where((item) =>
        item.itemType == 'POS' || item.itemType == 'SIM').length;

    final accessoriesCount = controller.currentItems.where((item) =>
        item.itemType != 'POS' && item.itemType != 'SIM').length;

    final trxRef = 'TRX-2026-${request.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Success pulsing green indicator
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withOpacity(0.3), width: 4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'تم نقل العهدة بنجاح',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تمت مطابقة الأصول ونقل مسؤولية الأجهزة والشرائح إلى ذمتك الميدانية بنجاح.',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Transaction Summary Card
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('رقم العملية', style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13)),
                        Text(trxRef, style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 24),
                    _buildSummaryRow('الأجهزة والشرائح المستلمة', '$receivedCount أصول'),
                    const SizedBox(height: 12),
                    _buildSummaryRow('الملحقات والمستندات', '$accessoriesCount ملحقات ورقية'),
                    const SizedBox(height: 12),
                    _buildSummaryRow('حالة العهدة الحالية', 'استلام بمستودع الفني', color: AppColors.success),
                  ],
                ),
              ),
              
              const Spacer(),

              // Action buttons
              Column(
                children: [
                  NeonButton(
                    onPressed: () async {
                      final success = await controller.startTask(request.id);
                      if (success) {
                        Get.offAllNamed(Routes.courierRequests);
                        Get.snackbar(
                          'بدء المهمة',
                          'تم بدء مهمة التوصيل وتحديث حالة الأصول إلى (IN_TRANSIT)',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                        );
                      }
                    },
                    label: 'بدء المهمة ومغادرة المستودع (In Transit)',
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Get.offAllNamed(Routes.courierRequests);
                    },
                    child: Text(
                      'العودة إلى قائمة الطلبات',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'BeIN', 
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontFamily: 'BeIN', 
            color: color ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
