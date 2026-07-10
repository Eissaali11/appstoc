import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../controllers/neoleap_leads_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class NeoleapLeadsPage extends StatefulWidget {
  const NeoleapLeadsPage({super.key});

  @override
  State<NeoleapLeadsPage> createState() => _NeoleapLeadsPageState();
}

class _NeoleapLeadsPageState extends State<NeoleapLeadsPage> {
  final NeoleapLeadsController controller = Get.find<NeoleapLeadsController>();
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _queryCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _searchFilterCtrl = TextEditingController();

  double _radius = 5000;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyCtrl.text = controller.apiKey.value;
    ever(controller.apiKey, (val) {
      if (_apiKeyCtrl.text != val) _apiKeyCtrl.text = val;
    });
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _queryCtrl.dispose();
    _phoneCtrl.dispose();
    _searchFilterCtrl.dispose();
    super.dispose();
  }

  // ── UI helpers ──────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (controller.apiKeyStatus.value) {
      case ApiKeyStatus.valid:
        return Colors.green;
      case ApiKeyStatus.invalid:
        return Colors.red;
      case ApiKeyStatus.checking:
        return Colors.orange;
      case ApiKeyStatus.idle:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (controller.apiKeyStatus.value) {
      case ApiKeyStatus.valid:
        return 'متصل ✅';
      case ApiKeyStatus.invalid:
        return 'غير صالح ❌';
      case ApiKeyStatus.checking:
        return 'جاري التحقق...';
      case ApiKeyStatus.idle:
        return 'لم يتم الاتصال';
    }
  }

  Widget _statusIcon() {
    switch (controller.apiKeyStatus.value) {
      case ApiKeyStatus.checking:
        return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
        );
      case ApiKeyStatus.valid:
        return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case ApiKeyStatus.invalid:
        return const Icon(Icons.cancel, color: Colors.red, size: 18);
      case ApiKeyStatus.idle:
        return const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18);
    }
  }

  // ── Phone dialog ─────────────────────────────────────────────────────────
  void _showPhoneDialog(LeadEntity lead) {
    _phoneCtrl.text = lead.phone ?? '';
    Get.defaultDialog(
      title: lead.phone == null ? 'add_phone'.tr : 'edit_phone'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '966XXXXXXXXX',
            labelText: 'whats_chat'.tr,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.phone),
          ),
        ),
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
        onPressed: () {
          controller.updateLeadPhone(lead.id, _phoneCtrl.text.trim());
          Get.back();
        },
        child: Text('save'.tr, style: const TextStyle(color: Colors.white)),
      ),
      cancel: TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
    );
  }

  Future<void> _launchWhatsApp(String phone, String name) async {
    var p = phone.replaceAll(RegExp(r'\s+|-|\+'), '');
    if (!p.startsWith('966') && p.startsWith('5')) p = '966$p';
    final msg = Uri.encodeComponent('مرحباً عميلنا الكريم في $name، نحن من خدمة عملاء Neoleap للمدفوعات الرقمية. هل ترغب بطلب جهاز POS؟');
    final uri = Uri.parse('https://wa.me/$p?text=$msg');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('error'.tr, 'whatsapp_not_installed'.tr);
    }
  }

  Future<void> _launchCall(String phone) async {
    if (!await launchUrl(Uri.parse('tel:$phone'))) {
      Get.snackbar('error'.tr, 'cannot_launch_dialer'.tr);
    }
  }

  Future<void> _openMap(double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('error'.tr, 'cannot_open_map'.tr);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'leads_title'.tr,
      body: Obx(() => Column(
        children: [
          // ── API Key Card ─────────────────────────────────────────────────
          _buildApiKeyCard(),

          // ── Error banner ─────────────────────────────────────────────────
          if (controller.error.value.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(controller.error.value,
                    style: const TextStyle(color: Colors.red, fontSize: 13))),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16, color: Colors.red),
                  onPressed: () => controller.error.value = '',
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ]),
            ),

          // ── Search card ──────────────────────────────────────────────────
          _buildSearchCard(),

          // ── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              Expanded(child: _statCard('total_leads'.tr, '${controller.totalLeads}',
                  Colors.blue.shade50, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('with_phone'.tr, '${controller.leadsWithPhone}',
                  Colors.green.shade50, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('sent_leads'.tr, '${controller.sentCount}',
                  Colors.teal.shade50, Colors.teal)),
            ]),
          ),

          // ── Filter + export row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchFilterCtrl,
                  onChanged: controller.filterLeads,
                  decoration: InputDecoration(
                    hintText: 'search_leads_hint'.tr,
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onPressed: controller.totalLeads == 0 ? null : controller.exportToCSV,
                icon: const Icon(LucideIcons.fileSpreadsheet, color: Colors.white, size: 18),
                label: Text('export_csv'.tr, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
          ),

          // ── Leads list ───────────────────────────────────────────────────
          Expanded(
            child: controller.filteredLeads.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(LucideIcons.store, size: 52, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('no_leads_found'.tr,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: controller.filteredLeads.length,
                    itemBuilder: (_, i) => _leadCard(controller.filteredLeads[i]),
                  ),
          ),
        ],
      )),
    );
  }

  // ── API Key Card ──────────────────────────────────────────────────────────
  Widget _buildApiKeyCard() {
    final status = controller.apiKeyStatus.value;
    final isChecking = status == ApiKeyStatus.checking;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: _statusColor.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.vpn_key_rounded, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مفتاح Google Places API',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Row(children: [
                  _statusIcon(),
                  const SizedBox(width: 5),
                  Text(_statusLabel,
                      style: TextStyle(fontSize: 12, color: _statusColor,
                          fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            if (controller.apiKey.value.isNotEmpty)
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                tooltip: 'مسح المفتاح',
                onPressed: () {
                  _apiKeyCtrl.clear();
                  controller.clearApiKey();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ]),

          const SizedBox(height: 10),

          // API Key input field
          TextField(
            controller: _apiKeyCtrl,
            obscureText: _obscureKey,
            style: const TextStyle(fontSize: 13, letterSpacing: 0.5),
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              labelText: 'أدخل المفتاح واضغط ✓ للاتصال',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.key, size: 18),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off, size: 18),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  tooltip: _obscureKey ? 'إظهار' : 'إخفاء',
                ),
                IconButton(
                  icon: isChecking
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, size: 22, color: Colors.blue),
                  onPressed: isChecking
                      ? null
                      : () => controller.saveAndValidateApiKey(_apiKeyCtrl.text),
                  tooltip: 'تحقق واتصل',
                ),
              ]),
            ),
            onSubmitted: (val) => controller.saveAndValidateApiKey(val),
          ),

          // Error message
          if (controller.apiKeyError.value.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(controller.apiKeyError.value,
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],

          // Hint
          const SizedBox(height: 6),
          Text(
            'بعد إدخال المفتاح اضغط ✓ أو Enter للتحقق التلقائي من الاتصال',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
        ]),
      ),
    );
  }

  // ── Search Card ───────────────────────────────────────────────────────────
  Widget _buildSearchCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Query field
          TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              labelText: 'search_query_hint'.tr,
              hintText: 'supermarket_hint'.tr,
              prefixIcon: const Icon(LucideIcons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          // Radius slider
          Row(children: [
            Expanded(child: Text(
              '${'radius_meters'.tr}: ${(_radius / 1000).toStringAsFixed(1)} ${'km'.tr}',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            )),
            Expanded(flex: 2, child: Slider(
              value: _radius, min: 1000, max: 10000, divisions: 9,
              onChanged: (v) => setState(() => _radius = v),
            )),
          ]),

          // Regions
          const SizedBox(height: 4),
          Text('regions_selection'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            ActionChip(
              label: Text('select_all'.tr, style: const TextStyle(fontSize: 12)),
              onPressed: controller.selectAllRegions,
            ),
            const SizedBox(width: 8),
            ActionChip(
              label: Text('deselect_all'.tr, style: const TextStyle(fontSize: 12)),
              onPressed: controller.deselectAllRegions,
            ),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: RegionEntity.saudiRegions.length,
              itemBuilder: (_, i) {
                final r = RegionEntity.saudiRegions[i];
                final selected = controller.selectedRegions.any((s) => s.name == r.name);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text('${r.emoji} ${r.name}'),
                    selected: selected,
                    onSelected: (_) => controller.toggleRegion(r),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Search button
          SizedBox(
            width: double.infinity, height: 48,
            child: Obx(() => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isApiKeyValid
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: controller.isLoading.value || !controller.isApiKeyValid
                  ? null
                  : () => controller.searchPlaces(
                        query: _queryCtrl.text.trim(),
                        radius: _radius.toInt(),
                      ),
              icon: controller.isLoading.value
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.downloadCloud, color: Colors.white),
              label: Text(
                controller.isLoading.value
                    ? 'searching'.tr
                    : controller.isApiKeyValid
                        ? 'search_button'.tr
                        : 'أدخل مفتاح API أولاً',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )),
          ),
        ]),
      ),
    );
  }

  // ── Stat card ─────────────────────────────────────────────────────────────
  Widget _statCard(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            textAlign: TextAlign.center),
      ]),
    );
  }

  // ── Lead card ─────────────────────────────────────────────────────────────
  Widget _leadCard(LeadEntity lead) {
    final hasPhone = lead.phone != null && lead.phone!.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lead.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (lead.address != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(LucideIcons.mapPin, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(child: Text(lead.address!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
              ],
              if (lead.rating != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star, size: 14, color: Colors.orange),
                  const SizedBox(width: 2),
                  Text('${lead.rating}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ],
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lead.isSent ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  lead.isSent ? 'sent_leads'.tr : 'pending'.tr,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: lead.isSent ? Colors.green : Colors.amber.shade800),
                ),
              ),
              const SizedBox(height: 6),
              IconButton(
                icon: const Icon(LucideIcons.edit2, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                onPressed: () => _showPhoneDialog(lead),
                tooltip: 'edit_phone'.tr,
              ),
            ]),
          ]),
          const Divider(height: 16),
          Row(children: [
            Expanded(child: hasPhone
                ? Row(children: [
                    const Icon(LucideIcons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(lead.phone!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ])
                : TextButton.icon(
                    onPressed: () => _showPhoneDialog(lead),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: Text('add_phone'.tr, style: const TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  )),
            Wrap(spacing: 4, children: [
              IconButton(
                icon: const Icon(LucideIcons.navigation, color: Colors.indigo, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _openMap(lead.latitude, lead.longitude, lead.name),
                tooltip: 'location'.tr,
              ),
              if (hasPhone) ...[
                IconButton(
                  icon: const Icon(LucideIcons.phoneCall, color: Colors.blue, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _launchCall(lead.phone!),
                  tooltip: 'call'.tr,
                ),
                IconButton(
                  icon: const Icon(LucideIcons.messageSquare, color: Colors.green, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _launchWhatsApp(lead.phone!, lead.name),
                  tooltip: 'whats_chat'.tr,
                ),
              ],
              if (!lead.isSent)
                IconButton(
                  icon: const Icon(LucideIcons.checkSquare, color: Colors.green, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => controller.markLeadAsSent(lead.id),
                  tooltip: 'mark_as_sent'.tr,
                ),
            ]),
          ]),
        ]),
      ),
    );
  }
}
