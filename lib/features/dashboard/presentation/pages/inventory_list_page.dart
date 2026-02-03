import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../widgets/inventory_filter_bar.dart';
import '../widgets/inventory_item_card.dart';
import '../widgets/shimmer_loading.dart';
import '../../../../shared/models/item_type.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final TextEditingController _searchController = TextEditingController();
  InventoryFilter _selectedFilter = InventoryFilter.all;
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'total', 'fixed', 'moving'

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

  List<_InventoryItem> _getFilteredItems(DashboardController controller) {
    final Map<String, _InventoryItem> itemsMap = {};

    // دمج المخزون الثابت والمتحرك
    for (var entry in controller.fixedInventory) {
      final itemType = controller.itemTypesMap[entry.itemTypeId];
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

    for (var entry in controller.movingInventory) {
      final itemType = controller.itemTypesMap[entry.itemTypeId];
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

    // الترتيب
    switch (_sortBy) {
      case 'total':
        items.sort((a, b) {
          final aTotal = a.fixedBoxes + a.fixedUnits + a.movingBoxes + a.movingUnits;
          final bTotal = b.fixedBoxes + b.fixedUnits + b.movingBoxes + b.movingUnits;
          return bTotal.compareTo(aTotal);
        });
        break;
      case 'fixed':
        items.sort((a, b) {
          final aTotal = a.fixedBoxes + a.fixedUnits;
          final bTotal = b.fixedBoxes + b.fixedUnits;
          return bTotal.compareTo(aTotal);
        });
        break;
      case 'moving':
        items.sort((a, b) {
          final aTotal = a.movingBoxes + a.movingUnits;
          final bTotal = b.movingBoxes + b.movingUnits;
          return bTotal.compareTo(aTotal);
        });
        break;
      case 'name':
        items.sort((a, b) => a.itemType.sortOrder.compareTo(b.itemType.sortOrder));
        break;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      builder: (controller) {
        if (controller.isLoading && controller.isInitialLoad) {
          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: const DashboardShimmer(),
          );
        }

        final filteredItems = _getFilteredItems(controller);

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          drawer: const AppDrawer(),
          body: Column(
            children: [
              // Filter Bar
              InventoryFilterBar(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                searchController: _searchController,
                searchQuery: _searchQuery,
              ),
              // Sort and Count Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.surfaceDark,
                child: Row(
                  children: [
                    Text(
                      '${filteredItems.length} صنف',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Sort Button
                    PopupMenuButton<String>(
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ترتيب',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'name' ? Icons.check : null,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text('حسب الاسم'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'total',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'total' ? Icons.check : null,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text('حسب الإجمالي'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'fixed',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'fixed' ? Icons.check : null,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text('حسب الثابت'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'moving',
                          child: Row(
                            children: [
                              Icon(
                                _sortBy == 'moving' ? Icons.check : null,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text('حسب المتحرك'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Items List
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => controller.refresh(),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 300 + (index * 50),
                              ),
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
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
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
              _searchQuery.isNotEmpty
                  ? 'لم يتم العثور على أصناف تطابق البحث'
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
