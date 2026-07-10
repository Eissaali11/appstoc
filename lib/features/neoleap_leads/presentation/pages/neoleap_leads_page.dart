import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../controllers/neoleap_leads_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/design_system.dart';

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

  // ── UI Helpers ──────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (controller.apiKeyStatus.value) {
      case ApiKeyStatus.valid:
        return AppColors.success;
      case ApiKeyStatus.invalid:
        return AppColors.error;
      case ApiKeyStatus.checking:
        return AppColors.warning;
      case ApiKeyStatus.idle:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (controller.apiKeyStatus.value) {
      case ApiKeyStatus.valid:
        return 'api_key_connected'.tr;
      case ApiKeyStatus.invalid:
        return 'api_key_invalid'.tr;
      case ApiKeyStatus.checking:
        return 'api_key_checking'.tr;
      case ApiKeyStatus.idle:
        return 'api_key_idle'.tr;
    }
  }

  Widget _statusIcon() {
    switch (controller.apiKeyStatus.value) {
      case ApiKeyStatus.checking:
        return const PulsingDot(color: AppColors.warning, size: 8);
      case ApiKeyStatus.valid:
        return const PulsingDot(color: AppColors.success, size: 8);
      case ApiKeyStatus.invalid:
        return const PulsingDot(color: AppColors.error, size: 8);
      case ApiKeyStatus.idle:
        return const PulsingDot(color: AppColors.textSecondary, size: 8);
    }
  }

  // ── Phone Dialog ─────────────────────────────────────────────────────────
  void _showPhoneDialog(LeadEntity lead) {
    _phoneCtrl.text = lead.phone ?? '';
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      lead.phone == null ? 'add_phone'.tr : 'edit_phone'.tr,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى إدخال رقم الهاتف للتواصل المباشر مع العميل عبر الواتساب والمكالمات.',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.robotoMono(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '966XXXXXXXXX',
                    hintStyle: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 13),
                    labelText: 'whats_chat'.tr,
                    labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    prefixIcon: const Icon(LucideIcons.phone, color: AppColors.textSecondary, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'cancel'.tr,
                        style: GoogleFonts.cairo(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        controller.updateLeadPhone(lead.id, _phoneCtrl.text.trim());
                        Get.back();
                      },
                      child: Text(
                        'save'.tr,
                        style: GoogleFonts.cairo(
                          color: AppColors.backgroundDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete Confirmation Dialog ───────────────────────────────────────────
  void _confirmDeleteLead(LeadEntity lead) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'حذف عميل محتمل',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'هل أنت متأكد من رغبتك في حذف العميل "${lead.name}"؟ لا يمكن التراجع عن هذا الإجراء.',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'cancel'.tr,
                        style: GoogleFonts.cairo(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        controller.deleteLead(lead.id);
                        Get.back();
                        Get.snackbar(
                          'تم الحذف',
                          'تم إزالة العميل بنجاح من القائمة',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.error,
                          colorText: Colors.white,
                        );
                      },
                      child: Text(
                        'حذف',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
      body: Obx(() => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ── Error Banner ─────────────────────────────────────────────────
            if (controller.error.value.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(controller.error.value,
                      style: GoogleFonts.cairo(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: AppColors.error),
                    onPressed: () => controller.error.value = '',
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                ]),
              ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // ── API Key Card ─────────────────────────────────────────────────
                  _buildApiKeyCard(),
                  const SizedBox(height: 16),

                  // ── Search & Filter Criteria ─────────────────────────────────────
                  _buildSearchCard(),
                  const SizedBox(height: 20),

                  // ── Live Stats Summary ───────────────────────────────────────────
                  _buildStatsSection(),
                  const SizedBox(height: 20),

                  // ── Filter and Export Action Bar ─────────────────────────────────
                  _buildFilterAndExportBar(),
                  const SizedBox(height: 12),

                  // ── Results Label ────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة العملاء المستخرجين',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${controller.filteredLeads.length} عميل محتمل',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Leads List ───────────────────────────────────────────────────
                  controller.filteredLeads.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.filteredLeads.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _leadCard(controller.filteredLeads[i]),
                        ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  // ── API Key Card ──────────────────────────────────────────────────────────
  Widget _buildApiKeyCard() {
    final status = controller.apiKeyStatus.value;
    final isChecking = status == ApiKeyStatus.checking;

    return GlassCard(
      borderColor: _statusColor.withOpacity(0.3),
      backgroundColor: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.key, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'google_places_settings'.tr,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _statusIcon(),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (controller.apiKey.value.isNotEmpty)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                  tooltip: 'api_key_clear'.tr,
                  onPressed: () {
                    _apiKeyCtrl.clear();
                    controller.clearApiKey();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: _obscureKey,
            style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13, letterSpacing: 0.5),
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              labelText: 'أدخل المفتاح واضغط ✓ للاتصال',
              labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
              hintStyle: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 12),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(LucideIcons.shield, size: 18, color: AppColors.textSecondary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off, size: 18, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                  IconButton(
                    icon: isChecking
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : const Icon(Icons.check_circle_outline, size: 22, color: AppColors.primary),
                    onPressed: isChecking
                        ? null
                        : () => controller.saveAndValidateApiKey(_apiKeyCtrl.text),
                  ),
                ],
              ),
            ),
            onSubmitted: (val) => controller.saveAndValidateApiKey(val),
          ),
          const SizedBox(height: 8),
          Text(
            'بعد إدخال المفتاح اضغط ✓ أو Enter للتحقق التلقائي من الاتصال',
            style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Search Card ───────────────────────────────────────────────────────────
  Widget _buildSearchCard() {
    return GlassCard(
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'خيارات استخراج واستكشاف العملاء',
            icon: LucideIcons.compass,
          ),
          const SizedBox(height: 8),

          // Query field
          TextField(
            controller: _queryCtrl,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'search_query_hint'.tr,
              hintText: 'supermarket_hint'.tr,
              labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
              hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 12),
              prefixIcon: const Icon(LucideIcons.store, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Radius slider
          Row(
            children: [
              Expanded(
                child: Text(
                  '${'radius_meters'.tr}: ${(_radius / 1000).toStringAsFixed(1)} ${'km'.tr}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                flex: 2,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.2),
                    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  ),
                  child: Slider(
                    value: _radius,
                    min: 1000,
                    max: 10000,
                    divisions: 9,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Regions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'regions_selection'.tr,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: controller.selectAllRegions,
                    child: Text(
                      'select_all'.tr,
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: controller.deselectAllRegions,
                    child: Text(
                      'deselect_all'.tr,
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Regions scrollable chips list
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: RegionEntity.saudiRegions.length,
              itemBuilder: (_, i) {
                final r = RegionEntity.saudiRegions[i];
                final selected = controller.selectedRegions.any((s) => s.name == r.name);
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GestureDetector(
                    onTap: () => controller.toggleRegion(r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(r.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            r.name,
                            style: GoogleFonts.cairo(
                              color: selected ? AppColors.primary : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Search button
          NeonButton(
            label: controller.isLoading.value ? 'searching'.tr : 'search_button'.tr,
            icon: LucideIcons.downloadCloud,
            isLoading: controller.isLoading.value,
            onPressed: !controller.isApiKeyValid
                ? null
                : () => controller.searchPlaces(
                      query: _queryCtrl.text.trim(),
                      radius: _radius.toInt(),
                    ),
          ),
        ],
      ),
    );
  }

  // ── Stats Section ────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _statCardItem(
            'total_leads'.tr,
            '${controller.totalLeads}',
            LucideIcons.store,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCardItem(
            'with_phone'.tr,
            '${controller.leadsWithPhone}',
            LucideIcons.phone,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statCardItem(
            'sent_leads'.tr,
            '${controller.sentCount}',
            LucideIcons.checkSquare,
            AppColors.accentPurple,
          ),
        ),
      ],
    );
  }

  Widget _statCardItem(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderColor: color.withOpacity(0.2),
      backgroundColor: color.withOpacity(0.04),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Filter and Export Action Bar ─────────────────────────────────────────
  Widget _buildFilterAndExportBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchFilterCtrl,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
            onChanged: controller.filterLeads,
            decoration: InputDecoration(
              hintText: 'search_leads_hint'.tr,
              hintStyle: GoogleFonts.cairo(color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: controller.totalLeads == 0 ? null : controller.exportToCSV,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: controller.totalLeads == 0 ? Colors.white.withOpacity(0.02) : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: controller.totalLeads == 0 ? Colors.white.withOpacity(0.05) : AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Icon(
              LucideIcons.fileSpreadsheet,
              color: controller.totalLeads == 0 ? Colors.white24 : AppColors.success,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── Lead Card ─────────────────────────────────────────────────────────────
  Widget _leadCard(LeadEntity lead) {
    final hasPhone = lead.phone != null && lead.phone!.trim().isNotEmpty;
    final cardBorderColor = lead.isSent
        ? AppColors.success.withOpacity(0.2)
        : AppColors.primary.withOpacity(0.15);

    return GlassCard(
      borderColor: cardBorderColor,
      backgroundColor: AppColors.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    if (lead.address != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              lead.address!,
                              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (lead.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${lead.rating}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    text: lead.isSent ? 'sent_leads'.tr : 'pending'.tr,
                    color: lead.isSent ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.edit2, size: 15, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showPhoneDialog(lead),
                        tooltip: 'edit_phone'.tr,
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 15, color: AppColors.error),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _confirmDeleteLead(lead),
                        tooltip: 'حذف',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: hasPhone
                    ? Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            lead.phone!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      )
                    : TextButton.icon(
                        onPressed: () => _showPhoneDialog(lead),
                        icon: const Icon(LucideIcons.plus, size: 13, color: AppColors.primary),
                        label: Text(
                          'add_phone'.tr,
                          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  // Navigate map
                  _circleIconButton(
                    icon: LucideIcons.navigation,
                    color: AppColors.info,
                    onPressed: () => _openMap(lead.latitude, lead.longitude, lead.name),
                    tooltip: 'location'.tr,
                  ),
                  if (hasPhone) ...[
                    // Call phone
                    _circleIconButton(
                      icon: LucideIcons.phoneCall,
                      color: AppColors.primary,
                      onPressed: () => _launchCall(lead.phone!),
                      tooltip: 'call'.tr,
                    ),
                    // WhatsApp
                    _circleIconButton(
                      icon: LucideIcons.messageSquare,
                      color: AppColors.success,
                      onPressed: () => _launchWhatsApp(lead.phone!, lead.name),
                      tooltip: 'whats_chat'.tr,
                    ),
                  ],
                  if (!lead.isSent)
                    // Mark contacted
                    _circleIconButton(
                      icon: LucideIcons.checkSquare,
                      color: AppColors.success,
                      onPressed: () => controller.markLeadAsSent(lead.id),
                      tooltip: 'mark_as_sent'.tr,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 15),
          ),
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.store, size: 48, color: Colors.white.withOpacity(0.15)),
            ),
            const SizedBox(height: 12),
            Text(
              'no_leads_found'.tr,
              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
