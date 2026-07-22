import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../../../../shared/utils/barcode_validator.dart';
import '../../../../shared/scanner/scanner_item_types.dart';
import '../../../../core/storage/offline_queue_manager.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/devices_controller.dart';
import '../../data/models/withdrawn_device.dart';

class WithdrawDevicePage extends StatefulWidget {
  const WithdrawDevicePage({super.key});

  @override
  State<WithdrawDevicePage> createState() => _WithdrawDevicePageState();
}

class _WithdrawDevicePageState extends State<WithdrawDevicePage> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _cityController;
  late final TextEditingController _technicianNameController;
  late final TextEditingController _terminalIdController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _damagePartController;
  late final TextEditingController _notesController;

  String _battery = 'جيدة';
  String _chargerCable = 'موجود';
  String _chargerHead = 'موجود';
  String _hasSim = 'نعم';
  String _simCardType = 'أخرى';

  final List<String> _batteryOptions = ['جيدة', 'متوسطة', 'سيئة', 'لا توجد'];
  final List<String> _accessoryOptions = ['موجود', 'غير موجود', 'تالف'];
  final List<String> _simOptions = ['نعم', 'لا'];
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

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    _cityController = TextEditingController(text: authController.user?.city ?? '');
    _technicianNameController = TextEditingController(text: authController.user?.fullName ?? '');
    _terminalIdController = TextEditingController();
    _serialNumberController = TextEditingController();
    _damagePartController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _technicianNameController.dispose();
    _terminalIdController.dispose();
    _serialNumberController.dispose();
    _damagePartController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(TextEditingController controller) async {
    final isSerial = controller == _serialNumberController;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWidget(
          title: isSerial ? 'مسح باركود الجهاز' : 'مسح رقم الجهاز',
          itemTypes: isSerial ? ScannerItemTypes.devices() : null,
          categoryHint: isSerial ? 'devices' : null,
          allowUnionOfItemTypes: true,
          rawBarcodeMode: !isSerial,
        ),
      ),
    );
    final cleanResult = _extractScanCode(result);
    if (cleanResult != null && cleanResult.isNotEmpty) {
      if (isSerial) {
        final validationError = BarcodeValidator.validateAnyDevice(cleanResult);
        if (validationError != null) {
          Get.snackbar(
            'خطأ في مسح الباركود',
            validationError,
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }
      setState(() {
        controller.text = cleanResult;
      });
    }
  }

  String? _extractScanCode(dynamic result) {
    if (result == null) return null;
    if (result is String) return result.trim();
    if (result is Map) {
      final code = result['code'];
      if (code is String) return code.trim();
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final device = WithdrawnDevice(
        city: _cityController.text.trim(),
        technicianName: _technicianNameController.text.trim(),
        terminalId: _terminalIdController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        battery: _battery,
        chargerCable: _chargerCable,
        chargerHead: _chargerHead,
        hasSim: _hasSim,
        simCardType: _hasSim == 'نعم' ? _simCardType : null,
        damagePart: _damagePartController.text.trim().isNotEmpty ? _damagePartController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final controller = Get.find<DevicesController>();
      controller.submitWithdrawnDevice(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: RasscoAppBar(
        titleText: 'withdraw_device_title'.tr,
      ),
      body: Directionality(
        textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: GetBuilder<DevicesController>(
          builder: (controller) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_return_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'withdraw_new_device'.tr,
                                  style: TextStyle(fontFamily: 'BeIN', 
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'withdraw_description'.tr,
                                  style: TextStyle(fontFamily: 'BeIN', 
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card Form Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // المدينة
                          _buildTextField(
                            controller: _cityController,
                            label: 'city'.tr,
                            hint: 'enter_city'.tr,
                            icon: Icons.location_city,
                            validator: (val) => val == null || val.trim().isEmpty ? 'enter_city'.tr : null,
                          ),
                          const SizedBox(height: 16),

                          // اسم الفني/المندوب
                          _buildTextField(
                            controller: _technicianNameController,
                            label: 'technician_name'.tr,
                            hint: 'enter_technician_name'.tr,
                            icon: Icons.person,
                            validator: (val) => val == null || val.trim().isEmpty ? 'enter_technician_name'.tr : null,
                          ),
                          const SizedBox(height: 16),

                          // رقم الجهاز Terminal ID
                          _buildTextField(
                            controller: _terminalIdController,
                            label: 'device_id'.tr,
                            hint: 'enter_device_id'.tr,
                            icon: Icons.terminal,
                            validator: (val) => val == null || val.trim().isEmpty ? 'enter_device_id'.tr : null,
                            suffix: IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              onPressed: () => _scanBarcode(_terminalIdController),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // الرقم التسلسلي Serial Number
                          _buildTextField(
                            controller: _serialNumberController,
                            label: 'serial_number_label'.tr,
                            hint: 'enter_serial'.tr,
                            icon: Icons.smartphone,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'enter_serial'.tr;
                              }
                              return BarcodeValidator.validateAnyDevice(val);
                            },
                            suffix: IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                              onPressed: () => _scanBarcode(_serialNumberController),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const Divider(color: Colors.white10),
                          const SizedBox(height: 10),
                          Text(
                            'accessories_status'.tr,
                            style: TextStyle(fontFamily: 'BeIN', 
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // حالة البطارية
                          _buildDropdownField(
                            label: 'battery_status'.tr,
                            value: _battery,
                            items: _batteryOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _battery = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // كابل الشاحن
                          _buildDropdownField(
                            label: 'charger_cable_status'.tr,
                            value: _chargerCable,
                            items: _accessoryOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _chargerCable = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // رأس الشاحن
                          _buildDropdownField(
                            label: 'charger_head_status'.tr,
                            value: _chargerHead,
                            items: _accessoryOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _chargerHead = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // شريحة الاتصال
                          _buildDropdownField(
                            label: 'has_sim_status'.tr,
                            value: _hasSim,
                            items: _simOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _hasSim = val);
                            },
                          ),
                          
                          if (_hasSim == 'نعم') ...[
                            const SizedBox(height: 16),
                            // نوع الشريحة
                            _buildDropdownField(
                              label: 'sim_type_status'.tr,
                              value: _simCardType,
                              items: _simTypes,
                              onChanged: (val) {
                                if (val != null) setState(() => _simCardType = val);
                              },
                            ),
                          ],
                          const SizedBox(height: 16),

                          // الأعطال والضرر
                          _buildTextField(
                            controller: _damagePartController,
                            label: 'damage_if_any'.tr,
                            hint: 'describe_damage'.tr,
                            icon: Icons.report_problem_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // ملاحظات عامة
                          _buildTextField(
                            controller: _notesController,
                            label: 'notes_additional'.tr,
                            hint: 'enter_additional_notes'.tr,
                            icon: Icons.note_alt_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: controller.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'register_withdrawal'.tr,
                              style: TextStyle(fontFamily: 'BeIN', 
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'BeIN', 
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontFamily: 'BeIN', color: Colors.white30, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              style: TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 14),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
