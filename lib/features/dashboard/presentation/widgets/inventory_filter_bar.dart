import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

enum InventoryFilter {
  all,
  fixed,
  moving,
  hasStock,
  lowStock,
}

class InventoryFilterBar extends StatelessWidget {
  final InventoryFilter selectedFilter;
  final Function(InventoryFilter) onFilterChanged;
  final TextEditingController searchController;
  final String searchQuery;

  const InventoryFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.searchController,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: TextField(
              controller: searchController,
              style: GoogleFonts.cairo(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن صنف...',
                hintStyle: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'الكل',
                  icon: Icons.all_inclusive,
                  isSelected: selectedFilter == InventoryFilter.all,
                  onTap: () => onFilterChanged(InventoryFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'الثابت',
                  icon: Icons.inventory_2,
                  isSelected: selectedFilter == InventoryFilter.fixed,
                  onTap: () => onFilterChanged(InventoryFilter.fixed),
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'المتحرك',
                  icon: Icons.local_shipping,
                  isSelected: selectedFilter == InventoryFilter.moving,
                  onTap: () => onFilterChanged(InventoryFilter.moving),
                  color: AppColors.purpleGradient.first,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'متوفر',
                  icon: Icons.check_circle,
                  isSelected: selectedFilter == InventoryFilter.hasStock,
                  onTap: () => onFilterChanged(InventoryFilter.hasStock),
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'منخفض',
                  icon: Icons.warning,
                  isSelected: selectedFilter == InventoryFilter.lowStock,
                  onTap: () => onFilterChanged(InventoryFilter.lowStock),
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : AppColors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? chipColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? chipColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
