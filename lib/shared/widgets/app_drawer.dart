import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_pages.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';

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
            // Header with User Info
            Obx(() {
              final user = authController.user;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.cairo(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      user?.fullName ?? 'مستخدم',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Username
                    Text(
                      '@${user?.username ?? 'user'}',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
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
                  _DrawerItem(
                    icon: Icons.dashboard,
                    title: 'لوحة التحكم',
                    route: Routes.dashboard,
                    isActive: currentRoute == Routes.dashboard,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2,
                    title: 'المخزون الثابت',
                    route: Routes.fixedInventory,
                    isActive: currentRoute == Routes.fixedInventory,
                    gradient: [AppColors.primary, AppColors.primaryDark],
                  ),
                  _DrawerItem(
                    icon: Icons.local_shipping,
                    title: 'المخزون المتحرك',
                    route: Routes.movingInventory,
                    isActive: currentRoute == Routes.movingInventory,
                    gradient: AppColors.purpleGradient,
                  ),
                  _DrawerItem(
                    icon: Icons.list_alt,
                    title: 'قائمة الأصناف',
                    route: Routes.inventoryList,
                    isActive: currentRoute == Routes.inventoryList,
                    gradient: AppColors.greenGradient,
                  ),
                  _DrawerItem(
                    icon: Icons.smartphone,
                    title: 'إدخال جهاز',
                    route: Routes.submitDevice,
                    isActive: currentRoute == Routes.submitDevice,
                    gradient: [AppColors.success, AppColors.success.withOpacity(0.8)],
                  ),
                  Obx(() {
                    final dashboardController = Get.isRegistered<DashboardController>()
                        ? Get.find<DashboardController>()
                        : null;
                    final count = dashboardController?.pendingTransfersCount ?? 0;
                    return _DrawerItem(
                      icon: Icons.notifications,
                      title: 'الإشعارات',
                      route: Routes.notifications,
                      isActive: currentRoute == Routes.notifications,
                      gradient: AppColors.orangeGradient,
                      badge: count > 0 ? count : null,
                    );
                  }),
                  const Divider(
                    color: AppColors.border,
                    height: 32,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  _DrawerItem(
                    icon: Icons.person,
                    title: 'الملف الشخصي',
                    route: Routes.profile,
                    isActive: currentRoute == Routes.profile,
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
                    gradient: LinearGradient(
                      colors: [AppColors.error, AppColors.error.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final confirmed = await Get.dialog<bool>(
                          AlertDialog(
                            backgroundColor: AppColors.surfaceDark,
                            title: Text(
                              'تأكيد',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            content: Text(
                              'هل أنت متأكد من تسجيل الخروج؟',
                              style: GoogleFonts.cairo(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: Text(
                                  'إلغاء',
                                  style: GoogleFonts.cairo(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Get.back(result: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  'تسجيل الخروج',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          Get.back(); // Close drawer
                          await authController.logout();
                        }
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
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'تسجيل الخروج',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 8,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.textSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary,
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
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Active Indicator
                if (isActive)
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
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
