import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../controllers/notifications_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';

import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';
import '../../../dashboard/presentation/widgets/shimmer_loading.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'الإشعارات',
          style: TextStyle(fontFamily: 'BeIN', 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.transfers.isEmpty) {
          return const DashboardShimmer();
        }

        if (controller.error != null && controller.transfers.isEmpty) {
          return _buildErrorView();
        }

        if (controller.transfers.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // شريط تحديد الكل + قبول/رفض المحدد
            Obx(() {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceDark,
                child: Row(
                  children: [
                    Checkbox(
                      value: controller.isAllSelected
                          ? true
                          : (controller.hasSelection ? null : false),
                      tristate: true,
                      activeColor: AppColors.primary,
                      onChanged: (_) {
                        if (controller.isAllSelected) {
                          controller.clearSelection();
                        } else {
                          controller.selectAll();
                        }
                      },
                    ),
                    Text(
                      'تحديد الكل',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (controller.hasSelection) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading
                              ? null
                              : () => _acceptSelected(controller),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            'قبول (${controller.selectedIds.length})',
                            style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading
                              ? null
                              : () => _showRejectMultipleDialog(controller),
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(
                            'رفض (${controller.selectedIds.length})',
                            style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.refresh(),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.transfers.length,
                  itemBuilder: (context, index) {
                    final transfer = controller.transfers[index];
                    final itemType = controller.itemTypesMap[transfer.itemType];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TransferCard(
                          transfer: transfer,
                          itemType: itemType,
                          isSelected: controller.isSelected(transfer.id),
                          onToggleSelection: () => controller.toggleSelection(transfer.id),
                          onAccept: () {
                            final isSerialized = itemType != null
                                ? (itemType.category == 'devices' || itemType.category == 'sim' || itemType.requiresSerial == true)
                                : (transfer.itemType.toLowerCase().contains('pos') ||
                                   transfer.itemType.toLowerCase().contains('sim') ||
                                   transfer.itemType.toLowerCase().contains('n950') ||
                                   transfer.itemType.toLowerCase().contains('i9000') ||
                                   transfer.itemType.toLowerCase().contains('i9100'));
                            if (isSerialized) {
                              final actualItemType = itemType ?? ItemType(
                                id: transfer.itemType,
                                nameAr: transfer.itemType,
                                nameEn: transfer.itemType,
                                category: transfer.itemType.toLowerCase().contains('sim') ? 'sim' : 'devices',
                                sortOrder: 0,
                                isActive: true,
                                isVisible: true,
                              );
                              _showSerializedScanSheet(context, transfer, actualItemType);
                            } else {
                              controller.acceptTransfer(transfer.id);
                            }
                          },
                          onReject: () => _showRejectDialog(transfer.id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _acceptSelected(NotificationsController ctrl) {
    if (ctrl.selectedIds.isEmpty) return;
    
    // Check if any selected transfer is serialized (devices or sim)
    final hasSerialized = ctrl.transfers.any((t) {
      if (ctrl.isSelected(t.id)) {
        final itemType = ctrl.itemTypesMap[t.itemType];
        final id = t.itemType.toLowerCase();
        final isSer = itemType != null
            ? (itemType.category == 'devices' || itemType.category == 'sim' || itemType.requiresSerial == true)
            : (id.contains('pos') || id.contains('sim') || id.contains('n950') || id.contains('i9000') || id.contains('i9100'));
        return isSer;
      }
      return false;
    });

    if (hasSerialized) {
      Get.snackbar(
        'تنبيه لمسح الأرقام',
        'يرجى قبول طلبات الأجهزة والشرائح بشكل منفرد لمسح الأرقام التسلسلية',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }
    
    ctrl.acceptMultipleTransfers(ctrl.selectedIds);
  }

  void _showRejectMultipleDialog(NotificationsController ctrl) {
    if (ctrl.selectedIds.isEmpty) return;
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'رفض الطلبات المحددة (${ctrl.selectedIds.length})',
          style: TextStyle(fontFamily: 'BeIN', 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: reasonController,
          style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
          decoration: InputDecoration(
            labelText: 'سبب الرفض (اختياري)',
            labelStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.rejectMultipleTransfers(
                ctrl.selectedIds,
                reason: reasonController.text.isEmpty ? null : reasonController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'رفض المحدد',
              style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String transferId) {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'رفض طلب النقل',
          style: TextStyle(fontFamily: 'BeIN', 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: reasonController,
          style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
          decoration: InputDecoration(
            labelText: 'سبب الرفض (اختياري)',
            labelStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectTransfer(transferId, reason: reasonController.text.isEmpty ? null : reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'رفض',
              style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.error ?? 'حدث خطأ في تحميل البيانات',
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لا توجد طلبات نقل معلقة حالياً',
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSerializedScanSheet(BuildContext context, WarehouseTransfer transfer, ItemType itemType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SerializedScanBottomSheet(
        transfer: transfer,
        itemType: itemType,
        controller: controller,
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final WarehouseTransfer transfer;
  final ItemType? itemType;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _TransferCard({
    required this.transfer,
    this.itemType,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceDark,
            AppColors.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.warning.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: checkbox + icon + title
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (_) => onToggleSelection(),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.orangeGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warehouse,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer.warehouseName ?? 'مستودع غير محدد',
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm', 'ar').format(transfer.createdAt),
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.orangeGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'معلق',
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Item Details
            if (itemType != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        itemType!.nameAr,
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${transfer.quantity} ${transfer.packagingType == "boxes" ? "كراتين" : "وحدات"}',
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'ملاحظات: ${transfer.notes}',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 20),
                    label: Text(
                      'قبول',
                      style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 20),
                    label: Text(
                      'رفض',
                      style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SerializedScanBottomSheet extends StatefulWidget {
  final WarehouseTransfer transfer;
  final ItemType itemType;
  final NotificationsController controller;

  const _SerializedScanBottomSheet({
    required this.transfer,
    required this.itemType,
    required this.controller,
  });

  @override
  State<_SerializedScanBottomSheet> createState() => _SerializedScanBottomSheetState();
}

class _SerializedScanBottomSheetState extends State<_SerializedScanBottomSheet> {
  final List<String> _scannedSerials = [];
  final _serialController = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scannedSerials.addAll(widget.controller.getScannedSerials(widget.transfer.id));
  }

  @override
  void dispose() {
    _serialController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addSerial() {
    var serial = _serialController.text.trim();
    if (serial.startsWith(']C1')) {
      serial = serial.substring(3);
    } else if (serial.toLowerCase().startsWith('c1')) {
      serial = serial.substring(2);
    }

    if (serial.isEmpty) {
      setState(() {
        _error = 'الرجاء إدخال أو مسح رقم تسلسلي';
      });
      return;
    }

    if (_scannedSerials.contains(serial)) {
      HapticFeedback.vibrate();
      setState(() {
        _error = 'هذا الرقم التسلسلي مضاف بالفعل';
      });
      return;
    }

    // Validation rules from database (ItemType)
    final itemType = widget.itemType;
    
    // 1. Prefix Validation
    if (itemType.serialPrefix != null && itemType.serialPrefix!.isNotEmpty) {
      final prefixes = itemType.serialPrefix!.split(',').map((p) => p.trim()).toList();
      final hasValidPrefix = prefixes.any((prefix) => serial.startsWith(prefix));
      if (!hasValidPrefix) {
        HapticFeedback.vibrate();
        setState(() {
          _error = '❌ الرقم التسلسلي غير صحيح. يجب أن يبدأ بـ: ${prefixes.join(' أو ')}';
        });
        return;
      }
    }

    // 2. Length Validation
    if (itemType.serialLength != null && itemType.serialLength! > 0) {
      if (serial.length != itemType.serialLength) {
        int digitsAfterPrefix = itemType.serialLength!;
        if (itemType.serialPrefix != null) {
          final prefixes = itemType.serialPrefix!.split(',').map((p) => p.trim()).toList();
          final matchedPrefix = prefixes.firstWhere((p) => serial.startsWith(p), orElse: () => '');
          if (matchedPrefix.isNotEmpty) {
            digitsAfterPrefix = itemType.serialLength! - matchedPrefix.length;
          }
        }
        HapticFeedback.vibrate();
        setState(() {
          _error = '❌ طول الرقم التسلسلي غير صحيح. المطلوب: $digitsAfterPrefix أرقام بعد البادئة.';
        });
        return;
      }
    }

    // 3. Regex Pattern Validation
    if (itemType.serialRegex != null && itemType.serialRegex!.isNotEmpty) {
      final regex = RegExp(itemType.serialRegex!);
      if (!regex.hasMatch(serial)) {
        HapticFeedback.vibrate();
        setState(() {
          _error = '❌ الرقم التسلسلي غير صحيح. الرقم لا يطابق الصيغة المعتمدة لـ ${itemType.nameAr}.';
        });
        return;
      }
    }

    if (widget.controller.isSerialScannedAnywhere(serial)) {
      HapticFeedback.vibrate();
      setState(() {
        _error = 'هذا الرقم التسلسلي تم مسحه بالفعل في طلب آخر';
      });
      return;
    }

    if (_scannedSerials.length >= widget.transfer.quantity) {
      HapticFeedback.vibrate();
      setState(() {
        _error = 'تم مسح الكمية المطلوبة بالكامل بالفعل';
      });
      return;
    }

    setState(() {
      _scannedSerials.add(serial);
      widget.controller.addScannedSerial(widget.transfer.id, serial);
      _serialController.clear();
      _error = null;
    });
    HapticFeedback.lightImpact();
    _focusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (_scannedSerials.length != widget.transfer.quantity) {
      setState(() {
        _error = 'الرجاء مسح كافة الأرقام التسلسلية (${widget.transfer.quantity}) المطلوبة';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final success = await widget.controller.acceptSerializedTransfer(
      transferId: widget.transfer.id,
      serials: _scannedSerials,
      itemType: widget.itemType,
    );

    if (success) {
      widget.controller.clearScannedSerials(widget.transfer.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remains = widget.transfer.quantity - _scannedSerials.length;
    final isDone = remains == 0;
    final isSim = widget.itemType.category == 'sim';

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مسح الأرقام التسلسلية المستلمة',
                          style: TextStyle(fontFamily: 'BeIN', 
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الصنف: ${widget.itemType.nameAr} | الكمية المطلوبة: ${widget.transfer.quantity}',
                          style: TextStyle(fontFamily: 'BeIN', 
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),

              // Progress bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : Icons.qr_code_scanner,
                      color: isDone ? AppColors.success : AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'حالة المسح',
                                style: TextStyle(fontFamily: 'BeIN', 
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_scannedSerials.length} / ${widget.transfer.quantity}',
                                style: GoogleFonts.robotoMono(
                                  color: isDone ? AppColors.success : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: widget.transfer.quantity > 0
                                  ? (_scannedSerials.length / widget.transfer.quantity)
                                  : 0,
                              backgroundColor: Colors.white10,
                              color: isDone ? AppColors.success : AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Manual input field
              TextFormField(
                controller: _serialController,
                focusNode: _focusNode,
                style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
                onFieldSubmitted: (_) => _addSerial(),
                decoration: InputDecoration(
                  hintText: isSim ? 'أدخل ICCID للشريحة' : 'أدخل الرقم التسلسلي للجهاز',
                  hintStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  prefixIcon: Icon(
                    isSim ? Icons.sim_card : Icons.phone_android,
                    color: AppColors.primary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BarcodeScannerWidget(
                                title: 'مسح باركود الأجهزة والشرائح',
                                isMultiScan: true,
                                itemTypes: [widget.itemType],
                                selectedItemTypeId: widget.itemType.id,
                              ),
                            ),
                          );
                          if (result != null) {
                            List<String> codes = [];
                            if (result is Map<String, dynamic>) {
                              codes = List<String>.from(result['codes'] ?? []);
                            } else if (result is List<String>) {
                              codes = result;
                            } else if (result is String && result.trim().isNotEmpty) {
                              codes = [result.trim()];
                            }
                            
                            if (codes.isNotEmpty) {
                              setState(() {
                                for (var code in codes) {
                                  var serial = code.trim();
                                  if (serial.startsWith(']C1')) {
                                    serial = serial.substring(3);
                                  } else if (serial.toLowerCase().startsWith('c1')) {
                                    serial = serial.substring(2);
                                  }
                                  if (serial.isNotEmpty && !_scannedSerials.contains(serial)) {
                                    // Validation rules from database (ItemType)
                                    final itemType = widget.itemType;
                                    bool isValid = true;

                                    // 1. Prefix Validation
                                    if (itemType.serialPrefix != null && itemType.serialPrefix!.isNotEmpty) {
                                      final prefixes = itemType.serialPrefix!.split(',').map((p) => p.trim()).toList();
                                      isValid = prefixes.any((prefix) => serial.startsWith(prefix));
                                    }

                                    // 2. Length Validation
                                    if (isValid && itemType.serialLength != null && itemType.serialLength! > 0) {
                                      isValid = serial.length == itemType.serialLength;
                                    }

                                    // 3. Regex Pattern Validation
                                    if (isValid && itemType.serialRegex != null && itemType.serialRegex!.isNotEmpty) {
                                      final regex = RegExp(itemType.serialRegex!);
                                      isValid = regex.hasMatch(serial);
                                    }

                                    if (!isValid) {
                                      _error = 'تم تخطي بعض الأرقام غير المطابقة للمواصفات';
                                    } else if (widget.controller.isSerialScannedAnywhere(serial)) {
                                      _error = 'تم تخطي بعض الأرقام التسلسلية المكررة في طلبات أخرى';
                                    } else if (_scannedSerials.length < widget.transfer.quantity) {
                                      _scannedSerials.add(serial);
                                      widget.controller.addScannedSerial(widget.transfer.id, serial);
                                    }
                                  }
                                }
                                _error = null;
                              });
                            }
                          }
                        },
                        tooltip: 'مسح بالكاميرا',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: _addSerial,
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(fontFamily: 'BeIN', color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),

              // Scanned list header
              if (_scannedSerials.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الأرقام الممسوحة مؤخراً:',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _scannedSerials.clear();
                          widget.controller.clearScannedSerials(widget.transfer.id);
                          _error = null;
                        });
                      },
                      child: Text(
                        'حذف الكل',
                        style: TextStyle(fontFamily: 'BeIN', color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _scannedSerials.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final item = _scannedSerials[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSim ? Icons.sim_card : Icons.phone_android,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: GoogleFonts.robotoMono(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                              onPressed: () {
                                setState(() {
                                  widget.controller.removeScannedSerial(widget.transfer.id, item);
                                  _scannedSerials.removeAt(index);
                                  _error = null;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving || !isDone ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 20),
                      label: Text(
                        _isSaving ? 'جاري الحفظ...' : 'حفظ وتأكيد الاستلام',
                        style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
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
}
