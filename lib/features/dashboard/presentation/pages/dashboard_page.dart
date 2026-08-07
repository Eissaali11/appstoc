import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../../../../core/routing/app_pages.dart';
import '../../../received_devices/presentation/pages/custody_category_items_page.dart';
import '../../../../shared/services/custody_sound_service.dart';
import '../../../../shared/scanner/identifier_normalization_service.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/custody_delete_confirmation_dialog.dart';

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
                        // 1. Welcome Header
                        _buildWelcomeHeader(context, user),
                        const SizedBox(height: 14),

                        // 2. Interactive Custody Lookup Search Card
                        DashboardCustodySearchCard(controller: controller),
                        const SizedBox(height: 10),

                        // 3. Compact Horizontal Quick Actions (الوصول السريع التفاعلي)
                        _buildHorizontalCompactQuickActions(),
                        const SizedBox(height: 8),

                        // 4. Compact Horizontal Order Stats (حالة الطلبات والتنفيذ اليومي)
                        _buildOrderStatsHorizontalStrip(requestsController),
                        const SizedBox(height: 10),

                        // 5. Offline Sync Alert
                        _buildOfflineSyncBanner(),

                        // 6. Custody Overview Section (العهدة الحالية - كشف الحساب)
                        _buildHighlightedSectionHeader(
                          title: 'العهدة الحالية (كشف الحساب)',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.accentPurple,
                          trailing: TextButton(
                            onPressed: () => Get.toNamed(Routes.serializedCustody),
                            child: const Text(
                              'عرض التفاصيل',
                              style: TextStyle(
                                fontFamily: 'BeIN', 
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        _buildCustodyOverviewList(),
                        const SizedBox(height: 16),

                        // 7. Daily Performance Tracker (معدل الإنجاز اليومي)
                        _buildDailyPerformanceTracker(requestsController),
                        const SizedBox(height: 16),

                        // 8. Last Notification Banner
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

  Widget _buildHighlightedSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'BeIN',
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (trailing != null) trailing,
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.25), width: 1),
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
                        style: const TextStyle(
                          fontFamily: 'BeIN', 
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              fontFamily: 'BeIN', 
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '/$totalLimit',
                            style: TextStyle(
                              fontFamily: 'BeIN', 
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Node circle indicator next to progress line extension
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.7),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GlowingProgressBar(
                          value: fraction,
                          color: color,
                          height: 7,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSerialized 
                              ? AppColors.primary.withOpacity(0.12) 
                              : AppColors.textSecondary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSerialized ? AppColors.primary.withOpacity(0.3) : Colors.white10,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSerialized ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSerialized ? 'رقم تسلسلي' : 'غير تسلسلي',
                              style: TextStyle(
                                fontFamily: 'BeIN', 
                                fontSize: 9.5,
                                color: isSerialized ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildHorizontalCompactQuickActions() {
    final actions = [
      _QuickActionItem(
        label: 'قائمة الطلبات',
        icon: Icons.list_alt_rounded,
        color: AppColors.primary,
        onTap: () => Get.toNamed(Routes.courierRequests),
      ),
      _QuickActionItem(
        label: 'كشف العهدة',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.accentPurple,
        onTap: () => Get.toNamed(Routes.serializedCustody),
      ),
      _QuickActionItem(
        label: 'استلام شحنة',
        icon: Icons.qr_code_scanner_rounded,
        color: AppColors.success,
        onTap: () => Get.toNamed(Routes.shipmentScan),
      ),
      _QuickActionItem(
        label: 'أرقامي التسلسلية',
        icon: Icons.qr_code_2_rounded,
        color: const Color(0xFF3F51B5),
        onTap: () => Get.toNamed(Routes.mySerializedInventory),
      ),
      _QuickActionItem(
        label: 'المستودع والنقل',
        icon: Icons.swap_horiz_rounded,
        color: AppColors.accentOrange,
        onTap: () => Get.toNamed(Routes.movingInventory),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = actions[index];
          return InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.color.withOpacity(0.35),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'BeIN',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderStatsHorizontalStrip(CourierRequestsController requestsController) {
    return Obx(() {
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

      final stats = [
        _OrderStatusItem(
          title: 'طلبات جديدة',
          count: newOrders,
          icon: Icons.new_releases_outlined,
          color: AppColors.accentOrange,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
        _OrderStatusItem(
          title: 'تحت التنفيذ',
          count: inProgressOrders,
          icon: Icons.play_circle_outline,
          color: AppColors.primary,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
        _OrderStatusItem(
          title: 'بانتظار التحقق',
          count: pendingVerification,
          icon: Icons.hourglass_empty_outlined,
          color: AppColors.accentPurple,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
        _OrderStatusItem(
          title: 'المهام المكتملة اليوم',
          count: completedToday,
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          onTap: () => Get.toNamed(Routes.courierRequests),
        ),
      ];

      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = stats[index];
            return InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.color.withOpacity(0.35),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 15),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // High-contrast Count Badge Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        '${item.count}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
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

class DashboardCustodySearchCard extends StatefulWidget {
  final DashboardController controller;
  const DashboardCustodySearchCard({super.key, required this.controller});

  @override
  State<DashboardCustodySearchCard> createState() => _DashboardCustodySearchCardState();
}

class _DashboardCustodySearchCardState extends State<DashboardCustodySearchCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCameraScanner() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: BarcodeScannerWidget(
                title: 'امسح باركود الجهاز أو الشريحة',
                isMultiScan: false,
                allowUnionOfItemTypes: true,
                onBarcodeDetected: (barcode) {
                  Get.back();
                  _searchController.text = barcode;
                  _performLookup(barcode);
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _performLookup(String rawInput) async {
    final clean = IdentifierNormalizationService.normalize(rawInput);
    if (clean.isEmpty) return;

    final controller = widget.controller;

    // 1. Search Active Custody
    final activeSerialized = controller.serializedItems;
    final foundActive = activeSerialized.firstWhereOrNull((item) {
      final s = (item['serialNumber'] ?? item['serial_number'] ?? item['iccid'] ?? '')
          .toString()
          .toUpperCase();
      return s == clean || s.endsWith(clean) || clean.endsWith(s);
    });

    // 2. Search Delivered Items
    final deliveredItems = controller.deliveredItems;
    final foundDelivered = deliveredItems.firstWhereOrNull((item) {
      final s = (item['serialNumber'] ?? item['serial_number'] ?? item['iccid'] ?? '')
          .toString()
          .toUpperCase();
      return s == clean || s.endsWith(clean) || clean.endsWith(s);
    });

    // 3. Search Pending Transfers
    final pendingTransfers = controller.pendingTransfers;
    final foundPending = pendingTransfers.firstWhereOrNull((t) {
      return t.id.toUpperCase() == clean ||
          (t.requestId != null && t.requestId!.toUpperCase() == clean);
    });

    if (foundActive != null) {
      // 🟢 1. في عهدة الفني (نشط)
      await CustodySoundService.playSuccessBell();
      if (!mounted) return;
      _showLookupResultModal(
        statusType: _CustodyStatusType.inCustody,
        serialNumber: clean,
        itemTitle: _resolveItemTypeName(foundActive['itemTypeId']?.toString()),
        statusLabel: 'في عهدة الفني (متحرك / نشط)',
        detailsMap: foundActive,
      );
    } else if (foundDelivered != null) {
      // 🔵 2. مُسلّم للعميل
      await CustodySoundService.playSuccessBell();
      if (!mounted) return;
      _showLookupResultModal(
        statusType: _CustodyStatusType.delivered,
        serialNumber: clean,
        itemTitle: _resolveItemTypeName(foundDelivered['itemTypeId']?.toString()),
        statusLabel: 'تم تسليمه سابقاً للعميل',
        detailsMap: foundDelivered,
      );
    } else if (foundPending != null) {
      // 🟡 3. غير مُسلّم (في قائمة النقل / المعلق)
      await CustodySoundService.playWarningBell();
      if (!mounted) return;
      _showLookupResultModal(
        statusType: _CustodyStatusType.pending,
        serialNumber: clean,
        itemTitle: 'شحنة / عهدة قيد النقل والانتظار',
        statusLabel: 'غير مُسلّم (في انتظار تأكيد الاستلام)',
      );
    } else {
      // 🔴 4. غير موجود في عهدة الفني
      await CustodySoundService.playWarningBell();
      if (!mounted) return;
      _showLookupResultModal(
        statusType: _CustodyStatusType.notFound,
        serialNumber: clean,
        itemTitle: 'رقم تسلسلي غير مدرج بالحساب',
        statusLabel: 'غير موجود في عهدتك الحالية',
        allowAddToCustody: true,
      );
    }
  }

  String _resolveItemTypeName(String? itemTypeId) {
    if (itemTypeId == null) return 'جهاز / شريحة عهدة';
    final type = widget.controller.itemTypesMap[itemTypeId];
    if (type != null) {
      return type.nameAr.isNotEmpty ? type.nameAr : type.nameEn;
    }
    return 'جهاز / شريحة عهدة';
  }

  // TEMPORARY FEATURE — remove or disable after final customer handover.
  // Maps an item's category to the backend's itemType URL segment (DEVICE|SIM).
  // Defaults to DEVICE for any non-SIM category, since only devices and SIMs are
  // ever serialized/shown in this custody lookup.
  String _resolveCustodyDeleteItemType(String? itemTypeId) {
    final category = itemTypeId != null
        ? widget.controller.itemTypesMap[itemTypeId]?.category
        : null;
    return category == 'sim' ? 'SIM' : 'DEVICE';
  }

  void _showLookupResultModal({
    required _CustodyStatusType statusType,
    required String serialNumber,
    required String itemTitle,
    required String statusLabel,
    Map<String, dynamic>? detailsMap,
    bool allowAddToCustody = false,
  }) {
    Color cardColor;
    IconData icon;
    String mainTitle;

    switch (statusType) {
      case _CustodyStatusType.inCustody:
        cardColor = AppColors.success; // 🟢
        icon = Icons.check_circle_rounded;
        mainTitle = 'في عهدة الفني (نشط)';
        break;
      case _CustodyStatusType.delivered:
        cardColor = Colors.lightBlueAccent; // 🔵
        icon = Icons.assignment_turned_in_rounded;
        mainTitle = 'مُسلّم للعميل';
        break;
      case _CustodyStatusType.pending:
        cardColor = AppColors.warning; // 🟡
        icon = Icons.hourglass_top_rounded;
        mainTitle = 'غير مُسلّم (قيد الانتظار)';
        break;
      case _CustodyStatusType.notFound:
        cardColor = AppColors.error; // 🔴
        icon = Icons.highlight_off_rounded;
        mainTitle = 'غير موجود في عهدتك';
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: cardColor, width: 2),
                ),
                child: Icon(icon, color: cardColor, size: 44),
              ),
              const SizedBox(height: 14),
              Text(
                mainTitle,
                style: TextStyle(
                  fontFamily: 'BeIN',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  serialNumber,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 10),
              _buildModalRow('اسم الصنف:', itemTitle, Icons.inventory_2_outlined),
              const SizedBox(height: 10),
              _buildModalRow('الحالة الحالية:', statusLabel, Icons.verified_outlined, textColor: cardColor),
              const SizedBox(height: 24),
              
              if (allowAddToCustody) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await widget.controller.addSerialToCustody(serialNumber);
                      _searchController.clear();
                      await CustodySoundService.playSuccessBell();
                      if (!mounted) return;
                      await showCustodySuccessDialog(
                        context,
                        title: 'تمت الإضافة بنجاح',
                        message: 'تم إضافة الرقم $serialNumber بنجاح إلى عهدتك النشطة وتحديث الحساب.',
                      );
                    },
                    icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                    label: const Text(
                      'إضافة وتأكيد إلى عهدتي الآن',
                      style: TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: const Text(
                    'إغلاق',
                    style: TextStyle(
                      fontFamily: 'BeIN',
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // TEMPORARY FEATURE — remove or disable after final customer handover.
              if (_isTechnicianUser()) ...[
                Builder(builder: (_) {
                  final custodyItemType = _resolveCustodyDeleteItemType(
                    detailsMap?['itemTypeId']?.toString(),
                  );
                  final isSim = custodyItemType == 'SIM';
                  final enabled = statusType == _CustodyStatusType.inCustody;
                  return Column(
                    children: [
                      const SizedBox(height: 22),
                      Divider(color: Colors.white.withOpacity(0.08)),
                      const SizedBox(height: 14),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: enabled
                              ? () => _handleDeleteFromCustody(
                                    ctx: ctx,
                                    itemType: custodyItemType,
                                    serialNumber: serialNumber,
                                    itemTitle: itemTitle,
                                    statusLabel: statusLabel,
                                    detailsMap: detailsMap,
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: enabled
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFEF4444),
                                        Color(0xFFB91C1C),
                                      ],
                                    )
                                  : null,
                              color: enabled ? null : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: enabled
                                    ? const Color(0xFFEF4444)
                                    : Colors.white12,
                                width: 1.5,
                              ),
                              boxShadow: enabled
                                  ? [
                                      BoxShadow(
                                        color: AppColors.error.withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  color: enabled ? Colors.white : Colors.white24,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isSim
                                          ? 'حذف الشريحة من عهدتي نهائيًا'
                                          : 'حذف الجهاز من عهدتي نهائيًا',
                                      style: TextStyle(
                                        fontFamily: 'BeIN',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: enabled ? Colors.white : Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enabled
                            ? 'تحذير: عملية نهائية لا يمكن التراجع عنها'
                            : 'لا يمكنك حذف جهاز غير موجود في عهدتك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'BeIN',
                          fontSize: 11.5,
                          color: enabled
                              ? AppColors.error.withOpacity(0.85)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  // TEMPORARY FEATURE — remove or disable after final customer handover.
  bool _isTechnicianUser() {
    try {
      return Get.find<AuthController>().user?.role == 'technician';
    } catch (_) {
      return false;
    }
  }

  // TEMPORARY FEATURE — remove or disable after final customer handover.
  Future<void> _handleDeleteFromCustody({
    required BuildContext ctx,
    required String itemType,
    required String serialNumber,
    required String itemTitle,
    required String statusLabel,
    Map<String, dynamic>? detailsMap,
  }) async {
    // Close the lookup result sheet first; the confirmation dialog is shown
    // on the page's own (still-mounted) context.
    Navigator.pop(ctx);

    final authController = Get.find<AuthController>();
    final receivedAt = detailsMap?['createdAt']?.toString();
    final isSim = itemType == 'SIM';

    final deleted = await showCustodyDeleteConfirmationDialog(
      context,
      serialNumber: serialNumber,
      itemTitle: itemTitle,
      itemCategoryLabel: isSim ? 'شريحة' : 'جهاز',
      statusLabel: statusLabel,
      ownerLabel: authController.user?.username != null
          ? 'أنت (${authController.user!.username})'
          : 'أنت',
      receivedAtLabel: receivedAt,
      onConfirmDelete: () => widget.controller.deleteSerialFromCustody(
        itemType,
        serialNumber,
        serialNumber,
      ),
    );

    if (!deleted) return;
    if (!mounted) return;

    _searchController.clear();
    await CustodySoundService.playSuccessBell();
    await showCustodySuccessDialog(
      context,
      title: 'تم الحذف بنجاح',
      message: isSim
          ? 'تم حذف الشريحة من عهدتك وتحديث بيانات المخزون بنجاح.'
          : 'تم حذف الجهاز من عهدتك وتحديث بيانات المخزون بنجاح.',
    );
  }

  Widget _buildModalRow(String label, String value, IconData icon, {Color? textColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BeIN',
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'BeIN',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      borderColor: AppColors.primary.withOpacity(0.35),
      shadows: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.manage_search_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'مستكشف الفحص والعهد الفوري',
                    style: TextStyle(
                      fontFamily: 'BeIN',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_strong_rounded, color: AppColors.primary, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'يدوي + مسح',
                      style: TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (val) => _performLookup(val),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'أدخل الرقم التسلسلي / الـ ICCID...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  final text = _searchController.text.trim();
                  if (text.isNotEmpty) {
                    _performLookup(text);
                  } else {
                    _openCameraScanner();
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.white38, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'أدخل الرقم يدوياً أو اضغط أيقونة الماسح للفحص بالكاميرا مع التنبيه الصوتي',
                  style: TextStyle(
                    fontFamily: 'BeIN',
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _CustodyStatusType {
  inCustody,  // 🟢 في عهدة الفني
  delivered,  // 🔵 مسلم
  pending,    // 🟡 غير مسلم (قيد الانتظار)
  notFound,   // 🔴 غير موجود
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _OrderStatusItem {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _OrderStatusItem({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
