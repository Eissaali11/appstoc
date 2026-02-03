import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';

class InventorySummaryCard extends StatelessWidget {
  final List<InventoryEntry> fixedInventory;
  final List<InventoryEntry> movingInventory;
  final Map<String, ItemType> itemTypesMap;

  const InventorySummaryCard({
    super.key,
    required this.fixedInventory,
    required this.movingInventory,
    required this.itemTypesMap,
  });

  List<_InventoryItem> get _allItems {
    final Map<String, _InventoryItem> itemsMap = {};

    // إضافة المخزون الثابت
    for (var entry in fixedInventory) {
      final itemType = itemTypesMap[entry.itemTypeId];
      if (itemType != null) {
        itemsMap[entry.itemTypeId] = _InventoryItem(
          itemType: itemType,
          fixedBoxes: entry.boxes,
          fixedUnits: entry.units,
          movingBoxes: 0,
          movingUnits: 0,
        );
      }
    }

    // إضافة المخزون المتحرك
    for (var entry in movingInventory) {
      final itemType = itemTypesMap[entry.itemTypeId];
      if (itemType != null) {
        if (itemsMap.containsKey(entry.itemTypeId)) {
          itemsMap[entry.itemTypeId]!.movingBoxes = entry.boxes;
          itemsMap[entry.itemTypeId]!.movingUnits = entry.units;
        } else {
          itemsMap[entry.itemTypeId] = _InventoryItem(
            itemType: itemType,
            fixedBoxes: 0,
            fixedUnits: 0,
            movingBoxes: entry.boxes,
            movingUnits: entry.units,
          );
        }
      }
    }

    return itemsMap.values.toList()
      ..sort((a, b) => a.itemType.sortOrder.compareTo(b.itemType.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    final items = _allItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد عناصر في المخزون',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'ملخص المخزون',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Items List
          ...items.map((item) => _InventoryItemRow(item: item)),
        ],
      ),
    );
  }
}

class _InventoryItemRow extends StatelessWidget {
  final _InventoryItem item;

  const _InventoryItemRow({required this.item});

  Color _getItemColor() {
    if (item.itemType.colorHex != null) {
      try {
        return Color(
          int.parse(item.itemType.colorHex!.replaceFirst('#', '0xFF')),
        );
      } catch (e) {
        return AppColors.primary;
      }
    }
    return AppColors.primary;
  }

  IconData _getItemIcon() {
    // Try to get icon from iconName first
    if (item.itemType.iconName != null && item.itemType.iconName!.isNotEmpty) {
      return IconMapper.getIcon(item.itemType.iconName);
    }
    // Fallback to name-based icon detection
    return IconMapper.getIconFromItemName(item.itemType.nameAr, item.itemType.nameEn);
  }

  @override
  Widget build(BuildContext context) {
    final totalBoxes = item.fixedBoxes + item.movingBoxes;
    final totalUnits = item.fixedUnits + item.movingUnits;
    final itemColor = _getItemColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(),
              color: itemColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Item Name
          Expanded(
            child: Text(
              item.itemType.nameAr,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          // Boxes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'كراتين: $totalBoxes',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Units
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'وحدات: $totalUnits',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItem {
  final ItemType itemType;
  int fixedBoxes;
  int fixedUnits;
  int movingBoxes;
  int movingUnits;

  _InventoryItem({
    required this.itemType,
    required this.fixedBoxes,
    required this.fixedUnits,
    required this.movingBoxes,
    required this.movingUnits,
  });
}
