import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/design_system.dart';
import '../controllers/courier_requests_controller.dart';
import '../../data/models/courier_request_model.dart';

class CourierRequestsPage extends StatefulWidget {
  const CourierRequestsPage({super.key});

  @override
  State<CourierRequestsPage> createState() => _CourierRequestsPageState();
}

class _CourierRequestsPageState extends State<CourierRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourierRequestsController controller =
      Get.find<CourierRequestsController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CourierRequest> _filterRequests(
      List<CourierRequest> list, int tabIndex) {
    if (tabIndex == 0) return list;
    if (tabIndex == 1) {
      return list
          .where((r) =>
              (r.installationStatus ?? '').toUpperCase() == 'ASSIGNED')
          .toList();
    }
    if (tabIndex == 2) {
      return list.where((r) {
        final s = (r.installationStatus ?? '').toUpperCase();
        return s == 'ACCEPTED' ||
            s == 'RECEIVING' ||
            s == 'PARTIALLY_RECEIVED' ||
            s == 'RECEIVED' ||
            s == 'ON_ROUTE' ||
            s == 'ARRIVED' ||
            s == 'INSTALLING';
      }).toList();
    }
    if (tabIndex == 3) {
      return list.where((r) {
        final s = (r.installationStatus ?? '').toUpperCase();
        return s.contains('COMPLETED') ||
            s == 'SUCCESS' ||
            s == 'FAILED' ||
            s == 'REJECTED';
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading && controller.requests.isEmpty) {
          return _buildLoadingState();
        }
        if (controller.error != null) {
          return _buildErrorState();
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadRequests(),
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          child: TabBarView(
            controller: _tabController,
            children: List.generate(4, (index) {
              final filtered =
                  _filterRequests(controller.requests, index);
              if (filtered.isEmpty) return _buildEmptyState(index);
              return _buildRequestList(filtered);
            }),
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final _tabs = [
      _TabInfo('الكل', Icons.list_alt),
      _TabInfo('بانتظار القبول', Icons.pending_actions),
      _TabInfo('قيد المعالجة', Icons.local_shipping),
      _TabInfo('المنتهية', Icons.check_circle_outline),
    ];

    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طلبات التوصيل',
            style: TextStyle(fontFamily: 'BeIN', 
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          Obx(() => Text(
                '${controller.requests.length} طلب إجمالاً',
                style: TextStyle(fontFamily: 'BeIN', 
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              )),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => controller.loadRequests(),
          icon: Obx(() => controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh, color: AppColors.primary)),
          tooltip: 'تحديث',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: AppColors.surfaceDark,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelStyle:
                TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontFamily: 'BeIN', fontSize: 12),
            tabs: _tabs
                .map((t) => Tab(
                      child: Row(
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _ShimmerEffect(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: AppColors.error, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'تعذر تحميل الطلبات',
            style: TextStyle(fontFamily: 'BeIN', 
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            controller.error ?? 'خطأ في الاتصال بالخادم',
            style:
                TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'إعادة المحاولة',
            icon: Icons.refresh,
            onPressed: () => controller.loadRequests(),
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final messages = [
      'لا توجد طلبات حالياً',
      'لا توجد طلبات بانتظار قبولك',
      'لا توجد طلبات قيد المعالجة',
      'لا توجد طلبات منتهية',
    ];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tabIndex == 1
                ? Icons.inbox_outlined
                : tabIndex == 2
                    ? Icons.local_shipping_outlined
                    : Icons.done_all,
            size: 72,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            messages[tabIndex],
            style: TextStyle(fontFamily: 'BeIN', 
                color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<CourierRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: requests.length,
      itemBuilder: (context, idx) => _buildRequestCard(requests[idx]),
    );
  }

  Widget _buildRequestCard(CourierRequest request) {
    final status = (request.installationStatus ?? '').toUpperCase();
    final statusColor = AppColors.statusColor(request.installationStatus);
    final isPendingAccept = status == 'ASSIGNED';
    final isActive = status == 'ACCEPTED' ||
        status == 'RECEIVING' ||
        status == 'PARTIALLY_RECEIVED' ||
        status == 'RECEIVED' ||
        status == 'ON_ROUTE' ||
        status == 'ARRIVED' ||
        status == 'INSTALLING';

    return GestureDetector(
      onTap: () =>
          Get.toNamed('/courier-request-details', arguments: request.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceMid,
              AppColors.surfaceDark,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPendingAccept
                ? AppColors.warning.withOpacity(0.5)
                : statusColor.withOpacity(0.25),
            width: isPendingAccept ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPendingAccept
                  ? AppColors.warning.withOpacity(0.15)
                  : Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top color accent strip
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.3)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPendingAccept
                                ? Icons.pending_actions
                                : isActive
                                    ? Icons.local_shipping
                                    : Icons.check_circle_outline,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب #${request.id}',
                                style: TextStyle(fontFamily: 'BeIN', 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              if (request.date != null)
                                Text(
                                  request.date!,
                                  style: TextStyle(fontFamily: 'BeIN', 
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          text: request.statusText,
                          color: statusColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 12),

                    // Details
                    _buildInfoRow(
                        Icons.storefront_outlined,
                        request.retailerName ?? request.customerName ?? 'غير محدد'),
                    _buildInfoRow(
                        Icons.location_on_outlined,
                        '${request.city ?? ''} — ${request.addressAr ?? request.addressEn ?? 'غير محدد'}'),
                    _buildInfoRow(
                        Icons.settings_applications,
                        request.installationType ?? 'تركيب جديد'),

                    if (isPendingAccept) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            PulsingDot(color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(
                              'بانتظار قبولك — اضغط لعرض التفاصيل',
                              style: TextStyle(fontFamily: 'BeIN', 
                                  color: AppColors.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'عرض التفاصيل',
                            style: TextStyle(fontFamily: 'BeIN', 
                                color: AppColors.primary, fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios,
                              size: 12, color: AppColors.primary),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'BeIN', 
                  color: AppColors.textSecondary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}

// Simple shimmer placeholder
class _ShimmerEffect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMid.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
