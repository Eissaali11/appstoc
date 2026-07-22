import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../../../../core/routing/app_pages.dart';
import 'package:dio/dio.dart';

bool _isActiveCustodyStatus(dynamic status) {
  final s = '${status ?? ''}'.toUpperCase();
  return s == 'RECEIVED_BY_TECHNICIAN' ||
      s == 'IN_TRANSIT_CUSTODY' ||
      s.contains('TRANSIT') ||
      s.contains('RECEIVED');
}

class CustodyCategoryItemsPage extends StatelessWidget {
  final String title;
  final String rawCategory;
  final List<MergedInventoryItem> items;
  final List<dynamic> completedRequests;
  final DashboardController dashboardController;
  final CourierRequestsController requestsController;

  const CustodyCategoryItemsPage({
    super.key,
    required this.title,
    required this.rawCategory,
    required this.items,
    required this.completedRequests,
    required this.dashboardController,
    required this.requestsController,
  });

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppColors.primary;
    if (rawCategory == 'sim') accentColor = AppColors.success;
    if (rawCategory == 'consumables') accentColor = AppColors.accentPurple;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: RasscoAppBar(
          titleText: title,
        ),
        body: items.isEmpty
            ? Center(
                child: Text(
                  'لا توجد عناصر في هذا القسم حالياً',
                  style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 14),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final itemTypeId = item.itemType.id;
                  final category = item.itemType.category;

                  final actualSerials = dashboardController.serializedItems
                      .where((si) =>
                          si['itemTypeId'] == itemTypeId &&
                          _isActiveCustodyStatus(si['status']))
                      .map((si) => si['serialNumber'] as String? ?? '')
                      .where((s) => s.isNotEmpty)
                      .toList();

                  final deliveredForType = dashboardController.deliveredItems
                      .where((si) => si['itemTypeId'] == itemTypeId)
                      .toList();

                  // Counts must use the same itemTypeId-scoped lists (no category-wide courier dump)
                  final int executedCount = deliveredForType.length;

                  int receivedCount = dashboardController.pendingTransfers
                      .where((t) => t.itemType == itemTypeId && t.status == 'accepted')
                      .fold(0, (sum, t) => sum + t.quantity);

                  final current = (category == 'devices' || category == 'sim')
                      ? actualSerials.length
                      : item.totalQuantity;

                  final starting = current + executedCount - receivedCount > 0 
                      ? current + executedCount - receivedCount 
                      : 0;

                  Color categoryColor = accentColor;
                  IconData categoryIcon = Icons.inventory_2_outlined;

                  if (category == 'devices') {
                    categoryIcon = Icons.phone_android_rounded;
                  } else if (category == 'sim') {
                    categoryIcon = Icons.sim_card_outlined;
                  } else if (category == 'papers') {
                    categoryIcon = Icons.receipt_long_outlined;
                  } else if (category == 'accessories') {
                    categoryIcon = Icons.style_outlined;
                  }

                  return _buildCustodyLedgerCard(
                    context: context,
                    title: item.itemType.nameAr,
                    subtitle: item.itemType.nameEn,
                    category: _getCategoryLabel(category ?? ''),
                    categoryColor: categoryColor,
                    categoryIcon: categoryIcon,
                    starting: starting,
                    received: receivedCount,
                    executed: executedCount,
                    current: current,
                    serials: actualSerials,
                    itemTypeId: item.itemType.id,
                    rawCategory: category ?? '',
                    itemTypeObj: item.itemType,
                  );
                },
              ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'devices':
        return 'أجهزة POS';
      case 'sim':
        return 'شرائح SIM';
      case 'papers':
        return 'بكرات ورق';
      case 'accessories':
        return 'ملصقات';
      default:
        return 'عهدة عامة';
    }
  }

  Widget _buildCustodyLedgerCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String category,
    required Color categoryColor,
    required IconData categoryIcon,
    required int starting,
    required int received,
    required int executed,
    required int current,
    required List<String> serials,
    required String itemTypeId,
    required String rawCategory,
    required ItemType itemTypeObj,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          borderColor: categoryColor.withOpacity(0.15),
          onTap: () {
            Get.toNamed(
              Routes.inventorySectionDetails,
              arguments: {
                'itemType': itemTypeObj,
                'activeCount': current,
                'executedCount': executed,
                'serials': serials,
                'deliveredItems': dashboardController.deliveredItems
                    .where((si) => si['itemTypeId'] == itemTypeId)
                    .toList(),
                'activeItems': dashboardController.serializedItems
                    .where((si) =>
                        si['itemTypeId'] == itemTypeId &&
                        _isActiveCustodyStatus(si['status']))
                    .toList(),
              },
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Builder(builder: (ctx) {
                    final operatorImg = IconMapper.getItemImagePath(title, subtitle, rawCategory);
                    if (operatorImg != null) {
                      return Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: rawCategory == 'devices' ? Colors.transparent : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: categoryColor.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(operatorImg, fit: BoxFit.contain),
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: categoryColor.withOpacity(0.2)),
                      ),
                      child: Icon(categoryIcon, color: categoryColor, size: 24),
                    );
                  }),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontFamily: 'BeIN', 
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontFamily: 'BeIN', 
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ledger Balances Table
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildBalanceCell('الافتتاحي', starting.toString(), Colors.white60)),
                    _buildSeparator(),
                    Expanded(child: _buildBalanceCell('المستلم (+)', received.toString(), AppColors.success)),
                    _buildSeparator(),
                    Expanded(child: _buildBalanceCell('المنفذ (-)', executed.toString(), AppColors.error)),
                    _buildSeparator(),
                    Expanded(child: _buildBalanceCell('الحالي (كاش)', current.toString(), AppColors.primary, isBold: true)),
                  ],
                ),
              ),

              // Serial numbers list for devices & SIMs
              if (serials.isNotEmpty) ...[
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'عرض الأرقام التسلسلية ($current)',
                      style: TextStyle(fontFamily: 'BeIN', 
                        fontSize: 12,
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    dense: true,
                    iconColor: categoryColor,
                    collapsedIconColor: categoryColor.withOpacity(0.6),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: serials.map((serial) {
                            return Chip(
                              label: Text(
                                serial,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: Colors.white.withOpacity(0.06),
                              side: BorderSide(color: Colors.white.withOpacity(0.1)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Update Stock button for papers and accessories (consumables)
              if (rawCategory == 'papers' || rawCategory == 'accessories' || rawCategory == 'consumables') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: NeonButton(
                    label: 'تحديث مخزون $title',
                    icon: Icons.edit_note_outlined,
                    onPressed: () => _showUpdateStockDialog(
                      context,
                      title,
                      itemTypeId,
                      current,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCell(String label, String value, Color valueColor, {bool isBold = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'BeIN', fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withOpacity(0.08),
    );
  }

  void _showUpdateStockDialog(BuildContext context, String title, String itemTypeId, int currentVal) {
    final controller = TextEditingController(text: currentVal.toString());
    final isUpdating = false.obs;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'تحديث مخزون $title',
              style: TextStyle(fontFamily: 'BeIN', 
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
                  style: TextStyle(fontFamily: 'BeIN', color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الكمية (وحدات)',
                    labelStyle: TextStyle(fontFamily: 'BeIN', color: Colors.white38),
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
                  style: TextStyle(fontFamily: 'BeIN', color: Colors.white38),
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
                        'itemTypeId': itemTypeId,
                        'boxes': 0,
                        'units': qty,
                      },
                    );

                    Navigator.of(context).pop();
                    await dashboardController.refresh();

                    Get.snackbar(
                      'نجح',
                      'تم تحديث مخزون $title بنجاح ✓',
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
                        style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              )),
            ],
          ),
        );
      },
    );
  }
}
