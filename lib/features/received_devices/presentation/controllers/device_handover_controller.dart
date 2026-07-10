import 'package:get/get.dart';
import '../../data/models/received_device.dart';
import '../../../../core/utils/gps_helper.dart';

class DeviceHandoverController extends GetxController {
  final _isLoading = false.obs;
  final _myCustodyDevices = <ReceivedDevice>[].obs;
  final _selectedDevices = <ReceivedDevice>{}.obs;
  
  // Recipient options
  final _handoverType = 'technician'.obs; // 'technician' | 'warehouse'
  final _selectedRecipientId = Rxn<String>();
  
  // GPS Coordinates
  final Rxn<double> _latitude = Rxn<double>();
  final Rxn<double> _longitude = Rxn<double>();
  
  // Lists fetched from server/mocked
  final _technicians = <Map<String, String>>[].obs;
  final _warehouses = <Map<String, String>>[].obs;

  bool get isLoading => _isLoading.value;
  List<ReceivedDevice> get myCustodyDevices => _myCustodyDevices;
  Set<ReceivedDevice> get selectedDevices => _selectedDevices;
  String get handoverType => _handoverType.value;
  String? get selectedRecipientId => _selectedRecipientId.value;
  double? get latitude => _latitude.value;
  double? get longitude => _longitude.value;
  List<Map<String, String>> get technicians => _technicians;
  List<Map<String, String>> get warehouses => _warehouses;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void setHandoverType(String type) {
    _handoverType.value = type;
    _selectedRecipientId.value = null;
  }

  void selectRecipient(String id) {
    _selectedRecipientId.value = id;
  }

  void toggleDeviceSelection(ReceivedDevice device) {
    if (_selectedDevices.contains(device)) {
      _selectedDevices.remove(device);
    } else {
      _selectedDevices.add(device);
    }
  }

  bool isDeviceSelected(ReceivedDevice device) => _selectedDevices.contains(device);

  void clearSelection() {
    _selectedDevices.clear();
  }

  // Scan serial and auto-select
  bool scanAndSelectDevice(String serial) {
    for (var device in _myCustodyDevices) {
      if (device.serialNumber.toLowerCase() == serial.toLowerCase().trim()) {
        if (!_selectedDevices.contains(device)) {
          _selectedDevices.add(device);
          update();
          return true;
        }
        return false; // already selected
      }
    }
    return false; // not found in custody
  }

  Future<void> loadData() async {
    try {
      _isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network

      // Mock Custody Devices (representing devices in technician's moving custody)
      _myCustodyDevices.value = [
        ReceivedDevice(
          id: 'dev-1',
          serialNumber: 'SN-950-8821',
          terminalId: 'T8821',
          battery: true,
          chargerCable: true,
          chargerHead: true,
          hasSim: true,
          simCardType: 'STC',
          status: 'approved',
          inventoryType: 'moving',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        ReceivedDevice(
          id: 'dev-2',
          serialNumber: 'SN-950-7612',
          terminalId: 'T7612',
          battery: true,
          chargerCable: true,
          chargerHead: false,
          hasSim: true,
          simCardType: 'موبايلي',
          status: 'approved',
          inventoryType: 'moving',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ReceivedDevice(
          id: 'dev-3',
          serialNumber: 'SN-i90-5044',
          terminalId: 'T5044',
          battery: true,
          chargerCable: false,
          chargerHead: false,
          hasSim: false,
          status: 'approved',
          inventoryType: 'moving',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ];

      // Mock Technicians
      _technicians.value = [
        {'id': 'tech-101', 'name': 'أحمد محمد العتيبي', 'city': 'الرياض'},
        {'id': 'tech-102', 'name': 'عيسى علي البشري', 'city': 'مكة المكرمة'},
        {'id': 'tech-103', 'name': 'عمر عبد الله المطيري', 'city': 'الدمام'},
      ];

      // Mock Warehouses
      _warehouses.value = [
        {'id': 'wh-1', 'name': 'مستودع جدة الرئيسي', 'city': 'جدة'},
        {'id': 'wh-2', 'name': 'مستودع الرياض الإقليمي', 'city': 'الرياض'},
      ];
    } catch (e) {
      // error handling
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> submitHandover() async {
    if (_selectedDevices.isEmpty || _selectedRecipientId.value == null) {
      return false;
    }

    try {
      _isLoading.value = true;

      // Auto GPS capture
      final position = await GpsHelper.getCurrentLocation();
      if (position != null) {
        _latitude.value = position.latitude;
        _longitude.value = position.longitude;
      } else {
        // Mock fallback if GPS is unavailable or disabled in testing
        _latitude.value = 24.7136;
        _longitude.value = 46.6753;
      }

      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate network

      // Remove transferred devices from custody for demonstration
      _myCustodyDevices.removeWhere((d) => _selectedDevices.contains(d));
      _selectedDevices.clear();
      _selectedRecipientId.value = null;

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
