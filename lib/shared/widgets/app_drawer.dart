import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_pages.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'user_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentRoute = Get.currentRoute;

    return Drawer(
      backgroundColor: AppColors.surfaceDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header with App Logo + User Info
            Obx(() {
              final user = authController.user;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  children: [
                    UserAvatar(
                      profileImage: user?.profileImage,
                      size: 64,
                      borderWidth: 1.5,
                      borderColor: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(width: 16),
                    // User name and app name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.fullName ?? 'drawer_user_default'.tr,
                            style: TextStyle(fontFamily: 'BeIN', 
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user?.username ?? 'stockpro'}',
                            style: TextStyle(fontFamily: 'BeIN', 
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'drawer_badge'.tr,
                                  style: TextStyle(fontFamily: 'BeIN', 
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // --- 1. الرئيسية والزيارات ---
                  _buildSectionHeader('drawer_sec_home_orders'.tr),
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'drawer_dashboard'.tr,
                    route: Routes.dashboard,
                    isActive: currentRoute == Routes.dashboard,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_outlined,
                    title: 'drawer_courier_requests'.tr,
                    route: Routes.courierRequests,
                    isActive: currentRoute == Routes.courierRequests,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),

                  // --- 2. إدارة العهدة والمخزون ---
                  _buildSectionHeader('drawer_sec_custody'.tr),
                  _DrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'drawer_serialized_custody'.tr,
                    route: Routes.serializedCustody,
                    isActive: currentRoute == Routes.serializedCustody,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'drawer_fixed_inventory'.tr,
                    route: Routes.fixedInventory,
                    isActive: currentRoute == Routes.fixedInventory,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'drawer_moving_inventory'.tr,
                    route: Routes.movingInventory,
                    isActive: currentRoute == Routes.movingInventory,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.list_alt_outlined,
                    title: 'drawer_inventory_list'.tr,
                    route: Routes.inventoryList,
                    isActive: currentRoute == Routes.inventoryList,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),

                  // --- 3. العمليات والمسح ---
                  _buildSectionHeader('drawer_sec_operations'.tr),
                  _DrawerItem(
                    icon: Icons.qr_code_scanner,
                    title: 'drawer_shipment_scan'.tr,
                    route: Routes.shipmentScan,
                    isActive: currentRoute == Routes.shipmentScan,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.add_to_photos_outlined,
                    title: 'drawer_submit_device'.tr,
                    route: Routes.submitDevice,
                    isActive: currentRoute == Routes.submitDevice,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.move_to_inbox_outlined,
                    title: 'drawer_device_handover'.tr,
                    route: Routes.deviceHandover,
                    isActive: currentRoute == Routes.deviceHandover,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.remove_circle_outline,
                    title: 'drawer_withdraw_device'.tr,
                    route: Routes.withdrawDevice,
                    isActive: currentRoute == Routes.withdrawDevice,
                    gradient: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
                  ),
                  _DrawerItem(
                    icon: Icons.history_outlined,
                    title: 'drawer_received_devices'.tr,
                    route: Routes.receivedDevices,
                    isActive: currentRoute == Routes.receivedDevices,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),

                  // --- 4. خدمات وأدوات ---
                  _buildSectionHeader('drawer_sec_services'.tr),
                  _DrawerItem(
                    icon: Icons.request_page_outlined,
                    title: 'drawer_request_inventory'.tr,
                    route: Routes.requestInventory,
                    isActive: currentRoute == Routes.requestInventory,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.business_rounded,
                    title: 'drawer_neoleap_leads'.tr,
                    route: Routes.neoleapLeads,
                    isActive: currentRoute == Routes.neoleapLeads,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),

                  // --- 5. النظام والحساب ---
                  _buildSectionHeader('drawer_sec_system'.tr),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    title: 'drawer_profile'.tr,
                    route: Routes.profile,
                    isActive: currentRoute == Routes.profile,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  Obx(() {
                    final dashboardController = Get.isRegistered<DashboardController>()
                        ? Get.find<DashboardController>()
                        : null;
                    final count = dashboardController?.pendingTransfersCount ?? 0;
                    return _DrawerItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'drawer_notifications'.tr,
                      route: Routes.notifications,
                      isActive: currentRoute == Routes.notifications,
                      gradient: [AppColors.primary, AppColors.primaryDark],
                      badge: count > 0 ? count : null,
                    );
                  }),
                  _DrawerItem(
                    icon: Icons.info_outline,
                    title: 'drawer_about_us'.tr,
                    route: Routes.aboutUs,
                    isActive: currentRoute == Routes.aboutUs,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final user = authController.user;
                if (user == null) {
                  return const SizedBox();
                }

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        Get.dialog(
                          AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: Text(
                              'confirm'.tr,
                              style: TextStyle(fontFamily: 'BeIN', 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            content: Text(
                              'logout_confirm'.tr,
                              style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'cancel'.tr,
                                  style: TextStyle(fontFamily: 'BeIN', 
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Get.back(); // close dialog
                                  Get.back(); // close drawer
                                  await authController.logout();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(fontFamily: 'BeIN', 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'logout'.tr,
                              style: TextStyle(fontFamily: 'BeIN', 
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8, left: 16, right: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontFamily: 'BeIN', 
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isActive;
  final List<Color> gradient;
  final int? badge;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.isActive,
    required this.gradient,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              )
            : null,
        color: isActive ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: gradient.first.withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Get.back(); // Close drawer
            if (Get.currentRoute != route) {
              Get.toNamed(route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : AppColors.primary.withOpacity(0.85),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontFamily: 'BeIN', 
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
                // Badge
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.3)
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge! > 9 ? '9+' : badge.toString(),
                      style: TextStyle(fontFamily: 'BeIN', 
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Active Indicator
                if (isActive)
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
