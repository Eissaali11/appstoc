import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/fixed_inventory_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../dashboard/presentation/widgets/shimmer_loading.dart';
import '../../../dashboard/presentation/pages/update_inventory_page.dart';

class FixedInventoryPage extends GetView<FixedInventoryController> {
  const FixedInventoryPage({super.key});

  void _showUpdateInventoryDialog() {
    Get.to(
      () => UpdateInventoryPage(
        currentInventory: controller.inventory,
        itemTypes: controller.itemTypes,
        inventoryType: 'fixed',
        onSave: (entries) => controller.updateInventory(entries),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'المخزون الثابت',
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
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUpdateInventoryDialog(),
        icon: const Icon(Icons.edit),
        label: Text(
          'تحديث',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading && controller.inventory.isEmpty) {
          return const DashboardShimmer();
        }

        if (controller.error != null && controller.inventory.isEmpty) {
          return _buildErrorView();
        }

        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Stats Header
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'الكراتين',
                        controller.totalBoxes.toString(),
                        Icons.inventory_2,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'الوحدات',
                        controller.totalUnits.toString(),
                        Icons.circle,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'الإجمالي',
                        controller.totalItems.toString(),
                        Icons.analytics,
                      ),
                    ],
                  ),
                ),
              ),

              // Inventory List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = controller.inventory[index];
                      final itemType = controller.itemTypesMap[entry.itemTypeId];
                      
                      if (itemType == null) return const SizedBox();

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
                          child: _InventoryItemCard(
                            itemType: itemType,
                            boxes: entry.boxes,
                            units: entry.units,
                          ),
                        ),
                      );
                    },
                    childCount: controller.inventory.length,
                  ),
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
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
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.error ?? 'حدث خطأ في تحميل البيانات',
              style: GoogleFonts.cairo(
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
                style: GoogleFonts.cairo(
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
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد مخزون ثابت',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم العثور على أي عناصر في المخزون الثابت',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => controller.refresh(),
            icon: const Icon(Icons.refresh),
            label: Text(
              'تحديث',
              style: GoogleFonts.cairo(
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
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final ItemType itemType;
  final int boxes;
  final int units;

  const _InventoryItemCard({
    required this.itemType,
    required this.boxes,
    required this.units,
  });

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

  @override
  Widget build(BuildContext context) {
    final itemColor = _getItemColor();
    final total = boxes + units;

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
          color: total > 0
              ? itemColor.withOpacity(0.3)
              : AppColors.border.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          if (total > 0)
            BoxShadow(
              color: itemColor.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
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
                itemType.iconName != null && itemType.iconName!.isNotEmpty
                    ? IconMapper.getIcon(itemType.iconName)
                    : IconMapper.getIconFromItemName(itemType.nameAr, itemType.nameEn),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Name and Details
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemType.nameEn,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuantityChip(
                        'كراتين',
                        boxes,
                        AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildQuantityChip(
                        'وحدات',
                        units,
                        AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Total Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: total > 0
                      ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                      : [AppColors.textSecondary, AppColors.textSecondary.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    total.toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'إجمالي',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
