import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../../../../core/routing/app_pages.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../../../received_devices/presentation/pages/custody_category_items_page.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final requestsController = Get.find<CourierRequestsController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Glowing color spot 1 (Top-Left primary brand cyan glow)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 120,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          // Glowing color spot 2 (Mid-Right accent purple glow)
          Positioned(
            top: 280,
            right: -80,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPurple.withValues(alpha: 0.08),
                    blurRadius: 100,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          Obx(() {
            if (controller.isLoading && controller.isInitialLoad) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (controller.error != null && controller.isInitialLoad) {
              return _buildErrorView();
            }

            final user = controller.user;
            if (user == null) {
              return _buildNoUserView();
            }

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await controller.refresh();
                  await requestsController.loadRequests();
                },
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Header
                        _buildWelcomeHeader(context, user),
                        const SizedBox(height: 20),

                        // Offline Sync Alert
                        _buildOfflineSyncBanner(),

                        // Daily Performance Dashboard
                        _buildDailyPerformanceTracker(requestsController),
                        const SizedBox(height: 24),

                        // Daily Stats Section
                        SectionHeader(
                          title: 'حالة الطلبات والتنفيذ اليومي',
                          icon: Icons.assignment_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        _buildOrderStatsGrid(context, requestsController),
                        const SizedBox(height: 24),

                        // Custody Section
                        SectionHeader(
                          title: 'العهدة الحالية (كشف الحساب)',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.accentPurple,
                          trailing: TextButton(
                            onPressed: () => Get.toNamed(Routes.serializedCustody),
                            child: Text(
                              'عرض التفاصيل',
                              style: TextStyle(fontFamily: 'BeIN', 
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCustodyOverviewList(),
                        const SizedBox(height: 24),

                        // Quick Actions
                        const SectionHeader(
                          title: 'الوصول السريع',
                          icon: Icons.electric_bolt_outlined,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(height: 8),
                        _buildQuickActionsRow(),
                        const SizedBox(height: 24),

                        // Last Notification
                        _buildLastNotificationBanner(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, dynamic user) {
    final String techCode = user.username.startsWith('T-') ? user.username : 'T-${user.username}';
    final isOnline = controller.pendingSyncCount == 0;
    const double avatarSize = 72;

    return Padding(
      padding: const EdgeInsets.only(top: avatarSize / 2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
            borderRadius: 20,
            borderColor: AppColors.primary.withValues(alpha: 0.28),
            shadows: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
            child: Column(
              children: [
                Text(
                  'صباح الخير، ${user.fullName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'BeIN',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'فني رقم: ',
                      style: TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      techCode,
                      style: const TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Builder(
                      builder: (ctx) => _WelcomeIconButton(
                        icon: Icons.menu_rounded,
                        tooltip: 'القائمة',
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOnline
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulsingDot(
                            color: isOnline ? AppColors.success : AppColors.warning,
                            size: 7,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'متصل' : 'أوفلاين',
                            style: TextStyle(
                              fontFamily: 'BeIN',
                              color: isOnline ? AppColors.success : AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _WelcomeIconButton(
                          icon: Icons.notifications_none_rounded,
                          tooltip: 'الإشعارات',
                          onTap: () => Get.toNamed(Routes.notifications),
                        ),
                        Obx(() {
                          final count = controller.pendingTransfersCount;
                          if (count == 0) return const SizedBox.shrink();
                          return Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontFamily: 'BeIN',
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logo avatar — dialog-style, half above the card
          Positioned(
            top: -(avatarSize / 2),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.primary, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/logo-1.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.business,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPerformanceTracker(CourierRequestsController requestsController) {
    final requests = requestsController.requests;
    final total = requests.length;
    final completed = requests.where((r) => r.installationStatus == 'COMPLETED' || r.installationStatus == 'SUCCESS').length;
    
    final displayTotal = total == 0 ? 8 : total;
    final displayCompleted = total == 0 ? 5 : completed;
    final percentage = (displayCompleted / displayTotal).clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.accentPurple.withValues(alpha: 0.2),
      shadows: [
        BoxShadow(
          color: AppColors.accentPurple.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معدل إنجاز المهام اليومية',
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تم إنجاز $displayCompleted من أصل $displayTotal طلبات زيارة اليوم',
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.gradientPurple),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: TextStyle(fontFamily: 'BeIN', 
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlowingProgressBar(
            value: percentage,
            color: AppColors.accentPurple,
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSyncBanner() {
    final count = controller.pendingSyncCount;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Color(0xFFB45309), size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تنبيه: أنت في وضع عدم الاتصال',
                      style: TextStyle(fontFamily: 'BeIN', 
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF78350F),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'لديك $count عمليات معلقة جاهزة للمزامنة',
                      style: TextStyle(fontFamily: 'BeIN', 
                        color: const Color(0xFF92400E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => controller.syncOfflineNow(),
              icon: const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
              label: Text(
                'مزامنة الآن',
                style: TextStyle(fontFamily: 'BeIN', 
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatsGrid(BuildContext context, CourierRequestsController requestsController) {
    final requests = requestsController.requests;

    final newOrders = requests.where((r) => r.installationStatus == 'ASSIGNED').length;
    final inProgressOrders = requests.where((r) => 
      r.installationStatus == 'ACCEPTED' || 
      r.installationStatus == 'RECEIVING' || 
      r.installationStatus == 'PARTIALLY_RECEIVED' || 
      r.installationStatus == 'RECEIVED' || 
      r.installationStatus == 'ON_ROUTE' || 
      r.installationStatus == 'ARRIVED' || 
      r.installationStatus == 'INSTALLING'
    ).length;

    final pendingVerification = requests.where((r) => r.installationStatus == 'COMPLETED').length;
    final completedToday = requests.where((r) => r.installationStatus == 'COMPLETED' || r.installationStatus == 'SUCCESS').length;

    final displayNew = newOrders;
    final displayInProgress = inProgressOrders;
    final displayPending = pendingVerification;
    final displayCompleted = completedToday;

    final int crossCount = context.isTabletDevice ? 4 : 2;
    final double aspectRatio = context.responsive(
      mobile: 1.20,
      tablet: 1.4,
      smallPhone: 1.10,
    );

    return GridView.count(
      crossAxisCount: crossCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      children: [
        _buildStatTile(
          context,
          title: 'طلبات جديدة',
          value: displayNew.toString(),
          icon: Icons.new_releases_outlined,
          color: AppColors.accentOrange,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
        _buildStatTile(
          context,
          title: 'طلبات تحت التنفيذ',
          value: displayInProgress.toString(),
          icon: Icons.play_circle_outline,
          color: AppColors.primary,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
        _buildStatTile(
          context,
          title: 'بانتظار التحقق',
          value: displayPending.toString(),
          icon: Icons.hourglass_empty_outlined,
          color: AppColors.accentPurple,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
        _buildStatTile(
          context,
          title: 'المهام المكتملة اليوم',
          value: displayCompleted.toString(),
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderColor: color.withValues(alpha: 0.15),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white24, size: 12),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustodyOverviewList() {
    final filtered = controller.filteredItems;
    final requestsController = Get.find<CourierRequestsController>();

    final papersQuantity = filtered
        .where((item) => item.itemType.category == 'papers' || item.itemType.nameAr.contains('ورق') || item.itemType.nameEn.toLowerCase().contains('paper'))
        .fold(0, (sum, item) => sum + item.totalQuantity);

    final stickersQuantity = filtered
        .where((item) => item.itemType.category == 'accessories' || item.itemType.nameAr.contains('ملصق') || item.itemType.nameEn.toLowerCase().contains('sticker'))
        .fold(0, (sum, item) => sum + item.totalQuantity);

    final dCount = filtered
        .where((item) => item.itemType.category == 'devices')
        .fold(0, (sum, item) => sum + item.movingUnits);
    final sCount = filtered
        .where((item) => item.itemType.category == 'sim')
        .fold(0, (sum, item) => sum + item.movingUnits);
    final pCount = papersQuantity;
    final stCount = stickersQuantity;

    final deviceItems = filtered
        .where((item) => item.itemType.category == 'devices')
        .toList();
    final simItems = filtered
        .where((item) => item.itemType.category == 'sim')
        .toList();

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        children: [
          _buildCustodyListTile(
            title: 'أجهزة POS',
            count: dCount,
            totalLimit: 15,
            icon: Icons.phone_android_rounded,
            color: AppColors.primary,
            isSerialized: true,
            onTap: () {
              Get.to(() => CustodyCategoryItemsPage(
                    title: 'قسم أجهزة POS',
                    rawCategory: 'devices',
                    items: deviceItems,
                    completedRequests: requestsController.requests
                        .where((r) => r.isCompleted)
                        .toList(),
                    dashboardController: controller,
                    requestsController: requestsController,
                  ));
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildCustodyListTile(
            title: 'شرائح SIM',
            count: sCount,
            totalLimit: 30,
            icon: Icons.sim_card_outlined,
            color: AppColors.success,
            isSerialized: true,
            onTap: () {
              Get.to(() => CustodyCategoryItemsPage(
                    title: 'قسم شرائح SIM',
                    rawCategory: 'sim',
                    items: simItems,
                    completedRequests: requestsController.requests
                        .where((r) => r.isCompleted)
                        .toList(),
                    dashboardController: controller,
                    requestsController: requestsController,
                  ));
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildCustodyListTile(
            title: 'بكرات ورق',
            count: pCount,
            totalLimit: 15,
            icon: Icons.receipt_long_outlined,
            color: AppColors.accentPurple,
            isSerialized: false,
            onTap: () => Get.toNamed(Routes.serializedCustody),
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildCustodyListTile(
            title: 'ملصقات دعائية',
            count: stCount,
            totalLimit: 40,
            icon: Icons.style_outlined,
            color: AppColors.accentOrange,
            isSerialized: false,
            onTap: () => Get.toNamed(Routes.serializedCustody),
          ),
        ],
      ),
    );
  }

  Widget _buildCustodyListTile({
    required String title,
    required int count,
    required int totalLimit,
    required IconData icon,
    required Color color,
    required bool isSerialized,
    required VoidCallback onTap,
  }) {
    final double fraction = (count / totalLimit).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(fontFamily: 'BeIN', 
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '/$totalLimit',
                            style: TextStyle(fontFamily: 'BeIN', 
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GlowingProgressBar(
                          value: fraction,
                          color: color,
                          height: 6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSerialized 
                              ? AppColors.primary.withValues(alpha: 0.1) 
                              : AppColors.textSecondary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSerialized ? 'رقم تسلسلي' : 'غير تسلسلي',
                          style: TextStyle(fontFamily: 'BeIN', 
                            fontSize: 9,
                            color: isSerialized ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: NeonButton(
                label: 'قائمة الطلبات',
                icon: Icons.list_alt,
                gradient: AppColors.gradientPrimary,
                onPressed: () => Get.toNamed(Routes.courierRequests),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeonButton(
                label: 'كشف العهدة',
                icon: Icons.account_balance_wallet_outlined,
                gradient: AppColors.gradientPurple,
                onPressed: () => Get.toNamed(Routes.serializedCustody),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NeonButton(
                label: 'استلام شحنة',
                icon: Icons.qr_code_scanner,
                gradient: AppColors.gradientSuccess,
                onPressed: () => Get.toNamed(Routes.shipmentScan),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NeonButton(
                label: 'أرقامي التسلسلية',
                icon: Icons.qr_code_sharp,
                gradient: const [Color(0xFF3F51B5), Color(0xFF2196F3)],
                onPressed: () => Get.toNamed(Routes.mySerializedInventory),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLastNotificationBanner() {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.info.withValues(alpha: 0.2),
      backgroundColor: AppColors.surfaceMid.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخر إشعار',
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تم إرسال عهدة جديدة لك من المستودع الرئيسي.',
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontSize: 13,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'منذ ٥ د',
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
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
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.error ?? 'حدث خطأ في تحميل البيانات',
              style: TextStyle(fontFamily: 'BeIN', 
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
                style: TextStyle(fontFamily: 'BeIN', 
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
          const Icon(
            Icons.person_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'يرجى تسجيل الدخول',
            style: TextStyle(fontFamily: 'BeIN', 
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
              style: TextStyle(fontFamily: 'BeIN', 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _WelcomeIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
