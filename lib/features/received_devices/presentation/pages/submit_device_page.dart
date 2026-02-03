import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/devices_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../data/models/received_device.dart';

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
  
  bool _battery = false;
  bool _chargerCable = false;
  bool _chargerHead = false;
  bool _hasSim = false;
  String? _simCardType;

  final List<String> _simTypes = ['موبايلي', 'STC', 'زين', 'أخرى'];

  @override
  void dispose() {
    _terminalIdController.dispose();
    _serialNumberController.dispose();
    _damagePartController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<DevicesController>();
      
      final device = ReceivedDevice(
        terminalId: _terminalIdController.text.trim(),
        serialNumber: _serialNumberController.text.trim(),
        battery: _battery,
        chargerCable: _chargerCable,
        chargerHead: _chargerHead,
        hasSim: _hasSim,
        simCardType: _hasSim ? (_simCardType ?? _simTypes[0]) : null,
        damagePart: _damagePartController.text.trim(),
      );

      controller.submitDevice(device);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DevicesController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'إدخال بيانات جهاز',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smartphone,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أدخل بيانات الجهاز المستلم',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Terminal ID
            _buildTextField(
              controller: _terminalIdController,
              label: 'رقم الجهاز (Terminal ID)',
              icon: Icons.tag,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال رقم الجهاز';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Serial Number
            _buildTextField(
              controller: _serialNumberController,
              label: 'الرقم التسلسلي (Serial Number)',
              icon: Icons.qr_code,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الرقم التسلسلي';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Accessories Section
            Text(
              'الملحقات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildCheckbox(
              title: 'بطارية',
              value: _battery,
              icon: Icons.battery_charging_full,
              onChanged: (value) => setState(() => _battery = value!),
            ),
            const SizedBox(height: 8),
            _buildCheckbox(
              title: 'كابل الشاحن',
              value: _chargerCable,
              icon: Icons.cable,
              onChanged: (value) => setState(() => _chargerCable = value!),
            ),
            const SizedBox(height: 8),
            _buildCheckbox(
              title: 'رأس الشاحن',
              value: _chargerHead,
              icon: Icons.power,
              onChanged: (value) => setState(() => _chargerHead = value!),
            ),
            const SizedBox(height: 24),

            // SIM Card Section
            _buildCheckbox(
              title: 'يحتوي على شريحة SIM',
              value: _hasSim,
              icon: Icons.sim_card,
              onChanged: (value) => setState(() => _hasSim = value!),
            ),
            if (_hasSim) ...[
              const SizedBox(height: 12),
              _buildDropdown(
                label: 'نوع الشريحة',
                value: _simCardType ?? _simTypes[0],
                items: _simTypes,
                onChanged: (value) => setState(() => _simCardType = value),
              ),
            ],
            const SizedBox(height: 24),

            // Damage Part
            _buildTextField(
              controller: _damagePartController,
              label: 'الجزء المتضرر',
              icon: Icons.warning,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الجزء المتضرر';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            Obx(() => ElevatedButton.icon(
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
                controller.isLoading ? 'جاري الإرسال...' : 'إرسال',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.textSecondary,
              ),
            )),
            const SizedBox(height: 100),
          ],
        ),
      )),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.cairo(color: Colors.white),
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.primary : AppColors.border.withOpacity(0.1),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.white,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
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
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
          prefixIcon: Icon(Icons.sim_card, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        dropdownColor: AppColors.surfaceDark,
        style: GoogleFonts.cairo(color: Colors.white),
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      ),
    );
  }
}
