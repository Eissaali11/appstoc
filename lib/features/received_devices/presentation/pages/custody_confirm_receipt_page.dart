import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/utils/barcode_validator.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';

/// CustodyConfirmReceiptPage — v3.0 Real-Time Scan Model
/// كل مسح يُرسل فوراً للـ API — السيريال يُنشأ لحظة المسح
class CustodyConfirmReceiptPage extends StatefulWidget {
  final WarehouseTransfer transfer;

  const CustodyConfirmReceiptPage({
    super.key,
    required this.transfer,
  });

  @override
  State<CustodyConfirmReceiptPage> createState() => _CustodyConfirmReceiptPageState();
}

class _CustodyConfirmReceiptPageState extends State<CustodyConfirmReceiptPage>
    with SingleTickerProviderStateMixin {
  // Local state: serials already confirmed with the server
  final List<_ScannedSerial> _confirmedSerials = [];

  // Manual input
  final TextEditingController _manualController = TextEditingController();
  final FocusNode _manualFocus = FocusNode();

  bool _isScanning = false; // scanning in progress (API call)
  bool _submitting = false; // final confirmation in progress
  String? _lastError;

  final DashboardController _controller = Get.find<DashboardController>();

  bool get isSerialized {
    final type = _controller.itemTypesMap[widget.transfer.itemType];
    if (type != null) {
      return type.requiresSerial == true || type.category == 'devices' || type.category == 'sim';
    }
    return [
      'n950',
      'i9000s',
      'i9100',
      'mobilySim',
      'stcSim',
      'zainSim',
      'lebara',
      'lebaraSim',
    ].contains(widget.transfer.itemType);
  }

  bool get isComplete =>
      !isSerialized || _confirmedSerials.length >= widget.transfer.quantity;

  @override
  void dispose() {
    _manualController.dispose();
    _manualFocus.dispose();
    super.dispose();
  }

  Future<void> _scanSerial(String rawSn) async {
    final sn = rawSn.trim();
    if (sn.isEmpty) return;

    // التحقق من صحة الرقم التسلسلي باستخدام البينات الخاصة بنوع الصنف
    final selectedType = _controller.itemTypesMap[widget.transfer.itemType];
    if (selectedType != null) {
      final validationError = BarcodeValidator.validate(sn, selectedType);
      if (validationError != null) {
        HapticFeedback.heavyImpact();
        setState(() => _lastError = validationError);
        Get.snackbar(
          'خطأ في التحقق',
          validationError,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    // Duplicate check (local)
    if (_confirmedSerials.any((s) => s.serialNumber == sn)) {
      HapticFeedback.heavyImpact();
      setState(() => _lastError = 'هذا الرقم تم مسحه بالفعل: $sn');
      Get.snackbar(
        'تكرار',
        'هذا الرقم التسلسلي مضاف بالفعل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Quantity cap
    if (_confirmedSerials.length >= widget.transfer.quantity) {
      Get.snackbar(
        'اكتملت الكمية',
        'تم استلام جميع الوحدات المطلوبة (${widget.transfer.quantity})',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accentOrange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _lastError = null;
    });

    try {
      // API call — real-time single serial registration
      await _controller.scanSingleSerial(widget.transfer.id, sn);

      setState(() {
        _confirmedSerials.add(_ScannedSerial(
          serialNumber: sn,
          confirmedAt: DateTime.now(),
          isSuccess: true,
        ));
        _isScanning = false;
      });

      HapticFeedback.lightImpact();
      _manualController.clear();
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception:', '').trim();
      setState(() {
        _isScanning = false;
        _lastError = errMsg;
        // Show failed scan in list for visibility
        _confirmedSerials.add(_ScannedSerial(
          serialNumber: sn,
          confirmedAt: DateTime.now(),
          isSuccess: false,
          errorMessage: errMsg,
        ));
      });
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _openCameraScanner() async {
    final selectedType = _controller.itemTypesMap[widget.transfer.itemType];
    final result = await Get.to(() => BarcodeScannerWidget(
          title: 'مسح الأرقام التسلسلية',
          isMultiScan: true,
          itemTypes: selectedType != null ? [selectedType] : null,
          selectedItemTypeId: selectedType?.id,
        ));

    if (result != null) {
      List<String> codes = [];
      if (result is List<String>) {
        codes = result;
      } else if (result is Map && result.containsKey('codes')) {
        codes = List<String>.from(result['codes'] as List);
      }
      for (final code in codes) {
        if (_confirmedSerials.length >= widget.transfer.quantity) break;
        await _scanSerial(code);
      }
    }
  }

  Future<void> _submitFinalConfirmation() async {
    setState(() => _submitting = true);
    try {
      await _controller.confirmTransferReceipt(widget.transfer.id, []);
      Get.back(result: true);
      Get.snackbar(
        '✓ تم الاستلام',
        'تم تأكيد استلام العهدة وتحديث مخزونك بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      // Error handled by controller snackbar
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemTypeName = _controller.itemTypesMap[widget.transfer.itemType]?.nameAr
        ?? widget.transfer.itemType;

    final successCount = _confirmedSerials.where((s) => s.isSuccess).length;
    final progress = isSerialized ? successCount / widget.transfer.quantity : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(
          'استلام العهدة',
          style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ─── Progress Bar ───
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
              minHeight: 3,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Header Summary Card ───
                    GlassCard(
                      borderColor: AppColors.primary.withOpacity(0.2),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.inventory_2_outlined,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemTypeName,
                                      style: TextStyle(fontFamily: 'BeIN', 
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      widget.transfer.warehouseName ?? 'المستودع الرئيسي',
                                      style: TextStyle(fontFamily: 'BeIN', 
                                          fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSerialized)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$successCount / ${widget.transfer.quantity}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isComplete
                                            ? AppColors.success
                                            : AppColors.accentOrange,
                                      ),
                                    ),
                                    Text(
                                      'تم الاستلام',
                                      style: TextStyle(fontFamily: 'BeIN', 
                                          fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          if (isSerialized && !isComplete) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accentOrange.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: AppColors.accentOrange, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'يتبقى ${widget.transfer.quantity - successCount} وحدة للمسح',
                                    style: TextStyle(fontFamily: 'BeIN', 
                                      fontSize: 13,
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── For Serialized Items: Scan Area ───
                    if (isSerialized) ...[
                      // Camera Scan Button
                      NeonButton(
                        label: _isScanning ? 'جارٍ التسجيل...' : 'مسح بالكاميرا',
                        icon: Icons.qr_code_scanner,
                        gradient: AppColors.gradientPrimary,
                        isLoading: _isScanning,
                        onPressed: (isComplete || _isScanning) ? null : _openCameraScanner,
                      ),
                      const SizedBox(height: 16),

                      // Manual Entry
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualController,
                              focusNode: _manualFocus,
                              enabled: !isComplete && !_isScanning,
                              style: GoogleFonts.robotoMono(
                                  color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'أدخل الرقم يدوياً...',
                                hintStyle: TextStyle(fontFamily: 'BeIN', 
                                    color: Colors.white30, fontSize: 13),
                                fillColor: AppColors.surfaceDark,
                                filled: true,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColors.border.withOpacity(0.2)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              onSubmitted: _scanSerial,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: (isComplete || _isScanning)
                                ? null
                                : () => _scanSerial(_manualController.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: Colors.white10,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'إضافة',
                              style: TextStyle(fontFamily: 'BeIN', 
                                  fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Error message
                      if (_lastError != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lastError!,
                                  style: TextStyle(fontFamily: 'BeIN', 
                                      color: AppColors.error, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ─── Scanned Serials List ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الأرقام المستلمة (${_confirmedSerials.length})',
                            style: TextStyle(fontFamily: 'BeIN', 
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (_confirmedSerials.isNotEmpty)
                            Text(
                              isComplete ? '✓ اكتملت الكمية' : '',
                              style: TextStyle(fontFamily: 'BeIN', 
                                  color: AppColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_confirmedSerials.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                'ابدأ المسح لتظهر الأرقام هنا',
                                style: TextStyle(fontFamily: 'BeIN', 
                                    color: Colors.white24, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _confirmedSerials.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            // Show newest first
                            final serial =
                                _confirmedSerials[_confirmedSerials.length - 1 - index];
                            return _buildSerialRow(
                                _confirmedSerials.length - index, serial);
                          },
                        ),
                    ] else ...[
                      // ─── Non-Serialized Items ───
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: AppColors.success, size: 52),
                            const SizedBox(height: 16),
                            Text(
                              'صنف غير مسلسّل',
                              style: TextStyle(fontFamily: 'BeIN', 
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'هذا الصنف (${itemTypeName}) لا يحتاج أرقاماً تسلسلية.\nيمكنك تأكيد الاستلام مباشرة.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'BeIN', 
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.transfer.quantity} ${widget.transfer.packagingType == "boxes" ? "كرتون" : "وحدة"}',
                                style: TextStyle(fontFamily: 'BeIN', 
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ─── Bottom Confirmation Button ───
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: NeonButton(
                label: 'تأكيد الاستلام النهائي',
                icon: Icons.check_circle_outline,
                gradient: isComplete
                    ? AppColors.gradientSuccess
                    : const [Color(0xFF374151), Color(0xFF4B5563)],
                isLoading: _submitting,
                onPressed: (isComplete && !_submitting) ? _submitFinalConfirmation : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerialRow(int number, _ScannedSerial serial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: serial.isSuccess
            ? AppColors.success.withOpacity(0.05)
            : AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: serial.isSuccess
              ? AppColors.success.withOpacity(0.15)
              : AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: serial.isSuccess
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.error.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              serial.isSuccess ? Icons.check : Icons.close,
              color:
                  serial.isSuccess ? AppColors.success : AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serial.serialNumber,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!serial.isSuccess && serial.errorMessage != null)
                  Text(
                    serial.errorMessage!,
                    style: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.error, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            serial.isSuccess ? '✓ مسجل' : 'فشل',
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 11,
              color: serial.isSuccess
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedSerial {
  final String serialNumber;
  final DateTime confirmedAt;
  final bool isSuccess;
  final String? errorMessage;

  const _ScannedSerial({
    required this.serialNumber,
    required this.confirmedAt,
    required this.isSuccess,
    this.errorMessage,
  });
}
