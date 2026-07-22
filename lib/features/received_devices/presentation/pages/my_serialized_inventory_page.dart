import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// MySerializedInventoryPage — v3.0
/// عرض كل الأرقام التسلسلية الموجودة في عهدة الفني حالياً
/// مصدر البيانات: GET /api/technicians/:id/serialized-items
class MySerializedInventoryPage extends StatefulWidget {
  const MySerializedInventoryPage({super.key});

  @override
  State<MySerializedInventoryPage> createState() => _MySerializedInventoryPageState();
}

class _MySerializedInventoryPageState extends State<MySerializedInventoryPage>
    with SingleTickerProviderStateMixin {
  final DashboardController _controller = Get.find<DashboardController>();
  final AuthController _authController = Get.find<AuthController>();

  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'all';

  final TextEditingController _searchController = TextEditingController();

  // Category filter options
  static const _categories = [
    ('all', 'الكل'),
    ('devices', 'الأجهزة'),
    ('sim', 'الشرائح'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSerializedItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSerializedItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = _authController.user?.id ?? '';
      final repo = _controller.getDashboardDataUseCase.repository;
      final items = await repo.fetchMySerializedItems(userId);
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final sn = (item['serialNumber'] as String? ?? '').toLowerCase();
        final typeName = (item['itemTypeName'] as String? ?? '').toLowerCase();
        final carrier = (item['carrierName'] as String? ?? '').toLowerCase();
        final category = item['itemTypeCategory'] as String? ?? '';

        final matchesSearch = _searchQuery.isEmpty ||
            sn.contains(_searchQuery.toLowerCase()) ||
            typeName.contains(_searchQuery.toLowerCase()) ||
            carrier.contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == 'all' ||
            category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // Group items by itemTypeId for display
  Map<String, List<Map<String, dynamic>>> get _groupedItems {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in _filteredItems) {
      final typeId = item['itemTypeId'] as String? ?? 'unknown';
      groups.putIfAbsent(typeId, () => []).add(item);
    }
    return groups;
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'devices': return AppColors.primary;
      case 'sim': return AppColors.success;
      default: return AppColors.accentPurple;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'devices': return Icons.phone_android_rounded;
      case 'sim': return Icons.sim_card_outlined;
      default: return Icons.inventory_2_outlined;
    }
  }

  String _getCarrierLabel(String? carrier) {
    switch (carrier?.toLowerCase()) {
      case 'mobily': return 'موبايلي';
      case 'stc': return 'STC';
      case 'zain': return 'زين';
      case 'lebara': return 'ليبارة';
      default: return '';
    }
  }

  Color _getCarrierColor(String? carrier) {
    switch (carrier?.toLowerCase()) {
      case 'mobily': return const Color(0xFF10B981);
      case 'stc': return const Color(0xFF8B5CF6);
      case 'zain': return const Color(0xFF06B6D4);
      case 'lebara': return const Color(0xFFF59E0B);
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: RasscoAppBar(
        titleText: 'أرقامي التسلسلية',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadSerializedItems,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ─── Stats Banner ───
            _buildStatsBanner(),

            // ─── Search & Filter ───
            _buildSearchAndFilter(),

            // ─── Content ───
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : _error != null
                      ? _buildErrorState()
                      : _filteredItems.isEmpty
                          ? _buildEmptyState()
                          : _buildGroupedList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBanner() {
    final deviceCount = _allItems
        .where((i) => i['itemTypeCategory'] == 'devices')
        .length;
    final simCount = _allItems
        .where((i) => i['itemTypeCategory'] == 'sim')
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          _buildStatChip(
            label: 'إجمالي السيريالات',
            value: '${_allItems.length}',
            color: AppColors.primary,
            icon: Icons.qr_code,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            label: 'أجهزة',
            value: '$deviceCount',
            color: AppColors.primary,
            icon: Icons.phone_android_rounded,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            label: 'شرائح',
            value: '$simCount',
            color: AppColors.success,
            icon: Icons.sim_card_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontFamily: 'BeIN', 
                        color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF111118),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'ابحث برقم تسلسلي، ICCID، أو نوع الجهاز...',
              hintStyle:
                  TextStyle(fontFamily: 'BeIN', color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuery = '';
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceDark,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$1;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat.$1);
                    _applyFilters();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      cat.$2,
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: isSelected ? AppColors.primary : Colors.white54,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final groups = _groupedItems;
    return RefreshIndicator(
      onRefresh: _loadSerializedItems,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final typeId = groups.keys.elementAt(index);
          final items = groups[typeId]!;
          final first = items.first;
          final typeName = first['itemTypeName'] as String? ?? typeId;
          final category = first['itemTypeCategory'] as String?;
          final color = _getCategoryColor(category);
          final icon = _getCategoryIcon(category);

          return _buildGroupCard(
            typeId: typeId,
            typeName: typeName,
            items: items,
            color: color,
            icon: icon,
          );
        },
      ),
    );
  }

  Widget _buildGroupCard({
    required String typeId,
    required String typeName,
    required List<Map<String, dynamic>> items,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          // Group Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    typeName,
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Text(
                    '${items.length} وحدة',
                    style: TextStyle(fontFamily: 'BeIN', 
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.white.withOpacity(0.05),
              indent: 14,
              endIndent: 14),

          // Serial items list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, idx) {
              return _buildSerialRow(items[idx], idx, color);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSerialRow(
      Map<String, dynamic> item, int idx, Color typeColor) {
    final sn = item['serialNumber'] as String? ?? '';
    final carrier = item['carrierName'] as String?;
    final carrierLabel = _getCarrierLabel(carrier);
    final carrierColor = _getCarrierColor(carrier);

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: sn));
        HapticFeedback.lightImpact();
        Get.snackbar(
          'تم النسخ',
          'تم نسخ الرقم: $sn',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            // Index
            SizedBox(
              width: 24,
              child: Text(
                '${idx + 1}',
                style: GoogleFonts.poppins(
                  color: typeColor.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Serial Number
            Expanded(
              child: Text(
                sn,
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Carrier badge (for SIM cards)
            if (carrierLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: carrierColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: carrierColor.withOpacity(0.25)),
                ),
                child: Text(
                  carrierLabel,
                  style: TextStyle(fontFamily: 'BeIN', 
                    color: carrierColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Copy hint
            const Icon(Icons.copy, color: Colors.white12, size: 14),
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
          const Icon(Icons.inventory_2_outlined,
              color: Colors.white12, size: 72),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد أرقام تسلسلية في عهدتك',
            style: TextStyle(fontFamily: 'BeIN', 
                color: Colors.white38, fontSize: 15),
          ),
          if (_searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'استلم عهدة وامسح الأجهزة لتظهر هنا',
                style: TextStyle(fontFamily: 'BeIN', 
                    color: Colors.white24, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 56),
          const SizedBox(height: 16),
          Text(
            'تعذّر تحميل البيانات',
            style: TextStyle(fontFamily: 'BeIN', 
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'BeIN', color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSerializedItems,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('إعادة المحاولة', style: TextStyle(fontFamily: 'BeIN', )),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
