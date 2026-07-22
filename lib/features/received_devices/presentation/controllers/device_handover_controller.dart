import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/models/received_device.dart';
import '../../../../core/utils/gps_helper.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

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
  
  // Lists fetched from server
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
      final ApiClient apiClient = Get.find<ApiClient>();

      // 1. Fetch technician's moving custody
      try {
        final custodyResponse = await apiClient.get('/api/my-serialized-custody');
        if (custodyResponse.data is List) {
          final List<dynamic> list = custodyResponse.data;
          _myCustodyDevices.value = list.map((item) {
            final isSim = item['carrierName'] != null;
            return ReceivedDevice(
              id: item['id']?.toString() ?? '',
              serialNumber: item['serialNumber']?.toString() ?? '',
              itemTypeId: item['itemTypeId']?.toString(),
              terminalId: '',
              battery: !isSim,
              chargerCable: !isSim,
              chargerHead: !isSim,
              hasSim: isSim,
              simCardType: item['carrierName']?.toString(),
              status: 'approved',
              inventoryType: 'moving',
              createdAt: item['createdAt'] != null 
                  ? DateTime.tryParse(item['createdAt'].toString()) 
                  : DateTime.now(),
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('Failed to load custody from server: $e');
        _myCustodyDevices.clear();
      }

      // 2. Fetch technicians
      try {
        final techResponse = await apiClient.get('/api/technicians');
        if (techResponse.data is List) {
          final List<dynamic> list = techResponse.data;
          _technicians.value = list.map((item) {
            final name = item['name']?.toString() ?? item['username']?.toString() ?? 'فني';
            return {
              'id': item['id']?.toString() ?? '',
              'name': name,
              'city': item['city']?.toString() ?? 'الرياض',
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('Failed to load technicians from server: $e');
        _technicians.value = [];
      }

      // 3. Fetch warehouses
      try {
        final whResponse = await apiClient.get('/api/warehouses');
        if (whResponse.data is List) {
          final List<dynamic> list = whResponse.data;
          _warehouses.value = list.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? 'مستودع',
              'city': item['city']?.toString() ?? 'جدة',
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('Failed to load warehouses from server: $e');
        _warehouses.value = [];
      }
    } catch (e) {
      debugPrint('Error loading handover data: $e');
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

      // Auto GPS capture — لا نستخدم إحداثيات وهمية عند الفشل
      final position = await GpsHelper.getCurrentLocation();
      if (position != null) {
        _latitude.value = position.latitude;
        _longitude.value = position.longitude;
      } else {
        _latitude.value = null;
        _longitude.value = null;
      }

      final ApiClient apiClient = Get.find<ApiClient>();
      final AuthController authController = Get.find<AuthController>();
      final currentUser = authController.user;

      for (final device in _selectedDevices) {
        if (_handoverType.value == 'technician') {
          final payload = {
            'technicianId': _selectedRecipientId.value,
            'serialNumber': device.serialNumber,
            'itemTypeId': device.itemTypeId,
            'terminalId': device.terminalId,
            'inventoryType': 'moving',
            'battery': device.battery,
            'chargerCable': device.chargerCable,
            'chargerHead': device.chargerHead,
            'hasSim': device.hasSim,
            'simCardType': device.simCardType,
            'status': 'pending',
          };
          await apiClient.post('/api/received-devices', data: payload);
        } else {
          final payload = {
            'city': currentUser?.city ?? 'الرياض',
            'technicianName': currentUser?.fullName ?? currentUser?.username ?? 'فني',
            'terminalId': device.terminalId ?? 'N/A',
            'serialNumber': device.serialNumber,
            'battery': device.battery ? 'yes' : 'no',
            'chargerCable': device.chargerCable ? 'yes' : 'no',
            'chargerHead': device.chargerHead ? 'yes' : 'no',
            'hasSim': device.hasSim ? 'yes' : 'no',
            if (device.simCardType != null) 'simCardType': device.simCardType,
            'notes': 'تم إرجاع الجهاز للمستودع عبر التطبيق',
          };
          await apiClient.post('/api/withdrawn-devices', data: payload);
        }
      }

      // Remove transferred devices from custody
      _myCustodyDevices.removeWhere((d) => _selectedDevices.contains(d));
      _selectedDevices.clear();
      _selectedRecipientId.value = null;

      return true;
    } catch (e) {
      debugPrint('Error during submitHandover: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
