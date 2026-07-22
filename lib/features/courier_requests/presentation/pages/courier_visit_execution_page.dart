import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../../shared/widgets/lottie_feedback_dialog.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/scanner/identifier_normalization_service.dart';
import '../../../../shared/scanner/scanner_item_types.dart';
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
  final ImagePicker _picker = ImagePicker();
  late int requestId;

  bool isSuccess = true;
  String? selectedFailureReason;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController posSnController = TextEditingController();
  final TextEditingController simSerialController = TextEditingController();
  final TextEditingController paperRollQtyController = TextEditingController(text: '0');
  final TextEditingController stickersQtyController = TextEditingController(text: '0');
  final TextEditingController nulipCardsQtyController = TextEditingController(text: '0');

  final FocusNode _snFocusNode = FocusNode();
  final FocusNode _simFocusNode = FocusNode();

  // Serial lookup states
  Map<String, dynamic>? _deviceLookup;
  Map<String, dynamic>? _simLookup;
  bool _snLookupLoading = false;
  bool _simLookupLoading = false;

  // Stores base64-encoded photos
  final List<String> _evidencePhotos = [];
  bool _isSubmitting = false;

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

    // Pre-fill SN/SIM from previously scanned items
    final posItem =
        controller.currentItems.firstWhereOrNull((i) => i.itemType == 'POS');
    if (posItem?.serialNumber != null) {
      posSnController.text = posItem!.serialNumber!;
    }
    final simItem =
        controller.currentItems.firstWhereOrNull((i) => i.itemType == 'SIM');
    if (simItem?.simSerial != null) {
      simSerialController.text = simItem!.simSerial!;
    }

    _snFocusNode.addListener(() {
      if (!_snFocusNode.hasFocus) {
        _doSerialLookup(posSnController.text, 'device');
      }
    });
    _simFocusNode.addListener(() {
      if (!_simFocusNode.hasFocus) {
        _doSerialLookup(simSerialController.text, 'sim');
      }
    });

    posSnController.addListener(() {
      final text = posSnController.text.trim();
      if (text.length >= 9) {
        if (!_snLookupLoading && (_deviceLookup == null || _deviceLookup!['serial'] != text)) {
          _doSerialLookup(text, 'device');
        }
      } else {
        if (_deviceLookup != null) {
          setState(() {
            _deviceLookup = null;
          });
        }
      }
    });

    simSerialController.addListener(() {
      final text = simSerialController.text.trim();
      if (text.length >= 18) {
        if (!_simLookupLoading && (_simLookup == null || _simLookup!['serial'] != text)) {
          _doSerialLookup(text, 'sim');
        }
      } else {
        if (_simLookup != null) {
          setState(() {
            _simLookup = null;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (posSnController.text.isNotEmpty) {
        _doSerialLookup(posSnController.text, 'device');
      }
      if (simSerialController.text.isNotEmpty) {
        _doSerialLookup(simSerialController.text, 'sim');
      }
    });
  }

  @override
  void dispose() {
    notesController.dispose();
    posSnController.dispose();
    simSerialController.dispose();
    paperRollQtyController.dispose();
    stickersQtyController.dispose();
    nulipCardsQtyController.dispose();
    _snFocusNode.dispose();
    _simFocusNode.dispose();
    super.dispose();
  }

  bool get _hasOwnershipMismatch {
    if (_deviceLookup == null || _simLookup == null) return false;
    final devFound = _deviceLookup!['found'] == true;
    final simFound = _simLookup!['found'] == true;
    if (!devFound || !simFound) return false;
    
    final devTechId = _deviceLookup!['technician']?['id']?.toString();
    final simTechId = _simLookup!['technician']?['id']?.toString();
    
    if (devTechId != null && simTechId != null && devTechId != simTechId) {
      return true;
    }
    return false;
  }

  Future<void> _doSerialLookup(String serial, String role) async {
    if (serial.trim().isEmpty) return;
    setState(() {
      if (role == 'device') {
        _snLookupLoading = true;
        _deviceLookup = null;
      } else {
        _simLookupLoading = true;
        _simLookup = null;
      }
    });

    try {
      final res = await controller.serialLookup(serial.trim());
      setState(() {
        if (role == 'device') {
          _deviceLookup = res;
        } else {
          _simLookup = res;
        }
      });
    } catch (e) {
      debugPrint('Serial lookup failed: $e');
    } finally {
      setState(() {
        if (role == 'device') {
          _snLookupLoading = false;
        } else {
          _simLookupLoading = false;
        }
      });
    }
  }

  // ─── Photo capture (camera or gallery) ───────────────────────────────────

  Future<void> _showPhotoSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إضافة صورة إثبات',
                  style: TextStyle(fontFamily: 'BeIN', 
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text('الكاميرا',
                    style: TextStyle(fontFamily: 'BeIN', color: Colors.white)),
                onTap: () {
                  Get.back();
                  _capturePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text('المعرض',
                    style: TextStyle(fontFamily: 'BeIN', color: Colors.white)),
                onTap: () {
                  Get.back();
                  _capturePhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() => _evidencePhotos.add(base64Str));
      Get.snackbar('📷 تم الالتقاط', 'تم إرفاق صورة إثبات بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل التقاط الصورة: ${e.toString()}',
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> _scanBarcode(TextEditingController tc, String role) async {
    final types = ScannerItemTypes.forRole(role);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerWidget(
          title: 'مسح الباركود',
          itemTypes: types,
          categoryHint: role == 'sim' ? 'sim' : 'devices',
          allowUnionOfItemTypes: true,
        ),
      ),
    );
    final raw = result is String
        ? result
        : (result is Map ? result['code'] as String? : null);
    if (raw != null) {
      // Light normalize — strip ICCID spaces; keep device letter prefixes.
      final normalized =
          IdentifierNormalizationService.normalize(raw);
      setState(() => tc.text = normalized);
      _doSerialLookup(normalized, role);
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validation
    if (isSuccess && _evidencePhotos.length < 2) {
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

    if (isSuccess && posSnController.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال الرقم التسلسلي لجهاز POS',
          backgroundColor: AppColors.warning, colorText: Colors.white);
      return;
    }

    if (isSuccess && _hasOwnershipMismatch) {
      Get.snackbar(
        '⚠️ تعارض في العهدة',
        'الجهاز والشريحة ينتميان لفنيين مختلفين. لا يمكن إغلاق الطلب.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await controller.submitExecutionAttempt(
      requestId,
      status: isSuccess ? 'SUCCESS' : 'FAILED',
      failureReasonCode: isSuccess ? null : selectedFailureReason,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      snInstalled: posSnController.text.trim().isEmpty
          ? null
          : posSnController.text.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_.]'), ''),
      simInstalled: simSerialController.text.trim().isEmpty
          ? null
          : simSerialController.text.trim(),
      paperRollQty: int.tryParse(paperRollQtyController.text.trim()) ?? 0,
      stickersQty: int.tryParse(stickersQtyController.text.trim()) ?? 0,
      nulipCardsQty: int.tryParse(nulipCardsQtyController.text.trim()) ?? 0,
      photos: _evidencePhotos,
      startTime: _startTime,
      arrivalTime: _arrivalTime,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (isSuccess) {
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
          onComplete: () async {
            await _shareWhatsApp(waMsg);
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

  Future<void> _shareWhatsApp(String msg) async {
    try {
      final encoded = Uri.encodeComponent(msg);
      final uri = Uri.parse('https://wa.me/?text=$encoded');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
                  _buildConsumablesSection(),
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
      title: RasscoBrandTitle.text('تنفيذ الزيارة الميدانية'),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x3000D9FF), AppColors.backgroundDark],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('تنفيذ الزيارة الميدانية',
                  style: TextStyle(fontFamily: 'BeIN', 
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              if (req != null)
                Text(
                  '${req.retailerName ?? req.customerName ?? ""} — طلب #$requestId',
                  style: TextStyle(fontFamily: 'BeIN', 
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
            Icon(icon,
                color: isSelected ? color : AppColors.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'BeIN', 
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                )),
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
              title: 'أرقام التسلسل المركبة', icon: Icons.qr_code_2),
          const SizedBox(height: 12),

          if (_hasOwnershipMismatch) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تعارض في العهدة: الجهاز والشريحة ينتميان لفنيين مختلفين. لا يمكن إغلاق الطلب.',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          _buildSerialField(
            label: 'سيريال جهاز POS *',
            controller: posSnController,
            icon: Icons.tablet_android,
            color: AppColors.accentPurple,
            role: 'device',
            focusNode: _snFocusNode,
          ),
          _buildLookupStatus('device'),
          _buildResolvedTechnicianCard(),

          const SizedBox(height: 16),
          _buildSerialField(
            label: 'رقم شريحة SIM (ICCID)',
            controller: simSerialController,
            icon: Icons.sim_card,
            color: AppColors.primary,
            role: 'sim',
            focusNode: _simFocusNode,
          ),
          _buildLookupStatus('sim'),
        ],
      ),
    );
  }

  Widget _buildLookupStatus(String role) {
    final isLoading = role == 'device' ? _snLookupLoading : _simLookupLoading;
    final lookup = role == 'device' ? _deviceLookup : _simLookup;
    
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 6, right: 4),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }
    
    if (lookup == null) return const SizedBox.shrink();
    
    final found = lookup['found'] == true;
    final inActiveCustody = lookup['inActiveCustody'] == true;
    final custodyStatus = lookup['custodyStatus']?.toString() ?? '';
    final itemTypeName = lookup['itemType']?['nameAr']?.toString() ?? (role == 'device' ? 'جهاز' : 'شريحة');
    
    // Resolve carrier name if present (especially for SIMs)
    final carrierName = lookup['itemType']?['carrierName']?.toString() ?? '';
    final displayName = carrierName.isNotEmpty ? '$itemTypeName ($carrierName)' : itemTypeName;
    
    final message = lookup['message']?.toString() ?? (found ? '' : 'الرقم التسلسلي غير موجود بالمنظومة');
    
    final isOk = found && inActiveCustody;
    
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 4),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_outline : Icons.error_outline_rounded,
            color: isOk ? AppColors.success : AppColors.error,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isOk
                  ? '$displayName · عهدة صالحة نشطة ($custodyStatus)'
                  : (message.isNotEmpty ? message : 'عهدة غير صالحة ($custodyStatus)'),
              style: TextStyle(fontFamily: 'BeIN', 
                color: isOk ? AppColors.success : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedTechnicianCard() {
    if (_deviceLookup == null) return const SizedBox.shrink();
    final tech = _deviceLookup!['technician'];
    if (tech == null) return const SizedBox.shrink();
    final techName = tech['fullName']?.toString() ?? 'غير محدد';
    final techCode = tech['technicianCode']?.toString() ?? tech['username']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الفني المسؤول (من عهدة الجهاز)',
                  style: TextStyle(fontFamily: 'BeIN', 
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                Text(
                  techName,
                  style: TextStyle(fontFamily: 'BeIN', 
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (techCode.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                techCode,
                style: GoogleFonts.ibmPlexMono(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    required String role,
    FocusNode? focusNode,
  }) {
    final isLoading = role == 'device' ? _snLookupLoading : _simLookupLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontFamily: 'BeIN', 
                color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
                textDirection: TextDirection.ltr,
                textCapitalization: role == 'device'
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                onChanged: role == 'device'
                    ? (val) {
                        final upper = val.toUpperCase();
                        if (val != upper) {
                          final sel = controller.selection;
                          controller.value = TextEditingValue(
                            text: upper,
                            selection: sel,
                          );
                        }
                      }
                    : null,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: color, size: 20),
                  hintText: 'أدخل الرقم أو امسح',
                  hintStyle:
                      TextStyle(fontFamily: 'BeIN', color: AppColors.textMuted, fontSize: 12),
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
              onTap: isLoading ? null : () => _doSerialLookup(controller.text, role),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(Icons.search, color: color, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _scanBarcode(controller, role),
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

  Widget _buildConsumablesSection() {
    Widget qtyField({
      required String label,
      required TextEditingController controller,
      String? hint,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'BeIN', 
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint ?? '0',
                hintStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'المواد المستهلكة المسلّمة',
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            'تُخصم تلقائياً من مخزون الفني عند إكمال التسليم',
            style: TextStyle(fontFamily: 'BeIN', 
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              qtyField(
                label: 'عدد الرول',
                controller: paperRollQtyController,
              ),
              const SizedBox(width: 10),
              qtyField(
                label: 'الملصقات',
                controller: stickersQtyController,
              ),
              const SizedBox(width: 10),
              qtyField(
                label: 'نيوليب (اختياري)',
                controller: nulipCardsQtyController,
              ),
            ],
          ),
        ],
      ),
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
            style: TextStyle(fontFamily: 'BeIN', 
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
              ..._evidencePhotos.asMap().entries.map((entry) {
                final photo = entry.value;
                return Stack(
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
                        onTap: () => setState(
                            () => _evidencePhotos.removeAt(entry.key)),
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
                );
              }),
              if (_evidencePhotos.length < 6)
                GestureDetector(
                  onTap: _showPhotoSourceDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundMid,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSufficient
                            ? AppColors.border
                            : AppColors.warning.withOpacity(0.4),
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
                        Text('إضافة صورة',
                            style: TextStyle(fontFamily: 'BeIN', 
                              color: isSufficient
                                  ? AppColors.textMuted
                                  : AppColors.warning,
                              fontSize: 10,
                            )),
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
                style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
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
            style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 13),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أي ملاحظات ميدانية إضافية للمشرف...',
              hintStyle:
                  TextStyle(fontFamily: 'BeIN', color: AppColors.textMuted, fontSize: 12),
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
              Text('رسالة WhatsApp للمشرف (تُرسل بعد الإغلاق)',
                  style: TextStyle(fontFamily: 'BeIN', 
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(message,
                style: TextStyle(fontFamily: 'BeIN', 
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.6)),
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
                      style: TextStyle(fontFamily: 'BeIN', 
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
                  icon: isSuccess ? Icons.send : Icons.report_problem_outlined,
                  gradient: isSuccess
                      ? AppColors.gradientSuccess
                      : AppColors.gradientError,
                  onPressed: canSubmit
                      ? (controller.isLoading || _isSubmitting ? null : _submit)
                      : null,
                  isLoading: controller.isLoading || _isSubmitting,
                  height: 52,
                )),
          ],
        ),
      ),
    );
  }
}
