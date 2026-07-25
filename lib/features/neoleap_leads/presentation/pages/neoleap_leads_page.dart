import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/lead_entity.dart';
import '../controllers/neoleap_leads_controller.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../core/theme/app_colors.dart';

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

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.discovered:
      case LeadStatus.unassigned:
        return const Color(0xFF2563EB); // Blue
      case LeadStatus.assigned:
      case LeadStatus.contacted:
        return AppColors.primary; // Corporate Turquoise
      case LeadStatus.visitPlanned:
      case LeadStatus.visited:
        return const Color(0xFF7C3AED); // Purple
      case LeadStatus.interested:
      case LeadStatus.won:
        return AppColors.success; // Green
      case LeadStatus.negotiation:
        return AppColors.warning; // Orange
      case LeadStatus.lost:
      case LeadStatus.notEligible:
        return AppColors.error; // Red
      case LeadStatus.duplicate:
        return AppColors.textMuted; // Gray
    }
  }

  // ── Phone Editing Dialog ──────────────────────────────────────────────────
  void _showPhoneDialog(LeadEntity lead) {
    _phoneCtrl.text = lead.phone ?? '';
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      lead.phone == null ? 'إضافة رقم الهاتف' : 'تعديل رقم الهاتف',
                      style: GoogleFonts.cairo(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل رقم الهاتف للتواصل المباشر مع العميل عبر الواتساب والمكالمات الهاتفية.',
                  style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.robotoMono(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '9665XXXXXXXX',
                    hintStyle: GoogleFonts.robotoMono(color: AppColors.textMuted, fontSize: 13),
                    labelText: 'رقم الهاتف / الواتساب',
                    labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
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
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    prefixIcon: const Icon(LucideIcons.phoneCall, color: AppColors.primary, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('إلغاء', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        controller.updateLeadPhone(lead.id, _phoneCtrl.text.trim());
                        Get.back();
                      },
                      child: Text('حفظ التغييرات', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ── Status Action Sheet ────────────────────────────────────────────────────
  void _showStatusUpdateSheet(LeadEntity lead) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تحديث حالة العميل الميداني',
                    style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lead.name,
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 20, color: AppColors.border),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LeadStatus.values.map((status) {
                  final isSelected = lead.leadStatus == status;
                  final statusColor = _getStatusColor(status);
                  return ChoiceChip(
                    label: Text(status.labelAr, style: GoogleFonts.cairo(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.textPrimary)),
                    selected: isSelected,
                    selectedColor: statusColor,
                    backgroundColor: AppColors.backgroundLight,
                    side: BorderSide(color: isSelected ? statusColor : AppColors.border),
                    onSelected: (val) {
                      if (val) {
                        controller.updateLeadStatus(lead.id, status);
                        Get.back();
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(LeadEntity lead) async {
    if (lead.phone == null || lead.phone!.trim().isEmpty) {
      _showPhoneDialog(lead);
      return;
    }
    var p = lead.phone!.replaceAll(RegExp(r'\s+|-|\+'), '');
    if (!p.startsWith('966') && p.startsWith('5')) p = '966$p';
    final msgText = controller.buildFormattedWhatsAppMsg(lead);
    final msgEncoded = Uri.encodeComponent(msgText);
    final uri = Uri.parse('https://wa.me/$p?text=$msgEncoded');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('خطأ', 'تعذّر فتح تطبيق الواتساب');
    }
  }

  Future<void> _launchCall(String phone) async {
    if (!await launchUrl(Uri.parse('tel:$phone'))) {
      Get.snackbar('خطأ', 'تعذّر إجراء الاتصال');
    }
  }

  Future<void> _openMap(double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('خطأ', 'تعذّر تطبيق خرائط Google');
    }
  }

  // ── Build Screen ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'اكتشاف الأنشطة التجارية القريبة',
      body: Obx(() => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          color: AppColors.backgroundLight,
          child: Column(
            children: [
              // ── Header Notice Banner ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.compass, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'نظام اكتشاف العملاء الجغرافي (Saudi Geo Leads)',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'سيتم البحث عن الأنشطة ضمن النطاق المحدد وإضافتها لقائمتك بعد إزالة التكرار.',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Main Content Scroll View ──────────────────────────────────
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Error alert if present
                    if (controller.error.value.isNotEmpty) _buildErrorBanner(),

                    // 1. Discovery Setup Card
                    _buildDiscoverySetupCard(),
                    const SizedBox(height: 16),

                    // 1.5. WhatsApp Marketing Message Template Editor
                    _buildWhatsAppTemplateCard(),
                    const SizedBox(height: 16),

                    // 2. Live Job Progress Metrics Card (if running or completed)
                    if (controller.isDiscovering.value || controller.jobPlacesFound.value > 0)
                      _buildJobProgressCard(),
                    if (controller.isDiscovering.value || controller.jobPlacesFound.value > 0)
                      const SizedBox(height: 16),

                    // 3. Stats & Counters Overview
                    _buildStatsRow(),
                    const SizedBox(height: 16),

                    // 4. View Mode Toggle & Filter Bar
                    _buildFilterAndSearchRow(),
                    const SizedBox(height: 12),

                    // 5. Results Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الأنشطة المكتشفة (${controller.filteredLeads.length})',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'النطاق النشط: ${controller.radiusKm.value} كم',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(LucideIcons.fileSpreadsheet, size: 18, color: AppColors.success),
                              tooltip: 'تصدير كـ CSV',
                              onPressed: controller.exportToCSV,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 6. Map or List Representation
                    controller.isMapView.value
                        ? _buildMapViewPlaceholder()
                        : (controller.filteredLeads.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.filteredLeads.length,
                                separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                                itemBuilder: (ctx, i) => _buildLeadCard(controller.filteredLeads[i]),
                              )),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  // ── Error Banner ──────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.error.value,
              style: GoogleFonts.cairo(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 16, color: AppColors.error),
            onPressed: () => controller.error.value = '',
          ),
        ],
      ),
    );
  }

  // ── Discovery Setup Card ──────────────────────────────────────────────────
  Widget _buildDiscoverySetupCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technician Location Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الموقع الحالي للفني',
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${controller.currentCityName.value} — ${controller.currentRegionName.value}',
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 12),
                    const SizedBox(width: 4),
                    Text('GPS نشط', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          // API Key Connection Box
          _buildApiKeyField(),
          const SizedBox(height: 16),

          // Search Radius Slider (Default 25km, Max 150km)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نطاق البحث الجغرافي:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Text('${controller.radiusKm.value} كم', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primaryGlow,
            ),
            child: Slider(
              value: controller.radiusKm.value.toDouble(),
              min: 5,
              max: 150,
              divisions: 29,
              label: '${controller.radiusKm.value} كم',
              onChanged: (val) => controller.radiusKm.value = val.round(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 كم', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted)),
              Text('25 كم (افتراضي)', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
              Text('50 كم', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted)),
              Text('150 كم (أقصى نطاق)', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 16),

          // Category Chips Selection
          Text('فئات الأنشطة المستهدفة بالبحث:', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BusinessCategoryOption.availableCategories.map((cat) {
              final isSelected = controller.selectedCategoryIds.contains(cat.id);
              return FilterChip(
                label: Text('${cat.iconEmoji} ${cat.titleAr}', style: GoogleFonts.cairo(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.backgroundLight,
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                onSelected: (_) => controller.toggleCategory(cat.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Discovery Trigger Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: controller.isDiscovering.value
                  ? null
                  : () => controller.startGeoDiscoveryJob(customQuery: _queryCtrl.text.trim()),
              icon: controller.isDiscovering.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.radar, color: Colors.white, size: 20),
              label: Text(
                controller.isDiscovering.value ? 'جارٍ فحص المناطق واكتشاف الأنشطة...' : 'اكتشاف العملاء القريبين',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField() {
    final status = controller.apiKeyStatus.value;
    final isChecking = status == ApiKeyStatus.checking;
    final isValid = status == ApiKeyStatus.valid;

    String statusText;
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    if (isChecking) {
      statusText = 'جاري الفحص...';
      statusColor = AppColors.info;
      statusBg = AppColors.infoLight;
      statusIcon = LucideIcons.refreshCw;
    } else if (isValid) {
      statusText = 'متصل';
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
      statusIcon = LucideIcons.checkCircle2;
    } else {
      statusText = 'غير متصل';
      statusColor = AppColors.error;
      statusBg = AppColors.errorLight;
      statusIcon = LucideIcons.xCircle;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isValid ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.key, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إعدادات مفتاح Google Places API',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isChecking)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                      )
                    else
                      Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: _obscureKey,
            style: GoogleFonts.robotoMono(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off, size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid ? AppColors.success : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: isChecking
                        ? null
                        : () => controller.saveAndValidateApiKey(_apiKeyCtrl.text),
                    icon: isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.plugZap, size: 16, color: Colors.white),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isChecking ? 'جاري الفحص...' : 'فحص الاتصال بـ API',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  _apiKeyCtrl.text = 'AIzaSyDDugb3nnytT46ALy6E1ER-F9mk3TKOvkE';
                  controller.saveAndValidateApiKey(_apiKeyCtrl.text);
                },
                icon: const Icon(LucideIcons.rotateCcw, size: 14, color: AppColors.textSecondary),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'الافتراضي',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          if (controller.apiKeyError.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              controller.apiKeyError.value,
              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  // ── Discovery Progress Metrics Card ───────────────────────────────────────
  Widget _buildJobProgressCard() {
    final double progressRatio = controller.jobTotalCells.value == 0
        ? 0.0
        : (controller.jobCurrentCell.value / controller.jobTotalCells.value).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.cpu, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.isDiscovering.value ? 'جارٍ تنفيذ مسح المربعات الجغرافية' : 'اكتملت مهمة الاكتشاف الجغرافي الأخيرة',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${(progressRatio * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: Colors.white,
              color: AppColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _metricTile('المربعات', '${controller.jobCurrentCell.value}/${controller.jobTotalCells.value}')),
              Expanded(child: _metricTile('الأماكن', '${controller.jobPlacesFound.value}')),
              Expanded(child: _metricTile('جدد', '${controller.jobNewLeadsAdded.value}', color: AppColors.success)),
              Expanded(child: _metricTile('مكرر', '${controller.jobDuplicatesSkipped.value}', color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? AppColors.primaryDark)),
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  // ── Stats Summary Row ────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statBox('إجمالي العملاء', '${controller.totalLeads}', LucideIcons.store, AppColors.secondaryBlue)),
        const SizedBox(width: 8),
        Expanded(child: _statBox('تم التواصل', '${controller.contactedCount}', LucideIcons.phoneCall, AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _statBox('مهتمون بالخدمة', '${controller.interestedCount}', LucideIcons.sparkles, AppColors.success)),
      ],
    );
  }

  Widget _statBox(String label, String val, IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: col),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Filter and Search Bar ─────────────────────────────────────────────────
  Widget _buildFilterAndSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchFilterCtrl,
            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textPrimary),
            onChanged: controller.filterLeads,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم، النشاط، أو العنوان...',
              hintStyle: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
              prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Map vs List Toggle Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            icon: Icon(
              controller.isMapView.value ? LucideIcons.list : LucideIcons.map,
              color: AppColors.primary,
              size: 20,
            ),
            tooltip: controller.isMapView.value ? 'عرض القائمة' : 'عرض الخريطة التفاعلية',
            onPressed: () => controller.isMapView.value = !controller.isMapView.value,
          ),
        ),
      ],
    );
  }

  // ── Interactive Map Representation View ──────────────────────────────────
  Widget _buildMapViewPlaceholder() {
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          // Background grid styling for map representation
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFFE5E7EB),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.mapPin, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        'خريطة اكتشاف العملاء الميدانية',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'عرض موقع الفني ونطاق ${controller.radiusKm.value} كم والأماكن المكتشفة',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statusDot('جديد', const Color(0xFF2563EB)),
                  _statusDot('تم التواصل', AppColors.primary),
                  _statusDot('مهتم', AppColors.success),
                  _statusDot('موعد', const Color(0xFF7C3AED)),
                  _statusDot('مكرر', AppColors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(String label, Color col) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textPrimary)),
      ],
    );
  }

  // ── Lead Card Widget ──────────────────────────────────────────────────────
  Widget _buildLeadCard(LeadEntity lead) {
    final hasPhone = lead.phone != null && lead.phone!.trim().isNotEmpty;
    final statusColor = _getStatusColor(lead.leadStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
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
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(6)),
                          child: Text(lead.category, style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.navigation, size: 10, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          'تبعد ${lead.distanceKm.toStringAsFixed(1)} كم',
                          style: GoogleFonts.cairo(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showStatusUpdateSheet(lead),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        lead.leadStatus.labelAr,
                        style: GoogleFonts.cairo(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (lead.formattedAddress != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lead.formattedAddress!,
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (lead.rating != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 13, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  '${lead.rating} (${lead.ratingCount ?? 0} مراجعة)',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const Divider(height: 16, color: AppColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: hasPhone
                    ? Text(
                        lead.phone!,
                        style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showPhoneDialog(lead),
                          icon: const Icon(LucideIcons.plus, size: 12, color: AppColors.primary),
                          label: Text('إضافة رقم الهاتف', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primary)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        ),
                      ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionCircleBtn(LucideIcons.navigation, AppColors.secondaryBlue, () => _openMap(lead.latitude, lead.longitude, lead.name), 'ملاحة'),
                  if (hasPhone) ...[
                    const SizedBox(width: 4),
                    _actionCircleBtn(LucideIcons.phoneCall, AppColors.primary, () => _launchCall(lead.phone!), 'اتصال'),
                    const SizedBox(width: 4),
                    _actionCircleBtn(LucideIcons.messageSquare, AppColors.success, () => _launchWhatsApp(lead), 'واتساب'),
                  ],
                  const SizedBox(width: 4),
                  _actionCircleBtn(LucideIcons.edit2, AppColors.textMuted, () => _showPhoneDialog(lead), 'تعديل'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCircleBtn(IconData icon, Color col, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: col.withValues(alpha: 0.2)),
          ),
          child: Center(child: Icon(icon, color: col, size: 14)),
        ),
      ),
    );
  }

  // ── Empty State Widget ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.backgroundLight, shape: BoxShape.circle),
              child: const Icon(LucideIcons.radar, size: 40, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text('لم يتم العثور على أنشطة بهذه الفلاتر', style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 13)),
            Text('اضغط "اكتشاف العملاء القريبين" للبدء في سحب واكتشاف الأنشطة الجغرافية', style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── WhatsApp Marketing Template Card Widget ────────────────────────────────
  Widget _buildWhatsAppTemplateCard() {
    final TextEditingController templateCtrl = TextEditingController(text: controller.whatsappTemplate.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.messageSquare, color: AppColors.success, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قالب الرسالة التسويقية للواتساب',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      'تعديل نص الرسالة التلقائية المرسلة للأنشطة المكتشفة',
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: templateCtrl,
            maxLines: 3,
            style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'اكتب نص الرسالة التسويقية هنا...',
              contentPadding: const EdgeInsets.all(12),
              fillColor: AppColors.backgroundLight,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tagChip('+ اسم المحل', () {
                        templateCtrl.text += ' {lead_name}';
                      }),
                      const SizedBox(width: 4),
                      _tagChip('+ النشاط', () {
                        templateCtrl.text += ' {category}';
                      }),
                      const SizedBox(width: 4),
                      _tagChip('+ المدينة', () {
                        templateCtrl.text += ' {city}';
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () {
                  controller.saveWhatsAppTemplate(templateCtrl.text);
                },
                icon: const Icon(LucideIcons.save, size: 14, color: Colors.white),
                label: Text('حفظ القالب', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
    );
  }
}
