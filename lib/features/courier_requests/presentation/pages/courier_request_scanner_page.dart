import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../../shared/scanner/scanner_item_types.dart';
import '../controllers/courier_requests_controller.dart';
import '../../data/models/courier_request_model.dart';
import '../../../../core/routing/app_pages.dart';

class CourierRequestScannerPage extends StatefulWidget {
  const CourierRequestScannerPage({super.key});

  @override
  State<CourierRequestScannerPage> createState() =>
      _CourierRequestScannerPageState();
}

class _CourierRequestScannerPageState
    extends State<CourierRequestScannerPage>
    with SingleTickerProviderStateMixin {
  final CourierRequestsController controller =
      Get.find<CourierRequestsController>();
  late int requestId;
  final TextEditingController _serialInputController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    requestId = Get.arguments as int;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadRequestDetails(requestId);
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _serialInputController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startCameraScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWidget(
          title: 'مسح باركود الأجهزة والشرائح',
          isMultiScan: true,
          itemTypes: ScannerItemTypes.serialTracked(),
          categoryHint: null,
          allowUnionOfItemTypes: true,
        ),
      ),
    );
    if (result != null) {
      List<String> codes = [];
      if (result is List<String>) {
        codes = result;
      } else if (result is Map) {
        codes = List<String>.from(result['codes'] ?? const []);
        if (codes.isEmpty && result['code'] is String) {
          codes = [result['code'] as String];
        }
      } else if (result is String && result.trim().isNotEmpty) {
        codes = [result.trim()];
      }

      if (codes.isNotEmpty) {
        int matchedCount = 0;
        int failedCount = 0;
        String? lastError;

        for (var code in codes) {
          final error = controller.scanItemLocal(code.trim());
          if (error != null) {
            failedCount++;
            lastError = error;
          } else {
            matchedCount++;
          }
        }

        if (matchedCount > 0) {
          Get.snackbar(
            '✅ تم مطابقة الشحنة',
            'تم تسجيل $matchedCount من العناصر بنجاح في الجلسة${failedCount > 0 ? " ($failedCount لم يتم مطابقتها)" : ""}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 4),
          );
        }
        if (failedCount > 0 && lastError != null) {
          Get.snackbar(
            '⚠️ تنبيه في المسح المتعدد',
            'فشل مسح $failedCount من العناصر. السبب الأخير: $lastError',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  void _processScannedCode(String code) {
    final error = controller.scanItemLocal(code);
    if (error != null) {
      Get.snackbar(
        '⚠️ خطأ في المسح',
        error,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        '✅ تم المطابقة',
        'السيريال ($code) مسجل بنجاح في الجلسة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _processScannedCodeForItem(CourierRequestItem item, String code) {
    final error = controller.scanSpecificItemLocal(item.id, code);
    if (error != null) {
      Get.snackbar(
        '⚠️ خطأ في المسح',
        error,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        '✅ تم المطابقة',
        'السيريال ($code) مسجل بنجاح في الجلسة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _markItemProblem(CourierRequestItem item) {
    final reasonController = TextEditingController(
        text: controller.localProblemReasons[item.id] ?? '');
    String selectedStatus =
        controller.localItemStatuses[item.id] ?? 'MISSING';
    if (selectedStatus == 'RECEIVED' || selectedStatus == 'PENDING_RECEIPT') {
      selectedStatus = 'MISSING';
    }

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
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
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.report_problem,
                              color: AppColors.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الإبلاغ عن مشكلة',
                          style: TextStyle(fontFamily: 'BeIN', 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('حالة المشكلة:',
                        style: TextStyle(fontFamily: 'BeIN', 
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundMid,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceMid,
                          value: selectedStatus,
                          style: TextStyle(fontFamily: 'BeIN', 
                              color: Colors.white, fontSize: 14),
                          items: const [
                            DropdownMenuItem(
                              value: 'MISSING',
                              child: Text('مفقود (Missing)'),
                            ),
                            DropdownMenuItem(
                              value: 'DAMAGED',
                              child: Text('تالف / متضرر (Damaged)'),
                            ),
                            DropdownMenuItem(
                              value: 'WRONG_ITEM',
                              child: Text('جهاز خاطئ (Wrong Item)'),
                            ),
                            DropdownMenuItem(
                              value: 'REJECTED',
                              child: Text('مرفوض (Rejected)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedStatus = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('تفاصيل المشكلة:',
                        style: TextStyle(fontFamily: 'BeIN', 
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'اكتب تفاصيل المشكلة...',
                        hintStyle: TextStyle(fontFamily: 'BeIN', 
                            color: AppColors.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.backgroundMid,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(
                                  color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('إلغاء',
                                style: TextStyle(fontFamily: 'BeIN', 
                                    color: AppColors.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeonButton.error(
                            label: 'حفظ المشكلة',
                            icon: Icons.save,
                            height: 44,
                            fontSize: 13,
                            onPressed: () {
                              if (reasonController.text.trim().isEmpty) {
                                Get.snackbar('تنبيه',
                                    'يجب إدخال سبب المشكلة للتوثيق',
                                    backgroundColor: AppColors.error,
                                    colorText: Colors.white);
                                return;
                              }
                              controller.reportProblemLocal(
                                  item.id,
                                  selectedStatus,
                                  reasonController.text.trim());
                              Get.back();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
        final items = controller.currentItems;

        if (controller.isLoading && items.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final posItems =
            items.where((i) => i.itemType == 'POS').toList();
        final simItems =
            items.where((i) => i.itemType == 'SIM').toList();
        final otherItems = items
            .where((i) => i.itemType != 'POS' && i.itemType != 'SIM')
            .toList();

        final posScanned = posItems
            .where((i) => controller.localItemStatuses[i.id] == 'RECEIVED')
            .length;
        final simScanned = simItems
            .where((i) => controller.localItemStatuses[i.id] == 'RECEIVED')
            .length;
        final posProblems = posItems
            .where((i) =>
                controller.localItemStatuses[i.id] != null &&
                controller.localItemStatuses[i.id] != 'RECEIVED' &&
                controller.localItemStatuses[i.id] != 'PENDING_RECEIPT')
            .length;
        final simProblems = simItems
            .where((i) =>
                controller.localItemStatuses[i.id] != null &&
                controller.localItemStatuses[i.id] != 'RECEIVED' &&
                controller.localItemStatuses[i.id] != 'PENDING_RECEIPT')
            .length;

        return CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.surfaceDark,
              foregroundColor: Colors.white,
              title: RasscoBrandTitle(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'محرك المسح الذكي',
                      style: TextStyle(fontFamily: 'BeIN', 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'طلب #$requestId — تحقق من هوية كل جهاز',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scanner HUD
            SliverToBoxAdapter(
              child: _buildScannerHUD(
                posScanned, posItems.length, posProblems,
                simScanned, simItems.length, simProblems,
              ),
            ),

            // Items
            SliverPadding(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (posItems.isNotEmpty) ...[
                    SectionHeader(
                      title:
                          'أجهزة نقاط البيع POS (${posItems.length})',
                      icon: Icons.tablet_android,
                      color: AppColors.accentPurple,
                    ),
                    ...posItems.map((i) => _buildSerialItemCard(i)),
                    const SizedBox(height: 16),
                  ],
                  if (simItems.isNotEmpty) ...[
                    SectionHeader(
                      title: 'شرائح SIM (${simItems.length})',
                      icon: Icons.sim_card,
                      color: AppColors.primary,
                    ),
                    ...simItems.map((i) => _buildSerialItemCard(i)),
                    const SizedBox(height: 16),
                  ],
                  if (otherItems.isNotEmpty) ...[
                    SectionHeader(
                      title: 'الملحقات والمستندات',
                      icon: Icons.inventory_2,
                      color: AppColors.warning,
                    ),
                    ...otherItems.map((i) => _buildAccessoryCard(i)),
                  ],
                ]),
              ),
            ),
          ],
        );
      }),

      // Bottom bar
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildScannerHUD(
    int posScanned, int posTotal, int posProblems,
    int simScanned, int simTotal, int simProblems,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _serialInputController,
                  style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
                  textDirection: TextDirection.ltr,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (val) {
                    final upper = val.toUpperCase();
                    if (val != upper) {
                      _serialInputController.value = TextEditingValue(
                        text: upper,
                        selection: _serialInputController.selection,
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'أدخل السيريال يدوياً أو امسح',
                    hintStyle: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.textMuted, fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.qr_code, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.backgroundMid,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _processScannedCode(val.trim().toUpperCase());
                      _serialInputController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Camera button
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _startCameraScan,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 26),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bars
          if (posTotal > 0) ...[
            GlowingProgressBar(
              value: posTotal == 0 ? 0 : posScanned / posTotal,
              color: AppColors.accentPurple,
              label: 'POS $posScanned/$posTotal',
              trailingText: posProblems > 0
                  ? '⚠️ $posProblems مشكلة'
                  : posScanned == posTotal
                      ? '✅ مكتمل'
                      : null,
            ),
            const SizedBox(height: 8),
          ],
          if (simTotal > 0)
            GlowingProgressBar(
              value: simTotal == 0 ? 0 : simScanned / simTotal,
              color: AppColors.primary,
              label: 'SIM $simScanned/$simTotal',
              trailingText: simProblems > 0
                  ? '⚠️ $simProblems مشكلة'
                  : simScanned == simTotal
                      ? '✅ مكتمل'
                      : null,
            ),
        ],
      ),
    );
  }

  Widget _buildSerialItemCard(CourierRequestItem item) {
    final itemStatus = controller.localItemStatuses[item.id];
    final isScanned = itemStatus == 'RECEIVED';
    final hasProblem = itemStatus != null &&
        itemStatus != 'RECEIVED' &&
        itemStatus != 'PENDING_RECEIPT';
    final problemReason = controller.localProblemReasons[item.id];
    final scannedSerial = controller.localScannedSerials[item.id];

    Color borderColor = AppColors.border;
    Color accentColor = AppColors.textMuted;
    if (isScanned) {
      borderColor = AppColors.success;
      accentColor = AppColors.success;
    } else if (hasProblem) {
      borderColor = AppColors.error;
      accentColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
        boxShadow: isScanned
            ? [
                BoxShadow(
                    color: AppColors.success.withOpacity(0.1),
                    blurRadius: 8)
              ]
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.itemType == 'POS'
                        ? Icons.tablet_android
                        : Icons.sim_card,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScanned && scannedSerial != null
                            ? scannedSerial
                            : (item.itemType == 'POS'
                                ? (item.serialNumber ?? 'جهاز POS')
                                : (item.simSerial ?? 'شريحة SIM')),
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isScanned
                            ? '✓ تم التحقق والاستلام'
                            : hasProblem
                                ? _problemText(itemStatus)
                                : 'بانتظار المسح الضوئي',
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 11,
                          color: accentColor,
                          fontWeight: isScanned || hasProblem
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                if (isScanned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                  )
                else if (hasProblem)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber,
                        color: AppColors.error, size: 18),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code,
                        color: AppColors.textMuted, size: 18),
                  ),
              ],
            ),
          ),

          // Problem reason
          if (hasProblem && problemReason != null)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'المشكلة: $problemReason',
                      style: TextStyle(fontFamily: 'BeIN', 
                          color: AppColors.error.withOpacity(0.9),
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isScanned || hasProblem)
                  TextButton.icon(
                    onPressed: () {
                      controller.clearItemLocal(item.id);
                    },
                    icon: const Icon(Icons.refresh,
                        size: 15, color: AppColors.textSecondary),
                    label: Text(
                      'تراجع وإعادة مسح',
                      style: TextStyle(fontFamily: 'BeIN', 
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  )
                else ...[
                  TextButton.icon(
                    onPressed: () => _markItemProblem(item),
                    icon: const Icon(Icons.report_problem_outlined,
                        size: 15, color: AppColors.warning),
                    label: Text(
                      'إبلاغ عن مشكلة',
                      style: TextStyle(fontFamily: 'BeIN', 
                          color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final types = item.itemType == 'SIM'
                          ? ScannerItemTypes.forRole('sim')
                          : ScannerItemTypes.forRole('device');
                      final scannedRaw = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BarcodeScannerWidget(
                            title: 'مسح باركود العنصر',
                            itemTypes: types,
                            categoryHint:
                                item.itemType == 'SIM' ? 'sim' : 'devices',
                            allowUnionOfItemTypes: true,
                          ),
                        ),
                      );
                      final scannedCode = scannedRaw is String
                          ? scannedRaw.trim()
                          : (scannedRaw is Map
                              ? (scannedRaw['code'] as String?)?.trim()
                              : null);
                      if (scannedCode != null && scannedCode.isNotEmpty) {
                        _processScannedCodeForItem(item, scannedCode);
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner,
                        size: 15, color: AppColors.primary),
                    label: Text(
                      'مسح الباركود',
                      style: TextStyle(fontFamily: 'BeIN', 
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _problemText(String status) {
    switch (status) {
      case 'MISSING':
        return '⚠ مفقود — تم تسجيل البلاغ';
      case 'DAMAGED':
        return '⚠ تالف — تم تسجيل البلاغ';
      case 'WRONG_ITEM':
        return '⚠ جهاز خاطئ — تم تسجيل البلاغ';
      case 'REJECTED':
        return '⚠ مرفوض — تم تسجيل البلاغ';
      default:
        return '⚠ مشكلة — تم تسجيل البلاغ';
    }
  }

  Widget _buildAccessoryCard(CourierRequestItem item) {
    final isChecked = controller.checkedAccessories.contains(item.id);
    final icon = item.itemType == 'DOCUMENT' ? Icons.description : Icons.cable;
    final title = item.itemType == 'DOCUMENT'
        ? 'أوراق / عقود / ملصقات'
        : 'ملحق / شاحن / ورق حراري (كمية: ${item.quantity})';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isChecked
              ? AppColors.success.withOpacity(0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isChecked ? AppColors.success : AppColors.textMuted,
              size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontFamily: 'BeIN', 
                color: isChecked ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    isChecked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.toggleAccessoryLocal(item.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isChecked
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isChecked
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                isChecked ? '✓ مستلم' : 'تأكيد',
                style: TextStyle(fontFamily: 'BeIN', 
                  color: isChecked ? AppColors.success : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
        child: NeonButton.success(
          label: 'مراجعة وتأكيد الاستلام',
          icon: Icons.rate_review_outlined,
          onPressed: () {
            Get.toNamed(Routes.courierRequestReview);
          },
          height: 52,
        ),
      ),
    );
  }
}
