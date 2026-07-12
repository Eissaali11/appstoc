import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../controllers/dashboard_controller.dart';
import '../../domain/repositories/dashboard_repository.dart';

class InventorySectionDetailsPage extends StatefulWidget {
  const InventorySectionDetailsPage({super.key});

  @override
  State<InventorySectionDetailsPage> createState() => _InventorySectionDetailsPageState();
}

class _InventorySectionDetailsPageState extends State<InventorySectionDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatusFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, String>> _custodySerials = [];
  bool _loadingCustody = true;
  int _inTransitCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustodyData());
  }

  bool _matchesItemType(Map<String, dynamic> item, ItemType itemType) {
    final typeId = item['itemTypeId']?.toString();
    final category = item['itemTypeCategory']?.toString();
    if (typeId != null && typeId == itemType.id) return true;
    if (category != null && category == itemType.category) return true;
    return false;
  }

  Future<void> _loadCustodyData() async {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final ItemType itemType = args['itemType'] as ItemType? ?? ItemType(
      id: 'mock-pos',
      nameAr: 'جهاز نقطة بيع POS',
      nameEn: 'POS Terminal V2',
      iconName: 'devices',
      colorHex: '#18B2B0',
      sortOrder: 1,
      isActive: true,
      isVisible: true,
      category: 'devices',
    );

    final List<Map<String, String>> merged = [];
    final seen = <String>{};

    void addRow(Map<String, String> row, {bool prefer = false}) {
      final serial = (row['serial'] ?? '').trim();
      if (serial.isEmpty) return;
      final key = serial.toLowerCase();
      if (seen.contains(key)) {
        if (!prefer) return;
        merged.removeWhere((e) => (e['serial'] ?? '').toLowerCase() == key);
      }
      seen.add(key);
      merged.add(row);
    }

    try {
      List<dynamic> activeItems = (args['activeItems'] as List?) ?? [];
      List<dynamic> deliveredItems = (args['deliveredItems'] as List?) ?? [];
      final List<dynamic> passedSerials = args['serials'] as List? ?? [];

      // Refresh from API when possible (source of truth after order close)
      if (Get.isRegistered<DashboardController>()) {
        final dash = Get.find<DashboardController>();
        final userId = dash.user?.id as String?;
        if (userId != null) {
          try {
            final repo = Get.find<DashboardRepository>();
            final active = await repo.fetchMySerializedItems(userId);
            final deliveredByType = await repo.fetchDeliveredItems(
              userId,
              itemTypeId: itemType.id,
            );
            // Also fetch all and filter by category — itemType.id may not match DB UUID
            final deliveredAll = await repo.fetchDeliveredItems(userId);
            activeItems = active.where((e) => _matchesItemType(e, itemType)).toList();
            final mergedDelivered = <String, Map<String, dynamic>>{};
            for (final e in [...deliveredByType, ...deliveredAll]) {
              if (!_matchesItemType(e, itemType) &&
                  e['itemTypeId']?.toString() != itemType.id) {
                // category match via name for legacy type ids like n950
                final name = '${e['itemTypeName'] ?? ''}'.toLowerCase();
                final cat = '${e['itemTypeCategory'] ?? ''}';
                final matchesName = itemType.category == 'devices'
                    ? (cat == 'devices' || name.contains('n950') || name.contains('pos'))
                    : (cat == 'sim' || name.contains('lebara') || name.contains('sim') || name.contains('شريحة'));
                if (!matchesName) continue;
              }
              final sn = '${e['serialNumber'] ?? ''}';
              if (sn.isEmpty) continue;
              mergedDelivered[sn] = e;
            }
            deliveredItems = mergedDelivered.values.toList();
          } catch (e) {
            debugPrint('Custody API refresh failed: $e');
          }
        }
      }

      // Delivered first (wins over active on duplicate serial)
      for (final raw in deliveredItems) {
        final item = Map<String, dynamic>.from(raw as Map);
        addRow({
          'serial': '${item['serialNumber'] ?? ''}',
          'tid': '${item['barcode'] ?? ''}',
          'status': 'مسلّم للعميل',
          'type': itemType.category == 'sim' ? 'شريحة' : 'متحرك',
          'customerName': '',
          'orderId': item['referenceId'] != null ? '#${item['referenceId']}' : '',
          'date': '${item['deliveredAt'] ?? item['createdAt'] ?? ''}',
          'simType': '${item['carrierName'] ?? ''}',
          'notes': '${item['notes'] ?? ''}',
        }, prefer: true);
      }

      // Active custody from API objects
      if (activeItems.isNotEmpty) {
        for (final raw in activeItems) {
          final item = Map<String, dynamic>.from(raw as Map);
          final statusRaw = '${item['status'] ?? ''}'.toUpperCase();
          if (statusRaw == 'DELIVERED') continue;
          addRow({
            'serial': '${item['serialNumber'] ?? ''}',
            'tid': item['barcode'] != null
                ? '${item['barcode']}'
                : ((item['serialNumber']?.toString().length ?? 0) > 4
                    ? 'T-${item['serialNumber'].toString().substring(item['serialNumber'].toString().length - 4)}'
                    : ''),
            'status': statusRaw.contains('TRANSIT') ? 'قيد النقل' : 'نشط في العهدة',
            'type': itemType.category == 'sim' ? 'شريحة' : 'متحرك',
            'simType': '${item['carrierName'] ?? ''}',
          });
        }
      } else {
        for (final s in passedSerials) {
          final serial = s.toString();
          addRow({
            'serial': serial,
            'tid': serial.length > 4 ? 'T-${serial.substring(serial.length - 4)}' : 'T-$serial',
            'status': 'نشط في العهدة',
            'type': itemType.category == 'sim' ? 'شريحة' : 'متحرك',
          });
        }
      }

      // Enrich / add from completed courier requests (real closes only — no mock)
      if (Get.isRegistered<CourierRequestsController>()) {
        final requestsController = Get.find<CourierRequestsController>();
        final completedRequests =
            requestsController.requests.where((r) => r.isCompleted).toList();

        for (final request in completedRequests) {
          if (itemType.category == 'devices' &&
              request.sn != null &&
              request.sn!.trim().isNotEmpty) {
            addRow({
              'serial': request.sn!,
              'tid': request.tid ?? '',
              'status': 'مسلّم للعميل',
              'type': 'متحرك',
              'customerName': request.customerName ?? '',
              'retailerName': request.retailerName ?? '',
              'orderId': '#${request.id}',
              'date': request.date ?? '',
              'terminalId': request.terminalId ?? '',
              'city': request.city ?? '',
              'address': request.addressAr ?? '',
              'mobile': request.mobile ?? '',
              'installationType': request.installationType ?? '',
              'simType': request.simType ?? '',
              'simSerial': request.simSerial ?? '',
              'trsm': request.trsm ?? '',
              'incidentNumber': request.incidentNumber ?? '',
            }, prefer: true);
          } else if (itemType.category == 'sim' &&
              request.simSerial != null &&
              request.simSerial!.trim().isNotEmpty) {
            addRow({
              'serial': request.simSerial!,
              'tid': '',
              'status': 'مسلّم للعميل',
              'type': 'شريحة',
              'customerName': request.customerName ?? '',
              'retailerName': request.retailerName ?? '',
              'orderId': '#${request.id}',
              'date': request.date ?? '',
              'terminalId': request.terminalId ?? '',
              'city': request.city ?? '',
              'address': request.addressAr ?? '',
              'mobile': request.mobile ?? '',
              'installationType': request.installationType ?? '',
              'simType': request.simType ?? '',
              'trsm': request.trsm ?? '',
              'incidentNumber': request.incidentNumber ?? '',
            }, prefer: true);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _custodySerials = merged;
        _inTransitCount =
            merged.where((e) => e['status'] == 'قيد النقل').length;
        _loadingCustody = false;
      });
    } catch (e) {
      debugPrint('Failed to build custody list: $e');
      if (!mounted) return;
      setState(() => _loadingCustody = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getUnitName(ItemType type) {
    if (type.category == 'papers') return 'رول';
    if (type.category == 'devices') return 'جهاز';
    if (type.category == 'sim') return 'شريحة';
    return 'حبة';
  }

  /// تحديد صورة الصنف/المشغل بناءً على النوع أو اسم الصنف
  String? _getOperatorImagePath(dynamic input) {
    if (input == null) return null;
    if (input is ItemType) {
      return IconMapper.getItemImagePath(input.nameAr, input.nameEn, input.category);
    }
    return IconMapper.getItemImagePath(input.toString(), '', '');
  }

  @override
  Widget build(BuildContext context) {
    // قراءة Arguments أو استخدام fallbacks رائعة
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    
    // إنشاء صنف افتراضي لمنع الأخطاء في حال الدخول المباشر
    final ItemType itemType = args['itemType'] as ItemType? ?? ItemType(
      id: 'mock-pos',
      nameAr: 'جهاز نقطة بيع POS',
      nameEn: 'POS Terminal V2',
      iconName: 'devices',
      colorHex: '#18B2B0',
      sortOrder: 1,
      isActive: true,
      isVisible: true,
      category: 'devices',
    );

    final int fixedBoxes = args['fixedBoxes'] ?? 0;
    final int fixedUnits = args['fixedUnits'] ?? 0;
    final int movingBoxes = args['movingBoxes'] ?? 0;
    final int movingUnits = args['movingUnits'] ?? 0;

    final totalBoxes = fixedBoxes + movingBoxes;
    final totalUnits = fixedUnits + movingUnits;
    final totalAvailable = totalBoxes + totalUnits;

    // Derive counters from the same list used by filters (fixes top vs chip mismatch)
    final int activeCount = _loadingCustody
        ? (args['activeCount'] as int? ?? 0)
        : _custodySerials.where((s) => s['status'] == 'نشط في العهدة' || s['status'] == 'قيد النقل').length;
    final int executedCount = _loadingCustody
        ? (args['executedCount'] as int? ?? 0)
        : _custodySerials.where((s) => s['status'] == 'مسلّم للعميل' || s['status'] == 'مسلّم').length;
    final custodySerials = _custodySerials;

    // سجل أنشطة من التسليمات الحقيقية فقط
    final List<Map<String, dynamic>> activityLog = custodySerials
        .where((e) => e['status'] == 'مسلّم للعميل')
        .take(10)
        .map((e) => {
              'title': 'تسليم للعميل',
              'desc': e['customerName']?.isNotEmpty == true
                  ? 'تم تسليم ${e['serial']} للعميل ${e['customerName']}${e['orderId']?.isNotEmpty == true ? ' — طلب ${e['orderId']}' : ''}'
                  : 'تم تسليم الرقم التسلسلي ${e['serial']}${e['orderId']?.isNotEmpty == true ? ' — طلب ${e['orderId']}' : ''}',
              'date': e['date']?.isNotEmpty == true ? e['date']! : 'مكتمل',
              'icon': Icons.assignment_turned_in_outlined,
              'color': AppColors.success,
            })
        .toList();

    // استخراج لون الصنف وأيقونته
    Color itemColor = AppColors.primary;
    if (itemType.colorHex != null) {
      try {
        itemColor = Color(int.parse(itemType.colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    IconData itemIcon = Icons.devices;
    if (itemType.iconName != null && itemType.iconName!.isNotEmpty) {
      itemIcon = IconMapper.getIcon(itemType.iconName);
    } else {
      itemIcon = IconMapper.getIconFromItemName(itemType.nameAr, itemType.nameEn);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            // أيقونة الصنف في AppBar
            Builder(builder: (ctx) {
              final opImg = _getOperatorImagePath(itemType);
              if (opImg != null) {
                return Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: itemType.category == 'devices' ? Colors.transparent : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(opImg, fit: BoxFit.contain),
                );
              }
              // Fallback to Icon
              return Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: itemColor.withOpacity(0.3)),
                ),
                child: Icon(itemIcon, color: itemColor, size: 20),
              );
            }),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                itemType.nameAr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // كارت الهوية التعريفي للصنف بالعلوي
                  _buildItemHeaderCard(itemType, itemColor, itemIcon),

                  // شبكة الإحصاءات الذكية
                  _buildStatsGrid(activeCount, executedCount, _inTransitCount),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                Container(
                  color: AppColors.surfaceDark,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.normal, fontSize: 14),
                    tabs: [
                      Tab(text: itemType.category == 'sim' ? 'أرقام الشرائح' : 'أرقام الأجهزة'),
                      Tab(text: 'سجل الأنشطة'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // التبويب الأول: قائمة العهدة الفردية
            _loadingCustody
                ? const Center(child: CircularProgressIndicator())
                : _buildCustodyItemsTab(custodySerials, itemColor, itemType),

            // التبويب الثاني: سجل الأنشطة والتحركات
            _buildActivityLogTab(activityLog),
          ],
        ),
      ),
      floatingActionButton: (itemType.category != 'devices' && itemType.category != 'sim')
          ? FloatingActionButton.extended(
              onPressed: () => _showUpdateStockDialog(context, itemType, activeCount),
              backgroundColor: itemColor,
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: Text(
                'تحديث الكمية',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  void _showUpdateStockDialog(BuildContext context, ItemType itemType, int currentVal) {
    final controller = TextEditingController(text: currentVal.toString());
    final isUpdating = false.obs;
    final dashboardController = Get.find<DashboardController>();

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'تحديث مخزون ${itemType.nameAr}',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرجاء إدخال الكمية الجديدة للمخزون الحالي:',
                  style: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الكمية (وحدات)',
                    labelStyle: GoogleFonts.cairo(color: Colors.white38),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(color: Colors.white38),
                ),
              ),
              Obx(() => ElevatedButton(
                onPressed: isUpdating.value ? null : () async {
                  final text = controller.text.trim();
                  final qty = int.tryParse(text);
                  if (qty == null || qty < 0) {
                    Get.snackbar(
                      'خطأ',
                      'الرجاء إدخال كمية صحيحة أكبر من أو تساوي 0',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  isUpdating.value = true;
                  try {
                    final dio = Get.find<Dio>();
                    final userId = dashboardController.user?.id;

                    if (userId == null) {
                      throw Exception('المستخدم غير مسجل دخول');
                    }

                    await dio.post(
                      '/api/technicians/$userId/fixed-inventory-entries',
                      data: {
                        'itemTypeId': itemType.id,
                        'boxes': 0,
                        'units': qty,
                      },
                    );

                    Navigator.of(context).pop();
                    Get.back();
                    await dashboardController.refresh();

                    Get.snackbar(
                      'نجح',
                      'تم تحديث مخزون ${itemType.nameAr} بنجاح ✓',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      'خطأ',
                      'فشل التحديث: ${e.toString().replaceAll('Exception: ', '')}',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.error,
                      colorText: Colors.white,
                    );
                  } finally {
                    isUpdating.value = false;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isUpdating.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'حفظ',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemHeaderCard(ItemType itemType, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // أيقونة الصنف المكبّرة
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: itemType.category == 'devices'
                  ? color.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            padding: itemType.category == 'devices' ? const EdgeInsets.all(8) : const EdgeInsets.all(6),
            child: Builder(builder: (ctx) {
              final operatorImg = _getOperatorImagePath(itemType);
              if (operatorImg != null) {
                return Image.asset(operatorImg, fit: BoxFit.contain);
              }
              // Fallback to Icon
              return Icon(icon, color: color, size: 36);
            }),
          ),
          const SizedBox(width: 16),

          // نصوص التعريف
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        itemType.nameAr,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // عرض صورة المشغل بجانب اسم الصنف إذا كانت شريحة
                    Builder(builder: (ctx) {
                      final operatorImg = _getOperatorImagePath(itemType);
                      if (operatorImg != null) {
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              operatorImg,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  itemType.nameEn,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // بادج وحدة القياس
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Text(
              _getUnitName(itemType),
              style: GoogleFonts.cairo(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int activeCount, int executedCount, int inTransitCount) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // إجمالي النشط
          Expanded(
            child: _buildSingleStatCard(
              context,
              title: 'العهدة النشطة',
              value: '$activeCount وحدات',
              icon: Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          // إجمالي المستعلم/المسلم
          Expanded(
            child: _buildSingleStatCard(
              context,
              title: 'العهدة المسلّمة',
              value: '$executedCount وحدات',
              icon: Icons.assignment_turned_in_outlined,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          // قيد النقل والتحويل
          Expanded(
            child: _buildSingleStatCard(
              context,
              title: 'قيد النقل حالياً',
              value: '$inTransitCount وحدات',
              icon: Icons.autorenew,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: context.fontSize(9.5),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: context.fontSize(12.5),
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustodyItemsTab(List<Map<String, String>> serials, Color activeColor, ItemType itemType) {
    // --- تطبيق الفلتر + البحث ---
    List<Map<String, String>> filteredSerials = serials;
    if (_selectedStatusFilter == 'active') {
      filteredSerials = serials.where((s) => s['status'] == 'نشط في العهدة' || s['status'] == 'قيد النقل').toList();
    } else if (_selectedStatusFilter == 'delivered') {
      filteredSerials = serials.where((s) => s['status'] == 'مسلّم للعميل' || s['status'] == 'مسلّم').toList();
    }
    if (_searchQuery.isNotEmpty) {
      filteredSerials = filteredSerials.where((s) =>
        (s['serial'] ?? '').toLowerCase().contains(_searchQuery) ||
        (s['tid'] ?? '').toLowerCase().contains(_searchQuery) ||
        (s['customerName'] ?? '').toLowerCase().contains(_searchQuery) ||
        (s['orderId'] ?? '').toLowerCase().contains(_searchQuery),
      ).toList();
    }

    final isDevice = itemType.category == 'devices';

    return Column(
      children: [
        // ─── حقل البحث ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: isDevice ? 'ابحث برقم السيريل أو TID أو اسم العميل...' : 'ابحث برقم الشريحة أو اسم العميل...',
              hintStyle: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceDark,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.6), width: 1.5),
              ),
            ),
          ),
        ),

        // ─── فلاتر الحالة ───
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  count: serials.length,
                  isSelected: _selectedStatusFilter == 'all',
                  color: AppColors.primary,
                  onTap: () => setState(() => _selectedStatusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'نشط بالعهدة',
                  count: serials.where((s) => s['status'] == 'نشط في العهدة' || s['status'] == 'قيد النقل').length,
                  isSelected: _selectedStatusFilter == 'active',
                  color: AppColors.primary,
                  onTap: () => setState(() => _selectedStatusFilter = 'active'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'مسلّم للعميل',
                  count: serials.where((s) => s['status'] == 'مسلّم للعميل' || s['status'] == 'مسلّم').length,
                  isSelected: _selectedStatusFilter == 'delivered',
                  color: AppColors.success,
                  onTap: () => setState(() => _selectedStatusFilter = 'delivered'),
                ),
              ],
            ),
          ),
        ),

        // ─── قائمة العناصر ───
        Expanded(
          child: filteredSerials.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد عناصر',
                        style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filteredSerials.length,
                  itemBuilder: (context, index) {
                    final item = filteredSerials[index];
                    final bool isDelivered = item['status'] == 'مسلّم للعميل' || item['status'] == 'مسلّم';
                    final bool isTransit = item['status'] == 'قيد التسليم';
                    final bool isMaintenance = item['status'] == 'تحت الصيانة';

                    Color statusColor = AppColors.success;
                    if (isTransit) statusColor = AppColors.warning;
                    if (isMaintenance) statusColor = AppColors.error;
                    if (isDelivered) statusColor = const Color(0xFF3B82F6);

                    final hasCustomer = isDelivered &&
                        item['customerName'] != null &&
                        item['customerName']!.isNotEmpty;

                    return GestureDetector(
                      onTap: () {
                        if (hasCustomer) {
                          _showDeliveryDetailsSheet(context, item, statusColor);
                        } else {
                          _showActiveItemDetailsSheet(context, item, statusColor, itemType);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDelivered
                                ? statusColor.withOpacity(0.25)
                                : Colors.white.withOpacity(0.06),
                            width: isDelivered ? 1.5 : 1,
                          ),
                          boxShadow: isDelivered
                              ? [BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ─── صف رئيسي: أيقونة + معلومات ───
                              Row(
                                children: [
                                  // أيقونة الصنف (مُكبَّرة)
                                  Builder(builder: (ctx2) {
                                    final specificType = item['simType'] ?? '';
                                    final opImg = itemType.category == 'sim'
                                        ? (_getOperatorImagePath(specificType) ?? _getOperatorImagePath(itemType))
                                        : _getOperatorImagePath(itemType);
                                    if (opImg != null) {
                                      return Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(
                                          color: itemType.category == 'devices' ? Colors.transparent : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                                        ),
                                        padding: const EdgeInsets.all(5),
                                        child: Image.asset(opImg, fit: BoxFit.contain),
                                      );
                                    }
                                    final itemIcon = itemType.iconName != null && itemType.iconName!.isNotEmpty
                                        ? IconMapper.getIcon(itemType.iconName)
                                        : IconMapper.getIconFromItemName(itemType.nameAr, itemType.nameEn);
                                    return Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        color: AppColors.cardColor.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: Icon(itemIcon, color: activeColor, size: 24),
                                    );
                                  }),
                                 const SizedBox(width: 12),

                                // معلومات الجهاز/الشريحة
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // اسم الصنف
                                      Text(
                                        itemType.nameAr,
                                        style: GoogleFonts.cairo(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // الرقم التسلسلي
                                      Text(
                                        item['serial'] ?? '',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // صف: TID + الفئة
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          if (item['tid'] != null && item['tid']!.isNotEmpty)
                                            _buildInfoBadge('TID: ${item['tid']}', Colors.blueGrey),
                                          _buildInfoBadge(
                                            isDevice ? '📱 ${item['type'] ?? 'متحرك'}' : '🔌 ${item['type'] ?? 'شريحة'}',
                                            Colors.purple,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // بادج الحالة
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    item['status'] ?? '',
                                    style: GoogleFonts.cairo(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ─── اختصار بيانات العميل (تنبيه بالنقر) ───
                            if (hasCustomer) ...[
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withOpacity(0.06), height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.person_outline, color: statusColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'العميل: ',
                                    style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item['customerName'] ?? '-',
                                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'التفاصيل',
                                          style: GoogleFonts.cairo(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(Icons.arrow_forward_ios, color: statusColor, size: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // ─── تنبيه بالنقر للأجهزة والشرائح النشطة ───
                            if (!hasCustomer) ...[
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withOpacity(0.06), height: 1),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: statusColor, size: 14),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'عهدة نشطة - جاهزة للتسليم للعميل',
                                      style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'عرض البيانات',
                                          style: GoogleFonts.cairo(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(Icons.arrow_forward_ios, color: statusColor, size: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(color: color.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showDeliveryDetailsSheet(BuildContext context, Map<String, String> item, Color statusColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مقبض السحب العلوي للتصميم
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.receipt_long, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل طلب التسليم المغلق',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'الطلب ${item['orderId'] ?? ''}',
                            style: GoogleFonts.cairo(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // بادج الحالة مغلق
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'مكتمل / مغلق',
                        style: GoogleFonts.cairo(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 10),

                // البيانات مرتبة بشكل منسق وجميل
                _buildSheetDetailCard('معلومات العميل والتاجر', [
                  _buildSheetRow('اسم العميل', item['customerName'], Icons.person, statusColor),
                  _buildSheetRow('اسم التاجر', item['retailerName'], Icons.store, Colors.orange),
                  _buildSheetRow('رقم الجوال', item['mobile'], Icons.phone, Colors.lightGreen),
                ]),

                _buildSheetDetailCard('الموقع والتاريخ', [
                  _buildSheetRow('المدينة', item['city'], Icons.location_city, Colors.teal),
                  _buildSheetRow('العنوان', item['address'], Icons.location_on, Colors.green),
                  _buildSheetRow('تاريخ التنفيذ', item['date'], Icons.calendar_today, Colors.blueGrey),
                ]),

                _buildSheetDetailCard('معلومات الجهاز الفنية', [
                  _buildSheetRow('الرقم التسلسلي للطلب', item['serial'], Icons.qr_code, Colors.purple),
                  _buildSheetRow('رقم الجهاز (TID)', item['tid'], Icons.credit_card, Colors.blue),
                  _buildSheetRow('Terminal ID', item['terminalId'], Icons.tag, Colors.cyan),
                  _buildSheetRow('نوع التركيب', item['installationType'], Icons.build, Colors.amber),
                ]),

                if (item['simType'] != null && item['simType']!.isNotEmpty)
                  _buildSheetDetailCard('بيانات شريحة الاتصال', [
                    _buildSheetRow('مزود الخدمة', item['simType'], Icons.sim_card, Colors.purple),
                    _buildSheetRow('رقم الشريحة (ICCID)', item['simSerial'], Icons.numbers, Colors.indigo),
                    _buildSheetRow('ترميز TRSM', item['trsm'], Icons.security, Colors.red),
                    _buildSheetRow('رقم الحادثة', item['incidentNumber'], Icons.confirmation_number, Colors.pink),
                  ]),

                const SizedBox(height: 12),
                
                // زر الإغلاق
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                    ),
                    child: Text(
                      'إغلاق النافذة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActiveItemDetailsSheet(BuildContext context, Map<String, String> item, Color statusColor, ItemType itemType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final bool isDevice = itemType.category == 'devices';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مقبض السحب العلوي للتصميم
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDevice ? Icons.devices : Icons.sim_card,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDevice ? 'تفاصيل الجهاز النشط' : 'تفاصيل الشريحة النشطة',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            itemType.nameAr,
                            style: GoogleFonts.cairo(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // بادج الحالة نشط
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        item['status'] ?? 'نشط في العهدة',
                        style: GoogleFonts.cairo(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 10),

                // البيانات مرتبة بشكل منسق وجميل
                _buildSheetDetailCard('المعلومات الأساسية', [
                  _buildSheetRow(
                    isDevice ? 'الرقم التسلسلي للجهاز' : 'رقم الشريحة (ICCID)',
                    item['serial'],
                    Icons.qr_code,
                    statusColor,
                  ),
                  if (isDevice && item['tid'] != null && item['tid']!.isNotEmpty)
                    _buildSheetRow('رقم الجهاز (TID)', item['tid'], Icons.credit_card, Colors.blue),
                  _buildSheetRow('الفئة والنوع', item['type'] ?? (isDevice ? 'متحرك' : 'شريحة اتصال'), Icons.category, Colors.purple),
                  _buildSheetRow('حالة العهدة', 'جاهزة للتسليم للعميل 🚀', Icons.info_outline, Colors.amber),
                ]),

                // كارت تعليمات ذكي
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[300], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDevice 
                              ? 'هذا الجهاز مسجل حالياً في عهدتك النشطة. يمكنك نقله وتسليمه للعميل مباشرة عند بدء زيارة تركيب جديدة.'
                              : 'هذه الشريحة مسجلة حالياً في عهدتك النشطة وجاهزة للاستخدام في جهاز العميل.',
                          style: GoogleFonts.cairo(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // زر نسخ الرقم التسلسلي + زر الإغلاق في Row واحد
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (item['serial'] != null) {
                            Clipboard.setData(ClipboardData(text: item['serial']!));
                            Get.snackbar(
                              'تم النسخ',
                              isDevice ? 'تم نسخ الرقم التسلسلي للجهاز' : 'تم نسخ رقم الشريحة',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surfaceDark,
                              colorText: Colors.white,
                              borderRadius: 10,
                              margin: const EdgeInsets.all(15),
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: Text(
                          isDevice ? 'نسخ السيريال' : 'نسخ رقم الشريحة',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إغلاق النافذة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetDetailCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSheetRow(String label, String? value, IconData icon, Color iconColor) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogTab(List<Map<String, dynamic>> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isLast = index == logs.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة النشاط والخطوط العمودية
            Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: (log['color'] as Color).withOpacity(0.15),
                  child: Icon(log['icon'], size: 16, color: log['color']),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 54,
                    color: Colors.white10,
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // تفاصيل الحركة التاريخية
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          log['title'] ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        log['date'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log['desc'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

