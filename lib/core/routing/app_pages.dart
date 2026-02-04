import 'package:get/get.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/dashboard/presentation/bindings/dashboard_binding.dart';
import '../../features/fixed_inventory/presentation/pages/fixed_inventory_page.dart';
import '../../features/fixed_inventory/presentation/bindings/fixed_inventory_binding.dart';
import '../../features/moving_inventory/presentation/pages/moving_inventory_page.dart';
import '../../features/moving_inventory/presentation/bindings/moving_inventory_binding.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/notifications/presentation/bindings/notifications_binding.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/received_devices/presentation/pages/submit_device_page.dart';
import '../../features/received_devices/presentation/pages/received_devices_page.dart';
import '../../features/received_devices/presentation/bindings/devices_binding.dart';
import '../../features/dashboard/presentation/pages/inventory_list_page.dart';
import '../../features/dashboard/presentation/pages/request_inventory_page.dart';
import '../../features/inventory_requests/presentation/bindings/inventory_request_binding.dart';
import '../../features/about/presentation/pages/about_us_page.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.fixedInventory,
      page: () => const FixedInventoryPage(),
      binding: FixedInventoryBinding(),
    ),
    GetPage(
      name: Routes.movingInventory,
      page: () => const MovingInventoryPage(),
      binding: MovingInventoryBinding(),
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: Routes.submitDevice,
      page: () => const SubmitDevicePage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.receivedDevices,
      page: () => const ReceivedDevicesPage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.inventoryList,
      page: () => const InventoryListPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.requestInventory,
      page: () => const RequestInventoryPage(),
      binding: InventoryRequestBinding(),
    ),
    GetPage(
      name: Routes.aboutUs,
      page: () => const AboutUsPage(),
    ),
  ];
}

class Routes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const fixedInventory = '/fixed-inventory';
  static const movingInventory = '/moving-inventory';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const submitDevice = '/submit-device';
  static const receivedDevices = '/received-devices';
  static const inventoryList = '/inventory-list';
  static const requestInventory = '/request-inventory';
  static const aboutUs = '/about-us';
}
