import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/ui_helper.dart';
import '../../../../shared/widgets/design_system.dart';
import '../controllers/courier_requests_controller.dart';
import '../../../../core/routing/app_pages.dart';
import '../../data/models/courier_request_model.dart';

class CourierRequestReviewPage extends GetView<CourierRequestsController> {
  const CourierRequestReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final request = controller.currentRequest;
    if (request == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            'حدث خطأ في استرداد بيانات الجلسة',
            style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'مراجعة واستلام العهدة',
          style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final receivedItems = controller.currentItems.where((item) =>
            controller.localItemStatuses[item.id] == 'RECEIVED').toList();

        final problemItems = controller.currentItems.where((item) =>
            controller.localItemStatuses[item.id] != null &&
            controller.localItemStatuses[item.id] != 'RECEIVED' &&
            controller.localItemStatuses[item.id] != 'PENDING_RECEIPT').toList();

        final accessories = controller.currentItems.where((item) =>
            item.itemType != 'POS' && item.itemType != 'SIM').toList();

        final checkedAccessoriesCount = accessories.where((item) =>
            controller.checkedAccessories.contains(item.id)).length;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Session info card
                  _buildSessionInfoCard(request),
                  const SizedBox(height: 16),

                  // Received items section
                  SectionHeader(
                    title: 'الأصول المستلمة والجاهزة (${receivedItems.length})',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  if (receivedItems.isEmpty)
                    _buildEmptyState('لم يتم مسح أي جهاز بنجاح بعد')
                  else
                    ...receivedItems.map((item) => _buildReceivedItemCard(item)),
                  const SizedBox(height: 16),

                  // Discrepancies section
                  SectionHeader(
                    title: 'المشكلات والفجوات (${problemItems.length})',
                    icon: Icons.report_problem_outlined,
                    color: AppColors.warning,
                  ),
                  if (problemItems.isEmpty)
                    _buildEmptyState('لا توجد بلاغات نقص أو تلفيات')
                  else
                    ...problemItems.map((item) => _buildProblemItemCard(item)),
                  const SizedBox(height: 16),

                  // Accessories status
                  SectionHeader(
                    title: 'الملحقات والمستندات',
                    icon: Icons.list_alt,
                    color: AppColors.primary,
                  ),
                  _buildAccessoriesSummaryCard(checkedAccessoriesCount, accessories.length),
                  const SizedBox(height: 16),

                  // Evidence Photos section
                  SectionHeader(
                    title: 'صور إثبات الاستلام (مطلوب)',
                    icon: Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                  _buildEvidencePhotosCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            
            // Confirm block
            _buildBottomActionBar(request),
          ],
        );
      }),
    );
  }

  Widget _buildSessionInfoCard(dynamic request) {
    final sessId = controller.sessionId.value;
    final displayId = sessId.length > 14 ? '${sessId.substring(0, 14)}...' : sessId;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'رمز الجلسة: $displayId',
                style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
              ),
              StatusBadge(
                text: 'قيد المراجعة',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'طلب رقم #${request.id}',
            style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'العميل: ${request.customerName ?? "غير محدد"}',
            style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontFamily: 'BeIN', color: AppColors.textMuted, fontSize: 14),
      ),
    );
  }

  Widget _buildReceivedItemCard(CourierRequestItem item) {
    final isPos = item.itemType == 'POS';
    final serial = (isPos ? item.serialNumber : item.simSerial) ?? controller.localScannedSerials[item.id] ?? 'غير معروف';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPos ? Icons.tablet_android : Icons.sim_card,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPos ? 'أجهزة نقاط البيع POS' : 'شرائح اتصال SIM',
                  style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'الرقم التسلسلي: $serial',
                  style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.check, color: AppColors.success, size: 18),
        ],
      ),
    );
  }

  Widget _buildProblemItemCard(CourierRequestItem item) {
    final isPos = item.itemType == 'POS';
    final serial = (isPos ? item.serialNumber : item.simSerial) ?? controller.localScannedSerials[item.id] ?? 'غير معروف';
    final status = controller.localItemStatuses[item.id] ?? 'UNKNOWN';
    final reason = controller.localProblemReasons[item.id] ?? 'بدون سبب مذكور';

    Color statusColor = AppColors.warning;
    String statusText = 'غير محدد';
    switch (status) {
      case 'MISSING':
        statusColor = AppColors.error;
        statusText = 'مفقود';
        break;
      case 'DAMAGED':
        statusColor = Colors.orange;
        statusText = 'تالف/متضرر';
        break;
      case 'WRONG_ITEM':
        statusColor = Colors.purple;
        statusText = 'جهاز خاطئ';
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        statusText = 'مرفوض';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPos ? Icons.tablet_android : Icons.sim_card,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isPos ? 'أجهزة نقاط البيع POS' : 'شرائح اتصال SIM',
                style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              StatusBadge(
                text: statusText,
                color: statusColor,
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 16),
          Text(
            'الرقم التسلسلي: $serial',
            style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'السبب: $reason',
            style: TextStyle(fontFamily: 'BeIN', color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoriesSummaryCard(int checked, int total) {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المطابقة والتحقق من الملحقات الورقية:',
            style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            '$checked / $total',
            style: TextStyle(fontFamily: 'BeIN', 
              color: checked == total ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencePhotosCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يرجى التقاط صورتين على الأقل لإثبات حالة الكرتون والمحتويات قبل التأكيد.',
            style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              ...controller.evidencePhotos.map((photo) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(photo),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => controller.evidencePhotos.remove(photo),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              )),
              if (controller.evidencePhotos.length < 3)
                GestureDetector(
                  onTap: () {
                    const mockBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAExJREFUeNrswQENAAAAwqD3T20PBxQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOBjQYAAAgwABQ==';
                    controller.addEvidencePhotoLocal(mockBase64);
                    Get.snackbar(
                      'تم التقاط الصورة',
                      'تم إرفاق صورة إثبات الاستلام بنجاح',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'إضافة صورة',
                          style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(dynamic request) {
    final photoCount = controller.evidencePhotos.length;
    final canConfirm = photoCount >= 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canConfirm)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'يجب التقاط صورتين إثبات استلام على الأقل للتأكيد ($photoCount/2)',
                    style: TextStyle(fontFamily: 'BeIN', color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          NeonButton.success(
            label: 'تأكيد واستلام العهدة ومطابقة الأصول',
            icon: Icons.check_circle,
            onPressed: canConfirm
                ? () async {
                    final success = await controller.submitConfirmReceiving(request.id);
                    if (success) {
                      Get.offNamed(Routes.courierRequestSuccess);
                    } else {
                      UIHelper.showErrorSnackBar('حدث خطأ أثناء تأكيد الاستلام.');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
