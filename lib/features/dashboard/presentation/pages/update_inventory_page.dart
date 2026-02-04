import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../stock_transfer/presentation/controllers/stock_transfer_controller.dart';
import '../../../stock_transfer/presentation/bindings/stock_transfer_binding.dart';

class UpdateInventoryPage extends StatefulWidget {
  final List<InventoryEntry> currentInventory;
  final List<ItemType> itemTypes;
  final String inventoryType; // 'fixed' or 'moving'
  final Function(List<InventoryEntry>) onSave;

  const UpdateInventoryPage({
    super.key,
    required this.currentInventory,
    required this.itemTypes,
    required this.inventoryType,
    required this.onSave,
  });

  @override
  State<UpdateInventoryPage> createState() => _UpdateInventoryPageState();
}

class _UpdateInventoryPageState extends State<UpdateInventoryPage> {
  final Map<String, TextEditingController> _boxesControllers = {};
  final Map<String, TextEditingController> _unitsControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    for (var entry in widget.currentInventory) {
      _boxesControllers[entry.itemTypeId] = TextEditingController(
        text: entry.boxes.toString(),
      );
      _unitsControllers[entry.itemTypeId] = TextEditingController(
        text: entry.units.toString(),
      );
    }
    // Initialize controllers for item types not in inventory
    for (var itemType in widget.itemTypes) {
      if (!_boxesControllers.containsKey(itemType.id)) {
        _boxesControllers[itemType.id] = TextEditingController(text: '0');
        _unitsControllers[itemType.id] = TextEditingController(text: '0');
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _boxesControllers.values) {
      controller.dispose();
    }
    for (var controller in _unitsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _parseInt(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final entries = <InventoryEntry>[];
      
      for (var itemType in widget.itemTypes) {
        final boxesController = _boxesControllers[itemType.id];
        final unitsController = _unitsControllers[itemType.id];
        
        if (boxesController != null && unitsController != null) {
          final boxes = _parseInt(boxesController);
          final units = _parseInt(unitsController);
          
          // Include all entries, even if zero (for complete inventory update)
          entries.add(InventoryEntry(
            itemTypeId: itemType.id,
            boxes: boxes,
            units: units,
          ));
        }
      }

      await widget.onSave(entries);
      
      if (mounted) {
        Get.back();
        Get.snackbar(
          'success'.tr,
          'update_success'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showTransferDialog() {
    // Ensure StockTransferController is available
    if (!Get.isRegistered<StockTransferController>()) {
      StockTransferBinding().dependencies();
    }
    
    Get.bottomSheet(
      _TransferBottomSheet(
        itemTypes: widget.itemTypes,
        inventoryType: widget.inventoryType,
        currentInventory: widget.currentInventory,
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          widget.inventoryType == 'fixed' 
              ? 'update_fixed_title'.tr
              : 'update_moving_title'.tr,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _showTransferDialog,
            tooltip: 'transfer_stock_tooltip'.tr,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.inventoryType == 'fixed'
                    ? [AppColors.primary, AppColors.primaryDark]
                    : AppColors.purpleGradient,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (widget.inventoryType == 'fixed'
                          ? AppColors.primary
                          : AppColors.purpleGradient.first)
                      .withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.inventoryType == 'fixed'
                      ? Icons.inventory_2
                      : Icons.local_shipping,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.inventoryType == 'fixed'
                            ? 'update_fixed_title'.tr
                            : 'update_moving_title'.tr,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.itemTypes.length} ${'types_available'.tr}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.itemTypes.length,
              itemBuilder: (context, index) {
                final itemType = widget.itemTypes[index];
                final boxesController = _boxesControllers[itemType.id];
                final unitsController = _unitsControllers[itemType.id];
                
                if (boxesController == null || unitsController == null) {
                  return const SizedBox();
                }

                return _buildItemRow(itemType, boxesController, unitsController);
              },
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'saving'.tr : 'save_changes'.tr,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    ItemType itemType,
    TextEditingController boxesController,
    TextEditingController unitsController,
  ) {
    final itemColor = itemType.colorHex != null
        ? Color(int.parse(itemType.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconMapper.getIcon(itemType.iconName),
                  color: itemColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemType.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (itemType.nameEn.isNotEmpty)
                      Text(
                        itemType.nameEn,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quantity Inputs
          Row(
            children: [
              Expanded(
                child: _buildQuantityField(
                  'كراتين',
                  boxesController,
                  Icons.inventory_2,
                  itemColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuantityField(
                  'units'.tr,
                  unitsController,
                  Icons.circle,
                  itemColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: AppColors.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color),
        ),
      ),
    );
  }
}

class _TransferBottomSheet extends StatefulWidget {
  final List<ItemType> itemTypes;
  final String inventoryType;
  final List<InventoryEntry> currentInventory;

  const _TransferBottomSheet({
    required this.itemTypes,
    required this.inventoryType,
    required this.currentInventory,
  });

  @override
  State<_TransferBottomSheet> createState() => _TransferBottomSheetState();
}

class _TransferBottomSheetState extends State<_TransferBottomSheet> {
  String? _selectedItemType;
  String _packagingType = 'unit'; // 'box' or 'unit'
  String _fromInventory = 'fixed'; // 'fixed' or 'moving'
  int _quantity = 1;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fromInventory = widget.inventoryType;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    if (_selectedItemType == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authController = Get.find<AuthController>();
      final technicianId = authController.user?.id;
      
      if (technicianId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      // Ensure StockTransferController is available
      if (!Get.isRegistered<StockTransferController>()) {
        StockTransferBinding().dependencies();
      }
      
      final stockTransferController = Get.find<StockTransferController>();
      
      final success = await stockTransferController.transferStock(
        technicianId: technicianId,
        itemType: _selectedItemType!,
        packagingType: _packagingType, // 'box' or 'unit'
        quantity: _quantity,
        fromInventory: _fromInventory,
        toInventory: _fromInventory == 'fixed' ? 'moving' : 'fixed',
        reason: _reasonController.text.trim().isEmpty 
            ? null 
            : _reasonController.text.trim(),
      );

      if (success && mounted) {
        Get.back();
        Get.snackbar(
          'نجح',
          'تم نقل المخزون بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else if (mounted) {
        Get.snackbar(
          'error'.tr,
          stockTransferController.error ?? 'transfer_fail'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'transfer_stock_tooltip'.tr,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // اختيار نوع الصنف
          DropdownButtonFormField<String>(
            value: _selectedItemType,
            decoration: InputDecoration(
              labelText: 'item_type_label'.tr,
              labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
            ),
            dropdownColor: AppColors.surfaceDark,
            style: GoogleFonts.cairo(color: Colors.white),
            items: widget.itemTypes.map((type) {
              final entry = widget.currentInventory
                  .firstWhere((e) => e.itemTypeId == type.id, orElse: () => InventoryEntry(
                      itemTypeId: type.id,
                      boxes: 0,
                      units: 0,
                    ));
              final available = entry.boxes + entry.units;
              
              return DropdownMenuItem(
                value: type.id,
                child: Row(
                  children: [
                    Expanded(child: Text(type.nameAr)),
                    Text(
                      '($available متاح)',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedItemType = v),
          ),
          const SizedBox(height: 16),
          
          // اتجاه النقل
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'fixed',
                label: Text(
                  'from_fixed_to_moving'.tr,
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
              ButtonSegment(
                value: 'moving',
                label: Text(
                  'from_moving_to_fixed'.tr,
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
            ],
            selected: {_fromInventory},
            onSelectionChanged: (s) => setState(() => _fromInventory = s.first),
          ),
          const SizedBox(height: 16),
          
          // نوع التعبئة
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'unit',
                label: Text('units'.tr, style: GoogleFonts.cairo(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'box',
                label: Text('boxes'.tr, style: GoogleFonts.cairo(fontSize: 12)),
              ),
            ],
            selected: {_packagingType},
            onSelectionChanged: (s) => setState(() => _packagingType = s.first),
          ),
          const SizedBox(height: 16),
          
          // الكمية
          Row(
            children: [
              Text(
                '${'quantity'.tr}:',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _quantity > 1 
                    ? () => setState(() => _quantity--) 
                    : null,
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  _quantity.toString(),
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // سبب النقل (اختياري)
          TextField(
            controller: _reasonController,
            style: GoogleFonts.cairo(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'سبب النقل (اختياري)',
              labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          
          // زر النقل
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedItemType == null || _isLoading ? null : _transfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'execute_transfer'.tr,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
