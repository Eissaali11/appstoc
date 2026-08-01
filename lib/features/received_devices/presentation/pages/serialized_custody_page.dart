import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../../../../core/routing/app_pages.dart';

import '../../../dashboard/presentation/pages/update_inventory_page.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../fixed_inventory/presentation/bindings/fixed_inventory_binding.dart';
import '../../../fixed_inventory/presentation/controllers/fixed_inventory_controller.dart';
import '../../../moving_inventory/presentation/bindings/moving_inventory_binding.dart';
import '../../../moving_inventory/presentation/controllers/moving_inventory_controller.dart';
import 'custody_category_items_page.dart';
import 'custody_confirm_receipt_page.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';

class SerializedCustodyPage extends StatefulWidget {
  const SerializedCustodyPage({super.key});

  @override
  State<SerializedCustodyPage> createState() => _SerializedCustodyPageState();
}

class _SerializedCustodyPageState extends State<SerializedCustodyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final requestsController = Get.find<CourierRequestsController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: RasscoAppBar(
        titleText: 'كشف حساب العهدة (Ledger)',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white),
            tooltip: 'تحديث المخزون يدوياً',
            onPressed: () => _showManualUpdateSelector(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white30,
          labelStyle: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'أرصدة العهدة'),
            Tab(text: 'استلام عهدة جديدة'),
            Tab(text: 'سجل العمليات'),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Obx(() {
          if (dashboardController.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBalancesTab(dashboardController, requestsController),
              _buildIntakeTab(dashboardController),
              _buildHistoryTab(dashboardController, requestsController),
            ],
          );
        }),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Get.toNamed(Routes.shipmentScan),
          backgroundColor: AppColors.success,
          elevation: 0,
          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
          label: Text(
            'استلام شحنة',
            style: TextStyle(fontFamily: 'BeIN', 
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Balances Tab ---
  Widget _buildBalancesTab(
      DashboardController dashboardController, CourierRequestsController requestsController) {
    final items = dashboardController.filteredItems;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await dashboardController.refresh();
          await requestsController.loadRequests();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: 400,
            alignment: Alignment.center,
            child: _buildEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'لا توجد عهدة حالية',
              description: 'رصيد عهدتك الحالية فارغ. يمكنك قبول الشحنات الواردة من المستودع لتظهر هنا.',
            ),
          ),
        ),
      );
    }

    final completedRequests = requestsController.requests
        .where((r) => r.isCompleted)
        .toList();

    // Group items by category
    final deviceItems = items.where((i) => i.itemType.category == 'devices').toList();
    final simItems = items.where((i) => i.itemType.category == 'sim').toList();
    final consumableItems = items.where((i) => i.itemType.category == 'papers' || i.itemType.category == 'accessories').toList();

    int getCategorySum(List<MergedInventoryItem> categoryItems) {
      int sum = 0;
      for (var item in categoryItems) {
        final itemTypeId = item.itemType.id;
        final category = item.itemType.category;

        if (category == 'devices' || category == 'sim') {
          final count = dashboardController.serializedItems
              .where((si) {
                final status = '${si['status'] ?? ''}'.toUpperCase();
                final active = status.isEmpty ||
                    status == 'RECEIVED_BY_TECHNICIAN' ||
                    status == 'IN_TRANSIT_CUSTODY' ||
                    status.contains('TRANSIT') ||
                    status.contains('RECEIVED');
                final delivered = status == 'DELIVERED' || status == 'RETURNED';
                return si['itemTypeId'] == itemTypeId && active && !delivered;
              })
              .length;
          sum += count;
        } else {
          sum += item.totalQuantity;
        }
      }
      return sum;
    }

    final deviceSum = getCategorySum(deviceItems);
    final simSum = getCategorySum(simItems);
    final consumableSum = getCategorySum(consumableItems);

    return RefreshIndicator(
      onRefresh: () async {
        await dashboardController.refresh();
        await requestsController.loadRequests();
      },
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header section description
          Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 4),
            child: Text(
              'أقسام العهدة الميدانية',
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // 1. Devices Section Card
          _buildCategorySummaryCard(
            title: 'قسم الأجهزة POS',
            subtitle: 'أجهزة نقاط البيع النشطة والمسلمة بالعهدة',
            icon: Icons.phone_android_rounded,
            color: AppColors.primary,
            count: deviceSum,
            imagePath: 'assets/1.png',
            onTap: () {
              Get.to(() => CustodyCategoryItemsPage(
                title: 'قسم أجهزة POS',
                rawCategory: 'devices',
                items: deviceItems,
                completedRequests: completedRequests,
                dashboardController: dashboardController,
                requestsController: requestsController,
              ));
            },
          ),
          const SizedBox(height: 16),

          // 2. SIM Cards Section Card
          _buildCategorySummaryCard(
            title: 'قسم شرائح SIM',
            subtitle: 'الشرائح المخصصة لتفعيل وتشغيل أجهزة نقاط البيع',
            icon: Icons.sim_card_outlined,
            color: AppColors.success,
            count: simSum,
            imagePath: 'assets/mobile.png',
            onTap: () {
              Get.to(() => CustodyCategoryItemsPage(
                title: 'قسم شرائح SIM',
                rawCategory: 'sim',
                items: simItems,
                completedRequests: completedRequests,
                dashboardController: dashboardController,
                requestsController: requestsController,
              ));
            },
          ),
          const SizedBox(height: 16),

          // 3. Consumables Section Card
          _buildCategorySummaryCard(
            title: 'ورق، بطاريات وملصقات',
            subtitle: 'المستندات، الورق الحراري، والملصقات الدعائية',
            icon: Icons.inventory_2_outlined,
            color: AppColors.accentPurple,
            count: consumableSum,
            imagePath: 'assets/mol.png',
            onTap: () {
              Get.to(() => CustodyCategoryItemsPage(
                title: 'ورق، بطاريات وملصقات',
                rawCategory: 'consumables',
                items: consumableItems,
                completedRequests: completedRequests,
                dashboardController: dashboardController,
                requestsController: requestsController,
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySummaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
    String? imagePath,
  }) {
    return GlassCard(
      borderColor: color.withOpacity(0.2),
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: [
          // Icon with Neon background or logo image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: imagePath != null && title.contains('الأجهزة') ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: -2,
                )
              ]
            ),
            padding: imagePath != null ? const EdgeInsets.all(6) : const EdgeInsets.all(14),
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  )
                : Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 18),
          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
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
          // Arrow + Count badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Text(
                  '$count وحدات',
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
            ],
          )
        ],
      ),
    );
  }





  // --- 2. Intake (Warehouse Transfers) Tab ---
  Widget _buildIntakeTab(DashboardController dashboardController) {
    final pendingTransfers = dashboardController.pendingTransfers
        .where((t) => t.status == 'pending')
        .toList();

    final acceptedTransfers = dashboardController.pendingTransfers
        .where((t) => t.status == 'accepted')
        .toList();

    if (pendingTransfers.isEmpty && acceptedTransfers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'لا توجد شحنات معلقة',
        description: 'جميع الشحنات المرسلة من المستودع تم قبولها أو التعامل معها بنجاح.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => dashboardController.refresh(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pendingTransfers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 4),
              child: Text(
                'شحنات بانتظار القبول (${pendingTransfers.length})',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            ...pendingTransfers.map((t) => _buildTransferCard(context, dashboardController, t, false)),
            const SizedBox(height: 16),
          ],
          if (acceptedTransfers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 4, top: 8),
              child: Text(
                'شحنات مقبولة بانتظار التوثيق والاستلام (${acceptedTransfers.length})',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            ...acceptedTransfers.map((t) => _buildTransferCard(context, dashboardController, t, true)),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferCard(
      BuildContext context,
      DashboardController dashboardController,
      WarehouseTransfer transfer,
      bool isAccepted) {
    final itemTypeName =
        dashboardController.itemTypesMap[transfer.itemType]?.nameAr ?? transfer.itemType;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      borderColor: isAccepted
          ? AppColors.success.withOpacity(0.2)
          : AppColors.accentOrange.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAccepted
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.accentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warehouse_outlined,
                      color: isAccepted ? AppColors.success : AppColors.accentOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemTypeName,
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'المصدر: ${transfer.warehouseName ?? "المستودع الرئيسي"}',
                        style: TextStyle(fontFamily: 'BeIN', 
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                isAccepted ? 'بانتظار التوثيق' : 'بانتظار القبول',
                style: TextStyle(fontFamily: 'BeIN', 
                  color: isAccepted ? AppColors.success : AppColors.accentOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الكمية المرسلة',
                    style: TextStyle(fontFamily: 'BeIN', fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    '${transfer.quantity} ${transfer.packagingType == "boxes" ? "كرتون" : "وحدة"}',
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('yyyy/MM/dd - HH:mm').format(transfer.createdAt),
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ملاحظات: ${transfer.notes}',
                style: TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!isAccepted)
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'قبول طلب النقل',
                    icon: Icons.check,
                    gradient: AppColors.gradientSuccess,
                    onPressed: () => dashboardController.acceptTransfer(transfer.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, dashboardController, transfer.id),
                    icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                    label: Text(
                      'رفض',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            NeonButton(
              label: 'توثيق وتأكيد الاستلام',
              icon: Icons.qr_code_scanner,
              gradient: AppColors.gradientPrimary,
              onPressed: () => Get.to(() => CustodyConfirmReceiptPage(transfer: transfer)),
            ),
        ],
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, DashboardController controller, String transferId) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'رفض شحنة العهدة',
          style: TextStyle(fontFamily: 'BeIN', 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.right,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يرجى كتابة سبب رفض استلام هذه العهدة:',
              style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
              decoration: InputDecoration(
                hintText: 'مثال: نقص في الكمية / تالف...',
                hintStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar('تنبيه', 'يجب إدخال سبب الرفض',
                    backgroundColor: Colors.amber, colorText: Colors.black);
                return;
              }
              Get.back();
              controller.rejectTransfer(transferId, reason: reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'تأكيد الرفض',
              style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. History Tab ---
  Widget _buildHistoryTab(
      DashboardController dashboardController, CourierRequestsController requestsController) {
    // Collect simulated + real history logs
    final logs = <_LedgerLog>[];

    // 1. Add completed requests
    final completedRequests = requestsController.requests
        .where((r) => r.isCompleted)
        .toList();

    for (var r in completedRequests) {
      final dateParsed = DateTime.tryParse(r.date ?? '') ?? DateTime.now().subtract(const Duration(hours: 4));
      logs.add(_LedgerLog(
        title: 'تسليم عهدة للعميل (Scan-Out)',
        details: 'توصيل وتركيب جهاز POS رقم TID: ${r.tid ?? "غير معروف"} للعميل: ${r.customerName ?? r.retailerName ?? "عميل"}',
        time: dateParsed,
        isPositive: false,
      ));
    }

    // 2. Add accepted transfers
    final acceptedTransfers = dashboardController.pendingTransfers
        .where((t) => t.status == 'accepted')
        .toList();

    for (var t in acceptedTransfers) {
      final name = dashboardController.itemTypesMap[t.itemType]?.nameAr ?? t.itemType;
      logs.add(_LedgerLog(
        title: 'استلام عهدة من المستودع (Scan-In)',
        details: 'قبول شحنة $name بعدد ${t.quantity} وحدة من ${t.warehouseName ?? "المستودع"}',
        time: t.createdAt,
        isPositive: true,
      ));
    }

    // Sort by time descending
    logs.sort((a, b) => b.time.compareTo(a.time));

    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا يوجد سجل عهدة حالياً',
            style: TextStyle(fontFamily: 'BeIN', color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Column
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: log.isPositive ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: log.isPositive ? AppColors.success : AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    log.isPositive ? Icons.add_rounded : Icons.remove_rounded,
                    color: log.isPositive ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                ),
                if (index != logs.length - 1)
                  Container(
                    width: 1.5,
                    height: 50,
                    color: Colors.white10,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Card details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderColor: Colors.white.withOpacity(0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: 'BeIN', 
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MM/dd HH:mm').format(log.time),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        log.details,
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Helper Helpers ---
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  void _showManualUpdateSelector(BuildContext context) {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تحديث العهدة يدوياً',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'اختر نوع المخزون الذي ترغب في تعديل كمياته (مثل ورق الطباعة والملصقات الدعائية)',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildUpdateOptionCard(
                      title: 'المخزون الثابت',
                      subtitle: 'ورق الطباعة والأجهزة الثابتة',
                      icon: Icons.inventory_2,
                      color: AppColors.primary,
                      onTap: () async {
                        Get.back();
                        if (!Get.isRegistered<FixedInventoryController>()) {
                          FixedInventoryBinding().dependencies();
                        }
                        final fixedController = Get.find<FixedInventoryController>();
                        Get.dialog(
                          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          barrierDismissible: false,
                        );
                        await fixedController.loadData();
                        Get.back();
                        Get.to(
                          () => UpdateInventoryPage(
                            currentInventory: fixedController.inventory.map((e) => InventoryEntry(
                              itemTypeId: e.itemTypeId,
                              boxes: e.boxes,
                              units: e.units,
                            )).toList(),
                            itemTypes: fixedController.itemTypes,
                            inventoryType: 'fixed',
                            onSave: (entries) => fixedController.updateInventory(entries.map((e) => InventoryEntry(
                              itemTypeId: e.itemTypeId,
                              boxes: e.boxes,
                              units: e.units,
                            )).toList()),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildUpdateOptionCard(
                      title: 'المخزون المتحرك',
                      subtitle: 'الملصقات والأجهزة المتحركة',
                      icon: Icons.local_shipping,
                      color: AppColors.accentPurple,
                      onTap: () async {
                        Get.back();
                        if (!Get.isRegistered<MovingInventoryController>()) {
                          MovingInventoryBinding().dependencies();
                        }
                        final movingController = Get.find<MovingInventoryController>();
                        Get.dialog(
                          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          barrierDismissible: false,
                        );
                        await movingController.loadData();
                        Get.back();
                        Get.to(
                          () => UpdateInventoryPage(
                            currentInventory: movingController.inventory.map((e) => InventoryEntry(
                              itemTypeId: e.itemTypeId,
                              boxes: e.boxes,
                              units: e.units,
                            )).toList(),
                            itemTypes: movingController.itemTypes,
                            inventoryType: 'moving',
                            onSave: (entries) => movingController.updateInventory(entries.map((e) => InventoryEntry(
                              itemTypeId: e.itemTypeId,
                              boxes: e.boxes,
                              units: e.units,
                            )).toList()),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildUpdateOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      borderColor: color.withOpacity(0.2),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _LedgerLog {
  final String title;
  final String details;
  final DateTime time;
  final bool isPositive;

  _LedgerLog({
    required this.title,
    required this.details,
    required this.time,
    required this.isPositive,
  });
}
