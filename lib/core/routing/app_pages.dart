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
import '../../features/received_devices/presentation/pages/withdrawn_device_details_page.dart';
import '../../features/received_devices/presentation/pages/device_handover_page.dart';
import '../../features/received_devices/presentation/pages/handover_details_page.dart';
import '../../features/received_devices/presentation/bindings/devices_binding.dart';
import '../../features/dashboard/presentation/pages/inventory_list_page.dart';
import '../../features/dashboard/presentation/pages/inventory_section_details_page.dart';
import '../../features/dashboard/presentation/pages/request_inventory_page.dart';
import '../../features/inventory_requests/presentation/bindings/inventory_request_binding.dart';
import '../../features/about/presentation/pages/about_us_page.dart';
import '../../features/received_devices/presentation/pages/serialized_custody_page.dart';
import '../../features/received_devices/presentation/pages/withdraw_device_page.dart';
import '../../features/neoleap_leads/presentation/pages/neoleap_leads_page.dart';
import '../../features/neoleap_leads/presentation/bindings/neoleap_leads_binding.dart';
import '../../features/courier_requests/presentation/pages/courier_requests_page.dart';
import '../../features/courier_requests/presentation/pages/courier_request_details_page.dart';
import '../../features/courier_requests/presentation/pages/courier_request_scanner_page.dart';
import '../../features/courier_requests/presentation/pages/courier_request_review_page.dart';
import '../../features/courier_requests/presentation/pages/courier_receiving_success_page.dart';
import '../../features/courier_requests/presentation/pages/courier_visit_execution_page.dart';
import '../../features/courier_requests/presentation/bindings/courier_requests_binding.dart';
import '../../features/moving_inventory/presentation/pages/shipment_scan_page.dart';
import '../../features/received_devices/presentation/pages/my_serialized_inventory_page.dart';

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
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 450),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardPage(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 450),
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
      name: Routes.withdrawnDeviceDetails,
      page: () => const WithdrawnDeviceDetailsPage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.deviceHandover,
      page: () => const DeviceHandoverPage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.handoverDetails,
      page: () => const HandoverDetailsPage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.inventoryList,
      page: () => const InventoryListPage(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.inventorySectionDetails,
      page: () => const InventorySectionDetailsPage(),
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
    GetPage(
      name: Routes.serializedCustody,
      page: () => const SerializedCustodyPage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.withdrawDevice,
      page: () => const WithdrawDevicePage(),
      binding: DevicesBinding(),
    ),
    GetPage(
      name: Routes.neoleapLeads,
      page: () => const NeoleapLeadsPage(),
      binding: NeoleapLeadsBinding(),
    ),
    GetPage(
      name: Routes.courierRequests,
      page: () => const CourierRequestsPage(),
      binding: CourierRequestsBinding(),
    ),
    GetPage(
      name: Routes.courierRequestDetails,
      page: () => const CourierRequestDetailsPage(),
      binding: CourierRequestsBinding(),
    ),
    GetPage(
      name: Routes.courierRequestScanner,
      page: () => const CourierRequestScannerPage(),
      binding: CourierRequestsBinding(),
    ),
    GetPage(
      name: Routes.courierRequestReview,
      page: () => const CourierRequestReviewPage(),
      binding: CourierRequestsBinding(),
    ),
    GetPage(
      name: Routes.courierRequestSuccess,
      page: () => const CourierReceivingSuccessPage(),
      binding: CourierRequestsBinding(),
    ),
    GetPage(
      name: Routes.courierVisitExecution,
      page: () => const CourierVisitExecutionPage(),
      binding: CourierRequestsBinding(),
    ),
    GetPage(
      name: Routes.shipmentScan,
      page: () => const ShipmentScanPage(),
      binding: MovingInventoryBinding(),
    ),
    GetPage(
      name: Routes.mySerializedInventory,
      page: () => const MySerializedInventoryPage(),
      binding: DashboardBinding(),
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
  static const withdrawnDeviceDetails = '/withdrawn-device-details';
  static const deviceHandover = '/device-handover';
  static const handoverDetails = '/handover-details';
  static const inventoryList = '/inventory-list';
  static const inventorySectionDetails = '/inventory-section-details';
  static const requestInventory = '/request-inventory';
  static const aboutUs = '/about-us';
  static const serializedCustody = '/serialized-custody';
  static const withdrawDevice = '/withdraw-device';
  static const neoleapLeads = '/neoleap-leads';
  static const courierRequests = '/courier-requests';
  static const courierRequestDetails = '/courier-request-details';
  static const courierRequestScanner = '/courier-request-scanner';
  static const courierRequestReview = '/courier-request-review';
  static const courierRequestSuccess = '/courier-request-success';
  static const courierVisitExecution = '/courier-visit-execution';
  static const shipmentScan = '/shipment-scan';
  static const mySerializedInventory = '/my-serialized-inventory';
}
