import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/lottie_feedback_dialog.dart';
import '../controllers/courier_requests_controller.dart';
import '../../data/models/courier_request_model.dart';

class CourierRequestDetailsPage extends StatefulWidget {
  const CourierRequestDetailsPage({super.key});

  @override
  State<CourierRequestDetailsPage> createState() =>
      _CourierRequestDetailsPageState();
}

class _CourierRequestDetailsPageState
    extends State<CourierRequestDetailsPage> {
  final CourierRequestsController controller =
      Get.find<CourierRequestsController>();
  late int requestId;

  @override
  void initState() {
    super.initState();
    requestId = Get.arguments as int;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadRequestDetails(requestId);
    });
  }

  // ============================================================
  // Actions
  // ============================================================

  Future<void> _handleAccept() async {
    final confirmed = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientCard,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 44),
                ),
                const SizedBox(height: 16),
                Text(
                  'قبول العهدة والطلب',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'سيتم نقلك فوراً لشاشة مسح الأجهزة للتحقق من هويتها وربطها بعهدتك.',
                  style: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('إلغاء',
                            style: GoogleFonts.cairo(
                                color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: NeonButton.success(
                        label: 'قبول ومسح الأجهزة',
                        icon: Icons.qr_code_scanner,
                        onPressed: () => Get.back(result: true),
                        height: 48,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final success = await controller.acceptRequest(requestId);
      if (success) {
        await controller.startReceivingSession(requestId);
        await AppLottieFeedback.show(
          isSuccess: true,
          title: 'تم قبول الطلب ✅',
          message: 'جلسة المسح بدأت. يرجى مسح الأجهزة للتحقق من هويتها.',
          onComplete: () {
            Get.toNamed('/courier-request-scanner', arguments: requestId);
          },
        );
      } else {
        _showError(controller.error ?? 'فشل قبول الطلب');
      }
    }
  }

  Future<void> _handleReject() async {
    final reasonController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientCard,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 44),
                ),
                const SizedBox(height: 16),
                Text(
                  'رفض الطلب والعهدة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'سبب الرفض (مثال: الأجهزة غير متطابقة)',
                    hintStyle:
                        GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.backgroundMid,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('إلغاء',
                            style: GoogleFonts.cairo(
                                color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: NeonButton.error(
                        label: 'تأكيد الرفض',
                        icon: Icons.cancel,
                        height: 48,
                        fontSize: 13,
                        onPressed: () {
                          if (reasonController.text.trim().isEmpty) {
                            Get.snackbar('تنبيه', 'يجب كتابة سبب الرفض',
                                backgroundColor: AppColors.error,
                                colorText: Colors.white);
                            return;
                          }
                          Get.back(result: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final itemStatuses = controller.currentItems.map((item) => {
            'itemId': item.id,
            'status': 'REJECTED',
            'reason': reasonController.text.trim(),
          }).toList();

      final success = await controller.confirmReceiving(requestId, itemStatuses);
      if (success) {
        await AppLottieFeedback.show(
          isSuccess: true,
          title: 'تم رفض الطلب',
          message: 'تم إرجاع العهدة للمستودع وتسجيل سبب الرفض.',
          onComplete: () => Get.back(),
        );
      } else {
        _showError(controller.error ?? 'فشل تنفيذ عملية الرفض');
      }
    }
  }

  void _showError(String msg) {
    Get.snackbar(
      'خطأ',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Obx(() {
        final req = controller.currentRequest;
        final items = controller.currentItems;

        if (controller.isLoading && req == null) {
          return _buildLoadingSkeleton();
        }
        if (req == null) {
          return Center(
            child: Text('تعذر تحميل تفاصيل الطلب',
                style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          );
        }

        final status = (req.installationStatus ?? '').toUpperCase();
        final statusColor = AppColors.statusColor(req.installationStatus);

        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(req, statusColor, status),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Active session alert
                  if ((status == 'ACCEPTED' ||
                          status == 'RECEIVING' ||
                          status == 'PARTIALLY_RECEIVED') &&
                      controller.hasSessionInProgress.value)
                    _buildActiveSessionAlert(),

                  // Customer & request info
                  _buildInfoCard(req),
                  const SizedBox(height: 16),

                  // Items list
                  _buildItemsSection(items),
                ]),
              ),
            ),
          ],
        );
      }),
      bottomSheet: Obx(() {
        final req = controller.currentRequest;
        if (req == null) return const SizedBox.shrink();
        return _buildBottomActions(req);
      }),
    );
  }

  Widget _buildSliverAppBar(
      CourierRequest req, Color statusColor, String status) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withOpacity(0.2),
                AppColors.backgroundDark,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'طلب #${req.id}',
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  StatusBadge(text: req.statusText, color: statusColor),
                  if (req.city != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      req.city!,
                      style: GoogleFonts.cairo(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSessionAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          PulsingDot(color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جلسة استلام نشطة',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                Text(
                  'مكتملة ${(controller.getSessionProgress() * 100).toInt()}% — استمر من حيث توقفت',
                  style: GoogleFonts.cairo(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed('/courier-request-scanner',
                arguments: requestId),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Text(
                'متابعة',
                style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CourierRequest req) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'تفاصيل الطلب',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 8),
          InfoRow(
            icon: Icons.person_outline,
            label: 'العميل',
            value: req.customerName ?? 'غير محدد',
          ),
          InfoRow(
            icon: Icons.storefront_outlined,
            label: 'التاجر / المحل',
            value: req.retailerName ?? 'غير محدد',
          ),
          InfoRow(
            icon: Icons.location_on_outlined,
            label: 'العنوان',
            value: req.addressAr ?? req.addressEn ?? 'غير محدد',
          ),
          InfoRow(
            icon: Icons.phone_outlined,
            label: 'الجوال',
            value: req.mobile ?? 'غير محدد',
          ),
          if (req.mobile2 != null && req.mobile2!.isNotEmpty)
            InfoRow(
              icon: Icons.phone_android_outlined,
              label: 'جوال إضافي',
              value: req.mobile2!,
            ),
          InfoRow(
            icon: Icons.settings_applications_outlined,
            label: 'نوع المعاملة',
            value: req.installationType ?? 'غير محدد',
          ),
          InfoRow(
            icon: Icons.supervisor_account_outlined,
            label: 'المشرف المرسل',
            value: req.createdByName ?? 'غير محدد',
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<CourierRequestItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'المواد المرفقة (${items.length} عنصر)',
          icon: Icons.inventory_2_outlined,
          color: AppColors.accentPurple,
          trailing: items.isEmpty
              ? null
              : StatusBadge(
                  text: 'تتطلب مسح',
                  color: AppColors.warning,
                  fontSize: 11,
                ),
        ),
        if (items.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'لا توجد مواد مدرجة بعد — سيتم تعيينها من المشرف',
                  style: GoogleFonts.cairo(
                      color: AppColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ...items.map((item) => _buildItemCard(item)),
      ],
    );
  }

  Widget _buildItemCard(CourierRequestItem item) {
    final localStatus = controller.localItemStatuses[item.id];
    final isScanned = localStatus == 'RECEIVED';
    final hasProblem = localStatus != null &&
        localStatus != 'RECEIVED' &&
        localStatus != 'PENDING_RECEIPT';

    IconData icon;
    String name;
    String serialText;
    Color borderColor;

    if (item.itemType == 'POS') {
      icon = Icons.tablet_android;
      name = 'جهاز دفع إلكتروني (POS)';
      serialText = item.serialNumber ??
          controller.localScannedSerials[item.id] ??
          'بانتظار المسح الضوئي';
      borderColor = isScanned
          ? AppColors.success
          : hasProblem
              ? AppColors.error
              : AppColors.accentPurple;
    } else if (item.itemType == 'SIM') {
      icon = Icons.sim_card;
      name = 'شريحة اتصال (SIM)';
      serialText = item.simSerial ??
          controller.localScannedSerials[item.id] ??
          'بانتظار المسح الضوئي';
      borderColor = isScanned
          ? AppColors.success
          : hasProblem
              ? AppColors.error
              : AppColors.primary;
    } else if (item.itemType == 'ACCESSORY') {
      icon = Icons.cable;
      name = 'ملحق / شاحن / ورق حراري';
      serialText = 'الكمية: ${item.quantity}';
      borderColor = AppColors.border;
    } else {
      icon = Icons.description;
      name = 'أوراق / عقود / ملصقات';
      serialText = 'توقيع وتسليم';
      borderColor = AppColors.border;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: borderColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                Text(
                  serialText,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isScanned)
            const Icon(Icons.check_circle, color: AppColors.success, size: 20)
          else if (hasProblem)
            const Icon(Icons.warning_amber, color: AppColors.error, size: 20)
          else
            Icon(Icons.qr_code, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildBottomActions(CourierRequest req) {
    final status = (req.installationStatus ?? '').toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: _buildActionButtons(status),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (status == 'ASSIGNED') {
      return Row(
        children: [
          Expanded(
            child: NeonButton.error(
              label: 'رفض',
              icon: Icons.cancel,
              onPressed: controller.isLoading ? null : _handleReject,
              height: 52,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: NeonButton.success(
              label: 'قبول ومسح الأجهزة',
              icon: Icons.qr_code_scanner,
              onPressed: controller.isLoading ? null : _handleAccept,
              isLoading: controller.isLoading,
              height: 52,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (status == 'ACCEPTED' ||
        status == 'RECEIVING' ||
        status == 'PARTIALLY_RECEIVED') {
      return NeonButton(
        label: controller.hasSessionInProgress.value
            ? 'متابعة مسح الأجهزة والتحقق'
            : 'بدء جلسة الاستلام والمسح',
        icon: Icons.qr_code_scanner,
        gradient: AppColors.gradientPrimary,
        onPressed: () async {
          if (!controller.hasSessionInProgress.value) {
            await controller.startReceivingSession(requestId);
          }
          Get.toNamed('/courier-request-scanner', arguments: requestId);
        },
        height: 52,
      );
    }

    if (status == 'RECEIVED') {
      return NeonButton(
        label: 'بدء التوجه للعميل',
        icon: Icons.directions_car,
        gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
        onPressed: controller.isLoading
            ? null
            : () async {
                final success = await controller.startRoute(requestId);
                if (success) {
                  Get.snackbar('تم', 'الحالة: في الطريق للعميل',
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM);
                }
              },
        isLoading: controller.isLoading,
        height: 52,
      );
    }

    if (status == 'ON_ROUTE') {
      return NeonButton(
        label: 'تأكيد الوصول للعميل',
        icon: Icons.location_on,
        gradient: AppColors.gradientWarning,
        onPressed: controller.isLoading
            ? null
            : () async {
                final success = await controller.arriveCustomer(requestId);
                if (success) {
                  Get.snackbar('تم الوصول', 'الحالة: تم الوصول لموقع العميل',
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM);
                }
              },
        isLoading: controller.isLoading,
        height: 52,
      );
    }

    if (status == 'ARRIVED') {
      return NeonButton(
        label: 'بدء التركيب والتشغيل',
        icon: Icons.build,
        gradient: AppColors.gradientPrimary,
        onPressed: controller.isLoading
            ? null
            : () async {
                final success = await controller.startInstallation(requestId);
                if (success) {
                  Get.snackbar('تم', 'الحالة: جاري التركيب والتشغيل',
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM);
                }
              },
        isLoading: controller.isLoading,
        height: 52,
      );
    }

    if (status == 'INSTALLING') {
      return NeonButton.success(
        label: 'تنفيذ وإغلاق المهمة الميدانية',
        icon: Icons.check_circle_outline,
        onPressed: () =>
            Get.toNamed('/courier-visit-execution', arguments: requestId),
        height: 52,
      );
    }

    return Text(
      'الطلب في حالة ($status) — لا يتطلب إجراءات',
      textAlign: TextAlign.center,
      style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(backgroundColor: AppColors.surfaceDark),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
