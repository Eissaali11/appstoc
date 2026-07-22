import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../controllers/devices_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../../shared/utils/barcode_validator.dart';
import '../../data/models/received_device.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../core/api/api_client.dart';

class SubmitDevicePage extends StatefulWidget {
  const SubmitDevicePage({super.key});

  @override
  State<SubmitDevicePage> createState() => _SubmitDevicePageState();
}

class _SubmitDevicePageState extends State<SubmitDevicePage> {
  final _formKey = GlobalKey<FormState>();
  final _terminalIdController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _damagePartController = TextEditingController();
  
  String _selectedCategory = 'devices'; // devices, papers, sim, accessories
  String? _selectedItemTypeId;
  String _inventoryType = 'fixed'; // fixed, moving

  // Accessories
  bool _battery = false;
  bool _chargerCable = false;
  bool _chargerHead = false;
  bool _hasSim = false;
  String? _simCardType;
  final List<String> _simTypes = [
    'STC',
    'موبايلي',
    'زين',
    'ليبارا',
    'فيرجن موبايل',
    'ريد بل موبايل',
    'سلام موبايل',
    'جوي',
    'فريندي موبايل',
    'أخرى'
  ];

  // Damages
  String _selectedDamageType = ''; // screen, port, battery, printer, keypad, other, none
  final Map<String, String> _damageTypes = {
    'screen': '🖥️ كسر في الشاشة',
    'port': '🔌 تلف منفذ الشحن',
    'battery': '🔋 انتفاخ/تلف البطارية',
    'printer': '🖨️ عطل في الطابعة',
    'keypad': '⌨️ تلف لوحة المفاتيح',
    'other': '⚙️ عطل آخر (كتابة مخصصة)',
    'none': '✅ لا يوجد تلف (سليم)',
  };

  // Offline Mode & Drafts
  bool _isOfflineMode = false;
  int _localDraftsCount = 0;
  late Box _draftsBox;

  // Custody Lookup State
  bool _isSearchingCustody = false;
  Map<String, dynamic>? _custodyInfo;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _draftsBox = await Hive.openBox('draft_devices');
    setState(() {
      _localDraftsCount = _draftsBox.length;
    });
  }

  @override
  void dispose() {
    _terminalIdController.dispose();
    _serialNumberController.dispose();
    _damagePartController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      final controller = Get.find<DevicesController>();
      final filtered = controller.itemTypes
          .where((type) => type.category == category)
          .toList();
      _selectedItemTypeId = filtered.isNotEmpty ? filtered.first.id : null;
      
      // Reset device specific fields if category is not devices
      if (category != 'devices') {
        _terminalIdController.clear();
        _battery = false;
        _chargerCable = false;
        _chargerHead = false;
        _hasSim = false;
        _simCardType = null;
        _selectedDamageType = '';
        _damagePartController.clear();
        _custodyInfo = null;
      }
    });
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'RECEIVED_BY_TECHNICIAN': return 'مستلم بعهدة الفني';
      case 'PENDING_TECHNICIAN_APPROVAL': return 'بانتظار قبول الفني';
      case 'IN_WAREHOUSE': return 'في المستودع';
      case 'INSTALLED': return 'تم تركيبه للعميل';
      case 'WITHDRAWN': return 'مسحوب/مرتجع';
      default: return status;
    }
  }

  // Smart Custody Lookup from Backend
  Future<void> _lookupCustody() async {
    final serial = _serialNumberController.text.trim();
    if (serial.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال الرقم التسلسلي أولاً للبحث',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white);
      return;
    }

    setState(() {
      _isSearchingCustody = true;
      _custodyInfo = null;
    });

    try {
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.get('/api/serialized-items/lookup/$serial');
      setState(() {
        _isSearchingCustody = false;
        if (response.data != null) {
          final data = response.data as Map<String, dynamic>;
          _custodyInfo = {
            'found': true,
            'technician': data['ownerName'] ?? data['ownerUsername'] ?? 'غير معروف',
            'city': 'العهد والعمليات',
            'model': data['itemTypeNameAr'] ?? 'جهاز نقاط البيع',
            'status': _translateStatus(data['status']?.toString() ?? ''),
          };
          if (_terminalIdController.text.isEmpty && data['barcode'] != null) {
            _terminalIdController.text = data['barcode'].toString();
          }
        } else {
          _custodyInfo = {
            'found': false,
            'message': 'الجهاز غير مسجل بعهدة أي فني حالياً (جديد/مستودع)',
          };
        }
      });
    } catch (e) {
      setState(() {
        _isSearchingCustody = false;
        _custodyInfo = {
          'found': false,
          'message': 'الجهاز غير مسجل بعهدة أي فني حالياً (جديد/مستودع)',
        };
      });
    }
  }

  bool _validateSerialNumberPattern(String serial, ItemType? selectedItemType) {
    if (selectedItemType == null) return true;

    final validationError = BarcodeValidator.validate(serial, selectedItemType);
    if (validationError != null) {
      Get.snackbar(
        'خطأ في الرقم التسلسلي',
        validationError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    }

    return true;
  }

  // Save as Local Draft (Offline Queue)
  Future<void> _saveAsDraft() async {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<DevicesController>();
      final serial = _serialNumberController.text.trim();

      final selectedItemType = controller.itemTypes.firstWhere(
        (type) => type.id == _selectedItemTypeId,
        orElse: () => controller.itemTypes.first,
      );

      if (!_validateSerialNumberPattern(serial, selectedItemType)) {
        return;
      }

      // Check if serial is already pending on the server
      final isAlreadyPending = controller.devices.any((d) =>
        d.serialNumber == serial &&
        (d.status ?? '').toLowerCase() == 'pending'
      );

      if (isAlreadyPending) {
        Get.snackbar(
          'تنبيه تكرار السيريال',
          'هذا الرقم التسلسلي مضاف بالفعل وقيد مراجعة المشرف في الإشعارات ولا يمكن تكراره.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Also check local drafts Box
      final isAlreadyInDrafts = _draftsBox.values.any((d) {
        if (d is Map) {
          return d['serialNumber'] == serial;
        }
        return false;
      });

      if (isAlreadyInDrafts) {
        Get.snackbar(
          'تنبيه تكرار السيريال',
          'هذا الرقم التسلسلي موجود بالفعل في المسودات المحلية.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final deviceData = {
        'itemTypeId': _selectedItemTypeId,
        'inventoryType': _inventoryType,
        'terminalId': _selectedCategory == 'devices' ? _terminalIdController.text.trim() : null,
        'serialNumber': _serialNumberController.text.trim(),
        'battery': _selectedCategory == 'devices' ? _battery : false,
        'chargerCable': _selectedCategory == 'devices' ? _chargerCable : false,
        'chargerHead': _selectedCategory == 'devices' ? _chargerHead : false,
        'hasSim': _selectedCategory == 'devices' ? _hasSim : false,
        'simCardType': (_selectedCategory == 'devices' && _hasSim) ? (_simCardType ?? _simTypes[0]) : null,
        'damagePart': _selectedCategory == 'devices' 
            ? (_selectedDamageType == 'other' ? _damagePartController.text.trim() : _damageTypes[_selectedDamageType])
            : null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _draftsBox.add(deviceData);
      setState(() {
        _localDraftsCount = _draftsBox.length;
      });

      _resetForm();

      Get.dialog(
        AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Row(
            children: [
              const Icon(Icons.cloud_off, color: AppColors.warning),
              const SizedBox(width: 8),
              Text('تم الحفظ كمسودة محلياً', style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'تم حفظ الجهاز في مسودات التخزين المحلي بنجاح نظراً لأن وضع العمل أوفلاين نشط. سيتم توريدها بمجرد عودة الإنترنت والضغط على مزامنة.',
            style: TextStyle(fontFamily: 'BeIN', color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('حسناً', style: TextStyle(fontFamily: 'BeIN', color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  // Sync Offline Drafts Queue
  Future<void> _syncDrafts() async {
    if (_localDraftsCount == 0) return;

    final controller = Get.find<DevicesController>();
    int successCount = 0;
    
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );

    try {
      final keys = List.from(_draftsBox.keys);
      for (var key in keys) {
        final data = _draftsBox.get(key) as Map;
        final device = ReceivedDevice(
          itemTypeId: data['itemTypeId'] as String?,
          inventoryType: data['inventoryType'] as String? ?? 'fixed',
          terminalId: data['terminalId'] as String?,
          serialNumber: data['serialNumber'] as String? ?? '',
          battery: data['battery'] as bool? ?? false,
          chargerCable: data['chargerCable'] as bool? ?? false,
          chargerHead: data['chargerHead'] as bool? ?? false,
          hasSim: data['hasSim'] as bool? ?? false,
          simCardType: data['simCardType'] as String?,
          damagePart: data['damagePart'] as String?,
        );

        await controller.repository.submitDevice(device);
        await _draftsBox.delete(key);
        successCount++;
      }

      Get.back(); // Dismiss loading

      setState(() {
        _localDraftsCount = _draftsBox.length;
      });

      await controller.loadDevices();

      Get.snackbar(
        'مزامنة ناجحة',
        'تم مزامنة وتوريد $successCount جهاز من المسودات المحلية بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Dismiss loading
      Get.snackbar(
        'خطأ في المزامنة',
        'فشل إرسال بعض المسودات. يرجى التحقق من اتصال الإنترنت والمحاولة لاحقاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _terminalIdController.clear();
    _serialNumberController.clear();
    _damagePartController.clear();
    setState(() {
      _battery = false;
      _chargerCable = false;
      _chargerHead = false;
      _hasSim = false;
      _simCardType = null;
      _selectedDamageType = '';
      _custodyInfo = null;
    });
  }

  void _submit() {
    if (_isOfflineMode) {
      _saveAsDraft();
      return;
    }

    if (_formKey.currentState!.validate()) {
      final controller = Get.find<DevicesController>();
      final serial = _serialNumberController.text.trim();

      final selectedItemType = controller.itemTypes.firstWhere(
        (type) => type.id == _selectedItemTypeId,
        orElse: () => controller.itemTypes.first,
      );

      if (!_validateSerialNumberPattern(serial, selectedItemType)) {
        return;
      }

      // Check if serial is already pending on the server
      final isAlreadyPending = controller.devices.any((d) =>
        d.serialNumber == serial &&
        (d.status ?? '').toLowerCase() == 'pending'
      );

      if (isAlreadyPending) {
        Get.snackbar(
          'تنبيه تكرار السيريال',
          'هذا الرقم التسلسلي مضاف بالفعل وقيد مراجعة المشرف في الإشعارات ولا يمكن تكراره.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }
      
      final damageText = _selectedCategory == 'devices'
          ? (_selectedDamageType == 'other' ? _damagePartController.text.trim() : _damageTypes[_selectedDamageType])
          : null;

      final device = ReceivedDevice(
        itemTypeId: _selectedItemTypeId,
        inventoryType: _inventoryType,
        terminalId: _selectedCategory == 'devices' ? _terminalIdController.text.trim() : null,
        serialNumber: _serialNumberController.text.trim(),
        battery: _selectedCategory == 'devices' ? _battery : false,
        chargerCable: _selectedCategory == 'devices' ? _chargerCable : false,
        chargerHead: _selectedCategory == 'devices' ? _chargerHead : false,
        hasSim: _selectedCategory == 'devices' ? _hasSim : false,
        simCardType: (_selectedCategory == 'devices' && _hasSim) ? (_simCardType ?? _simTypes[0]) : null,
        damagePart: (damageText != null && damageText != _damageTypes['none']) ? damageText : null,
      );

      _showSuccessReceipt(device);
    }
  }

  // Digital Receipt Success Preview
  void _showSuccessReceipt(ReceivedDevice device) {
    final controller = Get.find<DevicesController>();
    final itemName = _selectedItemTypeId != null 
        ? controller.itemTypes.firstWhere((t) => t.id == _selectedItemTypeId).nameAr
        : 'منتج غير معروف';

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 12),
              Text(
                'تم تسجيل التوريد بنجاح',
                style: TextStyle(fontFamily: 'BeIN', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'معاينة إيصال الاستلام الرقمي',
                style: TextStyle(fontFamily: 'BeIN', fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              
              // Receipt Details Area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _receiptRow('المنتج', itemName),
                    _receiptRow('الرقم التسلسلي', device.serialNumber),
                    if (device.terminalId != null && device.terminalId!.isNotEmpty)
                      _receiptRow('رقم الجهاز (ID)', device.terminalId!),
                    _receiptRow('نوع المستودع', device.inventoryType == 'moving' ? 'مخزون متحرك' : 'مخزون ثابت'),
                    if (_selectedCategory == 'devices') ...[
                      const Divider(color: AppColors.border),
                      _receiptRow('الملحقات المستلمة', '${device.accessoriesCount} ملحقات'),
                      if (device.damagePart != null)
                        _receiptRow('حالة الأعطال', device.damagePart!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Get.back(); // close dialog
                        await controller.submitDevice(device);
                      },
                      icon: const Icon(Icons.send),
                      label: Text('تأكيد وإرسال', style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      final buffer = StringBuffer();
                      buffer.writeln('📋 *إيصال استلام جهاز* 📋');
                      buffer.writeln('📦 المنتج: $itemName');
                      buffer.writeln('🔢 الرقم التسلسلي: ${device.serialNumber}');
                      if (device.terminalId != null) buffer.writeln('📟 رقم الجهاز: ${device.terminalId}');
                      buffer.writeln('🔋 الملحقات: ${device.accessoriesCount} ملحقات');
                      if (device.damagePart != null) buffer.writeln('⚠️ الضرر: ${device.damagePart}');
                      Share.share(buffer.toString());
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceDark,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DevicesController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: RasscoAppBar(
        titleText: 'إدخال وتوريد الأجهزة الذكي',
        actions: [
          // Offline Mode Toggle Icon
          IconButton(
            icon: Icon(
              _isOfflineMode ? Icons.cloud_off : Icons.cloud_done,
              color: _isOfflineMode ? AppColors.warning : AppColors.success,
            ),
            onPressed: () {
              setState(() {
                _isOfflineMode = !_isOfflineMode;
              });
              Get.snackbar(
                _isOfflineMode ? 'وضع الأوفلاين نشط' : 'وضع الأونلاين نشط',
                _isOfflineMode 
                    ? 'سيتم حفظ الأجهزة كمسودات محلياً في عهدتك دون اتصال' 
                    : 'سيتم توريد الأجهزة مباشرة إلى سيرفر النظام',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: _isOfflineMode ? AppColors.warning : AppColors.success,
                colorText: Colors.white,
              );
            },
          ),
          if (_localDraftsCount > 0)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.sync, color: AppColors.primary),
                  onPressed: _syncDrafts,
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: AppColors.error,
                    child: Text(
                      _localDraftsCount.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Obx(() {
          if (controller.isLoading && controller.itemTypes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final filteredItemTypes = controller.itemTypes
              .where((type) => type.category == _selectedCategory)
              .toList();

          if (_selectedItemTypeId == null && filteredItemTypes.isNotEmpty) {
            _selectedItemTypeId = filteredItemTypes.first.id;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Offline Alert Banner
              if (_isOfflineMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تعمل الآن في وضع عدم الاتصال. سيتم حفظ الأجهزة محلياً.',
                          style: TextStyle(fontFamily: 'BeIN', color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              // Category Selector
              _buildCategorySelector(),
              const SizedBox(height: 20),

              // Item Type Dropdown
              _buildItemTypeDropdown(filteredItemTypes),
              const SizedBox(height: 20),

              // Target Inventory Selector
              _buildTargetInventorySelector(),
              const SizedBox(height: 20),

              // Serial Number (Smart Field with Barcode Scanner & Lookup)
              _buildSmartSerialField(),
              const SizedBox(height: 20),

              // Custody Lookup Result Card
              if (_custodyInfo != null) _buildCustodyResultCard(),

              // Conditional Fields for "devices" category
              if (_selectedCategory == 'devices') ...[
                // Terminal ID
                _buildTextField(
                  controller: _terminalIdController,
                  label: 'رقم الجهاز (Terminal ID) - اختياري',
                  icon: Icons.tag,
                  onScanPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BarcodeScannerWidget(
                          title: 'مسح رقم الجهاز',
                          rawBarcodeMode: true,
                        ),
                      ),
                    );
                    final code = result is String
                        ? result
                        : (result is Map ? result['code'] as String? : null);
                    if (code != null) {
                      setState(() {
                        _terminalIdController.text = code;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Accessories Section (Visual Grid)
                Text(
                  'الملحقات المستلمة بالجهاز',
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _buildAccessoriesGrid(),
                if (_hasSim) ...[
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    label: 'نوع شريحة SIM',
                    value: _simCardType ?? _simTypes[0],
                    items: _simTypes,
                    onChanged: (value) => setState(() => _simCardType = value),
                  ),
                ],
                const SizedBox(height: 24),

                // Damage Section (Visual Chips Grid)
                Text(
                  'تقييم الضرر والكسر للجهاز المستلم',
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDamageGrid(),
                const SizedBox(height: 20),

                // Custom Damage Text (Visible only when 'other' is selected)
                if (_selectedDamageType == 'other')
                  _buildTextField(
                    controller: _damagePartController,
                    label: 'وصف الضرر والأعطال الإضافية بالتفصيل',
                    icon: Icons.warning,
                    maxLines: 2,
                  ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              ElevatedButton.icon(
                onPressed: controller.isLoading ? null : _submit,
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  controller.isLoading 
                      ? 'جاري الإرسال...' 
                      : (_isOfflineMode ? 'حفظ كمسودة محلياً' : 'إرسال وتسجيل التوريد'),
                  style: TextStyle(fontFamily: 'BeIN', 
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOfflineMode ? AppColors.warning : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'id': 'devices', 'name': 'جهاز', 'icon': Icons.smartphone},
      {'id': 'papers', 'name': 'ورقيات', 'icon': Icons.description},
      {'id': 'sim', 'name': 'شريحة SIM', 'icon': Icons.sim_card},
      {'id': 'accessories', 'name': 'إكسسوارات', 'icon': Icons.headset},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تصنيف المنتج',
          style: TextStyle(fontFamily: 'BeIN', 
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => _onCategoryChanged(cat['id'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildItemTypeDropdown(List<ItemType> filteredItemTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع المنتج التفصيلي',
          style: TextStyle(fontFamily: 'BeIN', 
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        if (filteredItemTypes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.5)),
            ),
            child: Text(
              'لا توجد أنواع منتجات معرفة في هذا التصنيف بالخادم',
              style: TextStyle(fontFamily: 'BeIN', color: AppColors.error, fontSize: 14),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedItemTypeId,
              items: filteredItemTypes.map((type) {
                return DropdownMenuItem(
                  value: type.id,
                  child: Text(
                    type.nameAr,
                    style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedItemTypeId = value),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: AppColors.surfaceDark,
              style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildTargetInventorySelector() {
    final options = [
      {'id': 'fixed', 'name': 'مخزون ثابت', 'icon': Icons.warehouse},
      {'id': 'moving', 'name': 'مخزون متحرك', 'icon': Icons.local_shipping},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المستودع المستهدف لتسجيل المخزون',
          style: TextStyle(fontFamily: 'BeIN', 
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: options.map((opt) {
            final isSelected = _inventoryType == opt['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _inventoryType = opt['id'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        opt['name'] as String,
                        style: TextStyle(fontFamily: 'BeIN', 
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmartSerialField() {
    final controller = Get.find<DevicesController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الرقم التسلسلي (Serial Number) / باركود المنتج',
          style: TextStyle(fontFamily: 'BeIN', 
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _serialNumberController,
            style: TextStyle(fontFamily: 'BeIN', color: AppColors.textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'يرجى إدخال الرقم التسلسلي أو مسح الباركود';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'أدخل الرقم التسلسلي أو امسح الباركود...',
              hintStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary.withOpacity(0.6), fontSize: 13),
              prefixIcon: const Icon(Icons.qr_code, color: AppColors.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedCategory == 'devices')
                    _isSearchingCustody
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : TextButton(
                            onPressed: _lookupCustody,
                            child: Text(
                              'فحص العهدة',
                              style: TextStyle(fontFamily: 'BeIN', color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                    onPressed: () async {
                      final result = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BarcodeScannerWidget(
                            title: 'مسح الرقم التسلسلي',
                            itemTypes: _selectedCategory == 'sim'
                                ? controller.itemTypes
                                    .where((t) => t.category == 'sim')
                                    .toList()
                                : controller.itemTypes
                                    .where((t) =>
                                        t.category == _selectedCategory)
                                    .toList(),
                            selectedItemTypeId: _selectedItemTypeId,
                            categoryHint: _selectedCategory,
                            // SIM: accept any carrier rule in category (18 or 19).
                            allowUnionOfItemTypes: _selectedCategory == 'sim',
                          ),
                        ),
                      );
                      if (result != null) {
                        String? code;
                        String? returnedItemTypeId;
                        if (result is Map) {
                          code = result['code'] as String?;
                          returnedItemTypeId = result['itemTypeId'] as String?;
                        } else if (result is String) {
                          code = result;
                        }
                        
                        if (code != null) {
                          setState(() {
                            _serialNumberController.text = code!;
                            if (returnedItemTypeId != null) {
                              _selectedItemTypeId = returnedItemTypeId;
                              final type = controller.itemTypes.firstWhere((t) => t.id == returnedItemTypeId);
                              _selectedCategory = type.category ?? 'devices';
                            }
                          });
                          if (_selectedCategory == 'devices') {
                            _lookupCustody();
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustodyResultCard() {
    final info = _custodyInfo!;
    final found = info['found'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: found ? AppColors.success.withOpacity(0.08) : AppColors.textSecondary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: found ? AppColors.success.withOpacity(0.4) : AppColors.border.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            found ? Icons.info_outline : Icons.help_outline,
            color: found ? AppColors.success : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: found
                  ? [
                      Text(
                        'جهاز معروف - عهدة نشطة في الميدان',
                        style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الحائز الحالي: ${info['technician']} (${info['city']})',
                        style: TextStyle(fontFamily: 'BeIN', color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        'حالة العهدة: ${info['status']}',
                        style: TextStyle(fontFamily: 'BeIN', color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ]
                  : [
                      Text(
                        'جهاز غير مدرج بعهدة فني',
                        style: TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info['message'] as String,
                        style: TextStyle(fontFamily: 'BeIN', color: Colors.white70, fontSize: 12),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoriesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildAccessoryCard('بطارية داخلية', _battery, Icons.battery_charging_full, (value) => setState(() => _battery = value)),
        _buildAccessoryCard('كابل الشاحن', _chargerCable, Icons.cable, (value) => setState(() => _chargerCable = value)),
        _buildAccessoryCard('رأس الشاحن', _chargerHead, Icons.power, (value) => setState(() => _chargerHead = value)),
        _buildAccessoryCard('شريحة SIM', _hasSim, Icons.sim_card, (value) {
          setState(() {
            _hasSim = value;
            if (!_hasSim) {
              _simCardType = null;
            } else {
              _simCardType = _simTypes[0];
            }
          });
        }),
      ],
    );
  }

  Widget _buildAccessoryCard(String title, bool isSelected, IconData icon, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontFamily: 'BeIN', 
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _damageTypes.entries.map((entry) {
        final isSelected = _selectedDamageType == entry.key;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDamageType = entry.key;
              if (entry.key != 'other') {
                _damagePartController.clear();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Text(
              entry.value,
              style: TextStyle(fontFamily: 'BeIN', 
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'BeIN', 
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    VoidCallback? onScanPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(fontFamily: 'BeIN', color: AppColors.textPrimary),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: onScanPressed != null
              ? IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                  onPressed: onScanPressed,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
