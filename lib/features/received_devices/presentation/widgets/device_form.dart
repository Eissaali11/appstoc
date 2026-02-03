import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';

class DeviceForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const DeviceForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<DeviceForm> {
  final _formKey = GlobalKey<FormState>();
  final _terminalIdController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _damagePartController = TextEditingController();
  
  bool _battery = false;
  bool _chargerCable = false;
  bool _chargerHead = false;
  bool _hasSim = false;
  String? _simCardType;

  final List<String> _simTypes = ['Micro SIM', 'Nano SIM', 'eSIM'];

  @override
  void dispose() {
    _terminalIdController.dispose();
    _serialNumberController.dispose();
    _damagePartController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit({
      'terminalId': _terminalIdController.text.trim(),
      'serialNumber': _serialNumberController.text.trim(),
      'battery': _battery,
      'chargerCable': _chargerCable,
      'chargerHead': _chargerHead,
      'hasSim': _hasSim,
      'simCardType': _hasSim ? _simCardType : null,
      'damagePart': _damagePartController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _terminalIdController,
              decoration: const InputDecoration(
                labelText: 'رقم الجهاز',
                prefixIcon: Icon(Icons.devices),
              ),
              textDirection: TextDirection.rtl,
              validator: (value) => Validators.required(value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _serialNumberController,
                    decoration: const InputDecoration(
                      labelText: 'الرقم التسلسلي',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) => Validators.required(value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    // TODO: Open barcode scanner
                  },
                  tooltip: 'مسح الباركود',
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('بطارية'),
              value: _battery,
              onChanged: (value) => setState(() => _battery = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('كابل الشاحن'),
              value: _chargerCable,
              onChanged: (value) => setState(() => _chargerCable = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('رأس الشاحن'),
              value: _chargerHead,
              onChanged: (value) => setState(() => _chargerHead = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('يحتوي شريحة'),
              value: _hasSim,
              onChanged: (value) {
                setState(() {
                  _hasSim = value ?? false;
                  if (!_hasSim) {
                    _simCardType = null;
                  }
                });
              },
            ),
            if (_hasSim) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'نوع الشريحة',
                  prefixIcon: Icon(Icons.sim_card),
                ),
                value: _simCardType,
                items: _simTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _simCardType = value),
                validator: (value) => _hasSim && value == null
                    ? 'يجب اختيار نوع الشريحة'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _damagePartController,
              decoration: const InputDecoration(
                labelText: 'الجزء المتضرر',
                prefixIcon: Icon(Icons.warning),
              ),
              textDirection: TextDirection.rtl,
              maxLines: 3,
              validator: (value) => Validators.required(value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}
