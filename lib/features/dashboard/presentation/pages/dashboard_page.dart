import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/inventory_filter_bar.dart';
import '../widgets/pending_transfer_card.dart';
import '../widgets/shimmer_loading.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      body: Obx(() {
        // Loading State with Shimmer
        if (controller.isLoading && controller.isInitialLoad) {
          return const DashboardShimmer();
        }

        // Error State
        if (controller.error != null && controller.isInitialLoad) {
          return _buildErrorView();
        }

        final user = controller.user;
        if (user == null) {
          return _buildNoUserView();
        }

        // Main Content
        return _DashboardContent(
          controller: controller,
          userName: user.fullName,
        );
      }),
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

  Widget _buildNoUserView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'يرجى تسجيل الدخول',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: Text(
              'تسجيل الدخول',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final DashboardController controller;
  final String userName;

  const _DashboardContent({
    required this.controller,
    required this.userName,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final TextEditingController _searchController = TextEditingController();
  InventoryFilter _selectedFilter = InventoryFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_InventoryItem> _getFilteredItems() {
    final Map<String, _InventoryItem> itemsMap = {};

    // دمج المخزون الثابت والمتحرك
    for (var entry in widget.controller.fixedInventory) {
      final itemType = widget.controller.itemTypesMap[entry.itemTypeId];
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

    for (var entry in widget.controller.movingInventory) {
      final itemType = widget.controller.itemTypesMap[entry.itemTypeId];
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

    var items = itemsMap.values.toList();

    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item.itemType.nameAr.toLowerCase().contains(_searchQuery) ||
            item.itemType.nameEn.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // تطبيق الفلاتر
    switch (_selectedFilter) {
      case InventoryFilter.fixed:
        items = items.where((item) => item.fixedBoxes + item.fixedUnits > 0).toList();
        break;
      case InventoryFilter.moving:
        items = items.where((item) => item.movingBoxes + item.movingUnits > 0).toList();
        break;
      case InventoryFilter.hasStock:
        items = items.where((item) => 
          (item.fixedBoxes + item.fixedUnits + item.movingBoxes + item.movingUnits) > 0
        ).toList();
        break;
      case InventoryFilter.lowStock:
        items = items.where((item) {
          final total = item.fixedBoxes + item.fixedUnits + item.movingBoxes + item.movingUnits;
          return total > 0 && total < 10;
        }).toList();
        break;
      case InventoryFilter.all:
        break;
    }

    // الترتيب حسب sortOrder
    items.sort((a, b) => a.itemType.sortOrder.compareTo(b.itemType.sortOrder));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isNarrow = width < 400;
    final int crossAxisCount = isNarrow ? 1 : 2;
    // كلما زاد الرقم، قلّ ارتفاع البطاقة
    final double childAspectRatio = isNarrow ? 3.0 : 2.0;
    final filteredItems = _getFilteredItems();

    return RefreshIndicator(
      onRefresh: () => widget.controller.refresh(),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: DashboardHeader(
              userName: widget.userName,
              notificationCount: widget.controller.pendingTransfersCount,
            ),
          ),

          // Stats Cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600 + (index * 100)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStatsCard(index),
                  );
                },
                childCount: 4,
              ),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: QuickActionsSection(
                onRequestInventory: () => Get.toNamed('/request-inventory'),
              ),
            ),
          ),

          // Filter Bar
          SliverToBoxAdapter(
            child: InventoryFilterBar(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              searchController: _searchController,
              searchQuery: _searchQuery,
            ),
          ),

          // Inventory Items List
          if (filteredItems.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredItems[index];
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
                      child: InventoryItemCard(
                        itemType: item.itemType,
                        fixedBoxes: item.fixedBoxes,
                        fixedUnits: item.fixedUnits,
                        movingBoxes: item.movingBoxes,
                        movingUnits: item.movingUnits,
                      ),
                    );
                  },
                  childCount: filteredItems.length,
                ),
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            ),

          // Pending Transfers
          if (widget.controller.pendingTransfers.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PendingTransfersSection(
                  transfers: widget.controller.pendingTransfers,
                  onViewAll: () => Get.toNamed('/notifications'),
                  onAccept: (transferId) => widget.controller.acceptTransfer(transferId),
                  onReject: (transferId) => widget.controller.rejectTransfer(transferId),
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
  }

  Widget _buildStatsCard(int index) {
    switch (index) {
      case 0:
        return StatsCard(
          title: 'المخزون الثابت',
          value: widget.controller.fixedInventoryTotal.toString(),
          icon: Icons.inventory_2,
          gradient: [AppColors.primary, AppColors.primaryDark],
          onTap: () => Get.toNamed('/fixed-inventory'),
        );
      case 1:
        return StatsCard(
          title: 'المخزون المتحرك',
          value: widget.controller.movingInventoryTotal.toString(),
          icon: Icons.local_shipping,
          gradient: AppColors.purpleGradient,
          onTap: () => Get.toNamed('/moving-inventory'),
        );
      case 2:
        return StatsCard(
          title: 'طلبات معلقة',
          value: widget.controller.pendingTransfersCount.toString(),
          icon: Icons.pending_actions,
          gradient: AppColors.orangeGradient,
          onTap: () => Get.toNamed('/notifications'),
        );
      case 3:
        return StatsCard(
          title: 'إجمالي المخزون',
          value: (widget.controller.fixedInventoryTotal +
                  widget.controller.movingInventoryTotal)
              .toString(),
          icon: Icons.analytics,
          gradient: AppColors.greenGradient,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد أصناف',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != InventoryFilter.all
                  ? 'لم يتم العثور على أصناف تطابق البحث أو الفلتر'
                  : 'لا توجد أصناف في المخزون',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != InventoryFilter.all) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedFilter = InventoryFilter.all;
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: Text(
                  'إعادة تعيين الفلاتر',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
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
