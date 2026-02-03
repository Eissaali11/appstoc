import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/utils/icon_mapper.dart';

class InventoryItemCard extends StatelessWidget {
  final ItemType itemType;
  final int fixedBoxes;
  final int fixedUnits;
  final int movingBoxes;
  final int movingUnits;
  final VoidCallback? onTap;

  const InventoryItemCard({
    super.key,
    required this.itemType,
    required this.fixedBoxes,
    required this.fixedUnits,
    required this.movingBoxes,
    required this.movingUnits,
    this.onTap,
  });

  int get totalBoxes => fixedBoxes + movingBoxes;
  int get totalUnits => fixedUnits + movingUnits;
  int get total => totalBoxes + totalUnits;

  Color _getItemColor() {
    if (itemType.colorHex != null) {
      try {
        return Color(
          int.parse(itemType.colorHex!.replaceFirst('#', '0xFF')),
        );
      } catch (e) {
        return AppColors.primary;
      }
    }
    return AppColors.primary;
  }

  IconData _getItemIcon() {
    // Try to get icon from iconName first
    if (itemType.iconName != null && itemType.iconName!.isNotEmpty) {
      return IconMapper.getIcon(itemType.iconName);
    }
    // Fallback to name-based icon detection
    return IconMapper.getIconFromItemName(itemType.nameAr, itemType.nameEn);
  }

  @override
  Widget build(BuildContext context) {
    final itemColor = _getItemColor();
    final hasStock = total > 0;
    final isLowStock = total > 0 && total < 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          color: hasStock
              ? (isLowStock
                  ? AppColors.warning.withOpacity(0.4)
                  : itemColor.withOpacity(0.3))
              : AppColors.border.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          if (hasStock)
            BoxShadow(
              color: itemColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Icon with Gradient
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            itemColor,
                            itemColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: itemColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getItemIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemType.nameAr,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itemType.nameEn,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Stock Status Badge
                    if (hasStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLowStock
                                ? [AppColors.warning, AppColors.warning.withOpacity(0.8)]
                                : [AppColors.success, AppColors.success.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (isLowStock ? AppColors.warning : AppColors.success)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLowStock ? Icons.warning : Icons.check_circle,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLowStock ? 'منخفض' : 'متوفر',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quantities Grid
                Row(
                  children: [
                    // Fixed Inventory
                    Expanded(
                      child: _QuantityCard(
                        title: 'المخزون الثابت',
                        boxes: fixedBoxes,
                        units: fixedUnits,
                        color: AppColors.primary,
                        icon: Icons.inventory_2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Moving Inventory
                    Expanded(
                      child: _QuantityCard(
                        title: 'المخزون المتحرك',
                        boxes: movingBoxes,
                        units: movingUnits,
                        color: AppColors.purpleGradient.first,
                        icon: Icons.local_shipping,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total
                    Expanded(
                      child: _QuantityCard(
                        title: 'الإجمالي',
                        boxes: totalBoxes,
                        units: totalUnits,
                        color: AppColors.success,
                        icon: Icons.analytics,
                        isTotal: true,
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
  }
}

class _QuantityCard extends StatelessWidget {
  final String title;
  final int boxes;
  final int units;
  final Color color;
  final IconData icon;
  final bool isTotal;

  const _QuantityCard({
    required this.title,
    required this.boxes,
    required this.units,
    required this.color,
    required this.icon,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icon and Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.inventory_2,
                  size: 12,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                boxes.toString(),
                style: GoogleFonts.cairo(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Units
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                units.toString(),
                style: GoogleFonts.cairo(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
