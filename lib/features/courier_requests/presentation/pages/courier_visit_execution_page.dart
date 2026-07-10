import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/lottie_feedback_dialog.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../controllers/courier_requests_controller.dart';

class CourierVisitExecutionPage extends StatefulWidget {
  const CourierVisitExecutionPage({super.key});

  @override
  State<CourierVisitExecutionPage> createState() =>
      _CourierVisitExecutionPageState();
}

class _CourierVisitExecutionPageState
    extends State<CourierVisitExecutionPage> {
  final CourierRequestsController controller =
      Get.find<CourierRequestsController>();
  late int requestId;

  bool isSuccess = true;
  String? selectedFailureReason;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController posSnController = TextEditingController();
  final TextEditingController simSerialController = TextEditingController();
  final List<String> _evidencePhotos = [];
  final DateTime _startTime =
      DateTime.now().subtract(const Duration(minutes: 15));
  final DateTime _arrivalTime =
      DateTime.now().subtract(const Duration(minutes: 10));

  final List<Map<String, String>> failureReasons = [
    {'code': 'CUST_NOT_ANSWER', 'name': 'العميل لا يجيب على الاتصالات'},
    {'code': 'CUST_REFUSED', 'name': 'العميل رفض استلام الأجهزة'},
    {'code': 'WRONG_LOCATION', 'name': 'الموقع الجغرافي للعميل خاطئ'},
    {'code': 'TECH_ISSUES', 'name': 'مشاكل تقنية في شبكة التفعيل'},
    {'code': 'OTHER', 'name': 'أسباب تشغيلية أخرى'},
  ];

  @override
  void initState() {
    super.initState();
    requestId = Get.arguments as int;
    selectedFailureReason = failureReasons.first['code'];

    final posItem = controller.currentItems
        .firstWhereOrNull((i) => i.itemType == 'POS');
    if (posItem?.serialNumber != null) {
      posSnController.text = posItem!.serialNumber!;
    }
    final simItem = controller.currentItems
        .firstWhereOrNull((i) => i.itemType == 'SIM');
    if (simItem?.simSerial != null) {
      simSerialController.text = simItem!.simSerial!;
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    posSnController.dispose();
    simSerialController.dispose();
    super.dispose();
  }

  // ============================================================
  // Photo Capture
  // ============================================================
  void _addPhoto() {
    // Mock: In production use image_picker
    const mockBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
    setState(() => _evidencePhotos.add(mockBase64));
    Get.snackbar(
      '📷 تم الالتقاط',
      'تم إرفاق صورة إثبات بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  Future<void> _scanBarcode(TextEditingController tc) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerWidget(
          title: 'مسح الباركود',
        ),
      ),
    );
    if (result != null) tc.text = result;
  }

  // ============================================================
  // Submit
  // ============================================================
  Future<void> _submit() async {
    if (_evidencePhotos.length < 2 && isSuccess) {
      Get.snackbar(
        '⚠️ يجب التقاط صور الإثبات',
        'التقط صورتين على الأقل قبل إغلاق المهمة (${_evidencePhotos.length}/2)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    final success = await controller.submitExecutionAttempt(
      requestId,
      status: isSuccess ? 'SUCCESS' : 'FAILED',
      failureReasonCode: isSuccess ? null : selectedFailureReason,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      snInstalled: posSnController.text.trim().isEmpty
          ? null
          : posSnController.text.trim(),
      simInstalled: simSerialController.text.trim().isEmpty
          ? null
          : simSerialController.text.trim(),
      photos: _evidencePhotos,
      startTime: _startTime,
      arrivalTime: _arrivalTime,
    );

    if (success) {
      if (isSuccess) {
        // Build WhatsApp message
        final req = controller.currentRequest;
        final waMsg = '✅ *تم التركيب والتسليم*\n'
            'العميل: ${req?.customerName ?? "-"}\n'
            'رقم الطلب: #$requestId\n'
            'SN: ${posSnController.text.trim()}\n'
            'SIM: ${simSerialController.text.trim()}\n'
            '${notesController.text.trim().isNotEmpty ? "ملاحظات: ${notesController.text.trim()}" : ""}';

        await AppLottieFeedback.show(
          isSuccess: true,
          title: '✅ تم إغلاق المهمة بنجاح!',
          message: 'تم رفع تقرير التنفيذ. شارك التقرير مع المشرف عبر الواتساب.',
          onComplete: () {
            _shareWhatsApp(waMsg);
            Get.until((route) => route.isFirst);
          },
        );
      } else {
        await AppLottieFeedback.show(
          isSuccess: false,
          title: 'تم تسجيل إخفاق المهمة',
          message: 'سيتم إعادة جدولة الطلب من قبل المشرف.',
          onComplete: () => Get.until((route) => route.isFirst),
        );
      }
    } else {
      Get.snackbar(
        '❌ خطأ',
        controller.error ?? 'فشل رفع التقرير',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void _shareWhatsApp(String msg) {
    try {
      final encoded = Uri.encodeComponent(msg);
      final url = 'https://wa.me/?text=$encoded';
      // In production: use url_launcher package
      debugPrint('WhatsApp URL: $url');
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
    }
  }

  // ============================================================
  // Build
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOutcomeSelector(),
                const SizedBox(height: 20),
                if (isSuccess) ...[
                  _buildSerialInputs(),
                  const SizedBox(height: 20),
                  _buildPhotoGrid(),
                  const SizedBox(height: 20),
                ] else ...[
                  _buildFailureReasonSelector(),
                  const SizedBox(height: 20),
                ],
                _buildNotesField(),
                const SizedBox(height: 20),
                if (isSuccess) _buildWhatsAppPreview(),
              ]),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    final req = controller.currentRequest;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x3000D9FF),
                AppColors.backgroundDark,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'تنفيذ الزيارة الميدانية',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (req != null)
                Text(
                  '${req.retailerName ?? req.customerName ?? ""} — طلب #$requestId',
                  style: GoogleFonts.cairo(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'نتيجة الزيارة',
            icon: Icons.flag_outlined,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOutcomeOption(
                  label: 'تم التركيب بنجاح',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                  isSelected: isSuccess,
                  onTap: () => setState(() => isSuccess = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOutcomeOption(
                  label: 'تعذّر التنفيذ',
                  icon: Icons.cancel,
                  color: AppColors.error,
                  isSelected: !isSuccess,
                  onTap: () => setState(() => isSuccess = false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeOption({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.backgroundMid,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialInputs() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'أرقام التسلسل المركبة',
            icon: Icons.qr_code_2,
          ),
          const SizedBox(height: 12),
          _buildSerialField(
            label: 'سيريال جهاز POS',
            controller: posSnController,
            icon: Icons.tablet_android,
            color: AppColors.accentPurple,
          ),
          const SizedBox(height: 12),
          _buildSerialField(
            label: 'رقم شريحة SIM (ICCID)',
            controller: simSerialController,
            icon: Icons.sim_card,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSerialField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: color, size: 20),
                  hintText: 'أدخل الرقم أو امسح',
                  hintStyle: GoogleFonts.cairo(
                      color: AppColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.backgroundMid,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _scanBarcode(controller),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(Icons.qr_code_scanner, color: color, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    const required = 2;
    final count = _evidencePhotos.length;
    final isSufficient = count >= required;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'صور الإثبات الميداني',
            icon: Icons.camera_alt_outlined,
            color: isSufficient ? AppColors.success : AppColors.warning,
            trailing: StatusBadge(
              text: '$count/${required}+ مطلوب',
              color: isSufficient ? AppColors.success : AppColors.warning,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'صوّر: ظهر الجهاز · شاشة TID · استمارة موقّعة · الشريحة',
            style: GoogleFonts.cairo(
                color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              ..._evidencePhotos.map((photo) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(photo),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _evidencePhotos.remove(photo)),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  )),
              if (_evidencePhotos.length < 6)
                GestureDetector(
                  onTap: _addPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSufficient
                            ? AppColors.border
                            : AppColors.warning.withOpacity(0.4),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: isSufficient
                              ? AppColors.textMuted
                              : AppColors.warning,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'إضافة صورة',
                          style: GoogleFonts.cairo(
                            color: isSufficient
                                ? AppColors.textMuted
                                : AppColors.warning,
                            fontSize: 10,
                          ),
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

  Widget _buildFailureReasonSelector() {
    return GlassCard(
      borderColor: AppColors.error.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'سبب الإخفاق',
            icon: Icons.report_problem_outlined,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: AppColors.surfaceMid,
                value: selectedFailureReason,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                items: failureReasons
                    .map((r) => DropdownMenuItem(
                          value: r['code'],
                          child: Text(r['name']!),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => selectedFailureReason = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'ملاحظات إضافية (اختياري)',
            icon: Icons.notes,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أي ملاحظات ميدانية إضافية للمشرف...',
              hintStyle:
                  GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AppColors.backgroundMid,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppPreview() {
    final req = controller.currentRequest;
    final message = '✅ *تقرير التركيب*\n'
        'العميل: ${req?.customerName ?? req?.retailerName ?? "-"}\n'
        'الطلب: #$requestId\n'
        'POS SN: ${posSnController.text.trim().isEmpty ? "—" : posSnController.text.trim()}\n'
        'SIM: ${simSerialController.text.trim().isEmpty ? "—" : simSerialController.text.trim()}\n'
        '${notesController.text.trim().isNotEmpty ? "ملاحظات: ${notesController.text.trim()}" : ""}';

    return GlassCard(
      borderColor: const Color(0xFF25D366).withOpacity(0.3),
      backgroundColor: const Color(0xFF25D366).withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.message, color: Color(0xFF25D366), size: 20),
              const SizedBox(width: 8),
              Text(
                'رسالة WhatsApp للمشرف (تُرسل بعد الإغلاق)',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: GoogleFonts.cairo(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canSubmit = !isSuccess || _evidencePhotos.length >= 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canSubmit)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'التقط ${2 - _evidencePhotos.length} صورة إثبات أخرى قبل الإغلاق',
                      style: GoogleFonts.cairo(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Obx(() => NeonButton(
                  label: isSuccess
                      ? 'إغلاق المهمة ومشاركة التقرير'
                      : 'تسجيل الإخفاق وإعادة الجدولة',
                  icon:
                      isSuccess ? Icons.send : Icons.report_problem_outlined,
                  gradient: isSuccess
                      ? AppColors.gradientSuccess
                      : AppColors.gradientError,
                  onPressed: canSubmit
                      ? (controller.isLoading ? null : _submit)
                      : null,
                  isLoading: controller.isLoading,
                  height: 52,
                )),
          ],
        ),
      ),
    );
  }
}
