import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/region_entity.dart';
import '../controllers/neoleap_leads_controller.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
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
  LeadEntity? _selectedMapLead;

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

  Future<void> _openMap(double lat, double lng, String name) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('خطأ', 'تعذّر تطبيق خرائط Google');
    }
  }

  Future<void> _launchCall(LeadEntity lead) async {
    if (lead.phone == null || lead.phone!.trim().isEmpty) {
      _showPhoneDialog(lead);
      return;
    }
    controller.updateLeadStatus(lead.id, LeadStatus.contacted);
    if (!await launchUrl(Uri.parse('tel:${lead.phone!}'))) {
      Get.snackbar('خطأ', 'تعذّر إجراء الاتصال');
    }
  }

  // ── Build Screen with 4 TabBar Tabs ────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Obx(() => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: RasscoAppBar(
            titleText: 'اكتشاف الأنشطة الجغرافية',
            bottom: TabBar(
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                const Tab(text: '📡 الإعدادات والقالب'),
                Tab(text: '📋 جميع العملاء (${controller.totalLeads})'),
                Tab(text: '💬 تمت المراسلة (${controller.contactedCount})'),
                Tab(text: '⏳ متبقي للمراسلة (${controller.pendingCount})'),
              ],
            ),
          ),
          body: Container(
            color: AppColors.backgroundLight,
            child: TabBarView(
              children: [
                _buildDiscoveryTab(),
                _buildAllLeadsTab(),
                _buildContactedLeadsTab(),
                _buildPendingLeadsTab(),
              ],
            ),
          ),
        ),
      )),
    );
  }

  // ── Tab 1: Discovery & Settings Tab ───────────────────────────────────────
  Widget _buildDiscoveryTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderNoticeBanner(),
        const SizedBox(height: 12),
        if (controller.error.value.isNotEmpty) _buildErrorBanner(),
        _buildDiscoverySetupCard(),
        const SizedBox(height: 16),
        _buildWhatsAppTemplateCard(),
        const SizedBox(height: 16),
        if (controller.isDiscovering.value || controller.jobPlacesFound.value > 0)
          _buildJobProgressCard(),
      ],
    );
  }

  // ── Tab 2: All Discovered Leads Tab ───────────────────────────────────────
  Widget _buildAllLeadsTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderNoticeBanner(),
        const SizedBox(height: 12),
        _buildStatsRow(),
        const SizedBox(height: 16),
        _buildFilterAndSearchRow(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الأنشطة المكتشفة (${controller.filteredLeads.length})',
              style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
        controller.isMapView.value
            ? _buildMapViewPlaceholder()
            : (controller.filteredLeads.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.filteredLeads.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _buildLeadCard(controller.filteredLeads[index]),
                  )),
      ],
    );
  }

  // ── Tab 3: Contacted Leads Tab ───────────────────────────────────────────
  Widget _buildContactedLeadsTab() {
    final contactedLeads = controller.leads.where((l) => l.isSent || l.leadStatus == LeadStatus.contacted || l.leadStatus == LeadStatus.visited || l.leadStatus == LeadStatus.won).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderNoticeBanner(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تمت مراسلة ووُجّهت العروض لـ ${contactedLeads.length} عميل من أصل ${controller.totalLeads}',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        contactedLeads.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.messageSquare, size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('لم تقم بمراسلة أي عميل بعد', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
                      Text('انتقل لتبويب "متبقي للمراسلة" للبدء في التواصل الفوري مع العملاء', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contactedLeads.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _buildLeadCard(contactedLeads[index]),
              ),
      ],
    );
  }

  // ── Tab 4: Pending Uncontacted Leads Tab ─────────────────────────────────
  Widget _buildPendingLeadsTab() {
    final pendingLeads = controller.leads.where((l) => !l.isSent && l.leadStatus != LeadStatus.contacted && l.leadStatus != LeadStatus.visited && l.leadStatus != LeadStatus.won).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderNoticeBanner(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.clock, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'متبقي ${pendingLeads.length} عميل بانتظار المراسلة والتواصل',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        pendingLeads.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.partyPopper, size: 44, color: AppColors.success),
                      const SizedBox(height: 12),
                      Text('أحسنت! تمت مراسلة جميع العملاء المكتشفين 🎉', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Text('قم بتشغيل الاكتشاف الجغرافي لسحب أنشطة تجارية جديدة', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingLeads.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _buildLeadCard(pendingLeads[index]),
              ),
      ],
    );
  }

  // ── Header Notice Banner ──────────────────────────────────────────────────
  Widget _buildHeaderNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.compass, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نظام اكتشاف العملاء الجغرافي (Saudi Geo Leads)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                ),
                Text(
                  'يتم حفظ جميع العملاء وحالات المراسلة تلقائياً وتحديث التبويبات فورياً.',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
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

          // Regional Hierarchy Selection (6 Core Regions + Sub-cities & Villages)
          _buildRegionalSelectionSection(),
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
            height: 50,
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
                controller.isDiscovering.value
                    ? 'جارٍ فحص المناطق واكتشاف الأنشطة...'
                    : 'جلب بيانات الأنشطة التجارية حسب تحديد المناطق (${controller.selectedSubCities.length} مدينة وهجرة)',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalSelectionSection() {
    final activeGroup = RegionEntity.mainSaudiRegions.firstWhere(
      (g) => g.id == controller.activeMainRegionId.value,
      orElse: () => RegionEntity.mainSaudiRegions.first,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.map, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'اختيار المناطق والمدن والقرى والهجر المستهدفة:',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'اختر المنطقة الرئيسية لعرض كافة المدن والقرى والهجر التابعة لها:',
            style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          // Main Regions Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: RegionEntity.mainSaudiRegions.map((group) {
                final isSelected = controller.activeMainRegionId.value == group.id;
                final selectedCitiesCount = group.cities.where((c) => controller.isSubCitySelected(c)).length;

                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: InkWell(
                    onTap: () => controller.selectMainRegionTab(group.id),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Text(group.emoji, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            group.nameAr,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          if (selectedCitiesCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$selectedCitiesCount',
                                style: GoogleFonts.cairo(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primary : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Sub-Cities & Villages Container for Active Main Region
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'المدن والقرى والهجر التابعة لـ ${activeGroup.nameAr} (${activeGroup.cities.length} موقع):',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero),
                          onPressed: () => controller.selectAllSubCitiesForRegion(activeGroup.id),
                          icon: const Icon(LucideIcons.checkCheck, size: 13, color: AppColors.success),
                          label: Text('تحديد الكل', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero),
                          onPressed: () => controller.deselectAllSubCitiesForRegion(activeGroup.id),
                          icon: const Icon(LucideIcons.x, size: 13, color: AppColors.error),
                          label: Text('إلغاء', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: activeGroup.cities.map((city) {
                    final isSelected = controller.isSubCitySelected(city);
                    return FilterChip(
                      label: Text('${city.emoji} ${city.name}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          )),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.backgroundLight,
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                      onSelected: (_) => controller.toggleSubCity(city),
                    );
                  }).toList(),
                ),
              ],
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
  // ── Interactive Map View Component ───────────────────────────────────────
  Widget _buildMapViewPlaceholder() {
    final centerLat = controller.currentLat.value;
    final centerLng = controller.currentLng.value;
    final radius = controller.radiusKm.value;
    final leadsToDisplay = controller.filteredLeads;

    final activeLead = (_selectedMapLead != null && leadsToDisplay.any((l) => l.id == _selectedMapLead!.id))
        ? _selectedMapLead
        : (leadsToDisplay.isNotEmpty ? leadsToDisplay.first : null);

    final mapZoom = (radius <= 10) ? 13 : ((radius <= 35) ? 11 : 9);
    final String staticMapUrl = controller.apiKey.value.isNotEmpty
        ? 'https://maps.googleapis.com/maps/api/staticmap?center=$centerLat,$centerLng&zoom=$mapZoom&size=800x420&scale=2&maptype=roadmap&key=${controller.apiKey.value}'
        : 'https://staticmap.openstreetmap.de/staticmap.php?center=$centerLat,$centerLng&zoom=$mapZoom&size=800x420&markers=$centerLat,$centerLng,ol-marker';

    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Live Google Map / OSM Tile Image Background inside the App
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    staticMapUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (ctx, err, stack) {
                      return CustomPaint(
                        painter: _RadarMapPainter(radiusKm: radius),
                        size: Size.infinite,
                      );
                    },
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return Stack(
                        children: [
                          CustomPaint(
                            painter: _RadarMapPainter(radiusKm: radius),
                            size: Size.infinite,
                          ),
                          const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ],
                      );
                    },
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
          ),

          // 2. Interactive Lead Pins plotted on Map Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final double spanDeg = (radius <= 0 ? 5 : radius) / 80.0;

              return Stack(
                children: [
                  // Center Technician Position (Blue Radar Beacon)
                  Positioned(
                    left: width / 2 - 16,
                    top: height / 2 - 16,
                    child: Tooltip(
                      message: 'موقع التواجد (موقعي)',
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.crosshair, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  // Pins for discovered leads
                  for (final lead in leadsToDisplay) ...[
                    Builder(
                      builder: (ctx) {
                        final dLng = lead.longitude - centerLng;
                        final dLat = centerLat - lead.latitude;

                        final normX = (dLng / spanDeg).clamp(-1.0, 1.0);
                        final normY = (dLat / spanDeg).clamp(-1.0, 1.0);

                        final leftPos = (width / 2) + (normX * (width / 2.3)) - 16;
                        final topPos = (height / 2) + (normY * (height / 2.3)) - 16;

                        final isSelected = activeLead?.id == lead.id;
                        final isContacted = lead.isSent || lead.leadStatus == LeadStatus.contacted || lead.leadStatus == LeadStatus.visited || lead.leadStatus == LeadStatus.won;
                        final pinColor = isContacted ? AppColors.success : (lead.phone != null ? AppColors.warning : AppColors.primary);

                        return Positioned(
                          left: leftPos,
                          top: topPos,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMapLead = lead;
                              });
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 1.3 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: pinColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: pinColor.withValues(alpha: 0.6),
                                      blurRadius: isSelected ? 10 : 4,
                                      spreadRadius: isSelected ? 2 : 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isContacted ? LucideIcons.check : LucideIcons.store,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),

          // 3. Top Action Overlay Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${leadsToDisplay.length} نشاط جغرافي',
                        style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openMap(centerLat, centerLng, 'نطاق الأنشطة المكتشفة'),
                  icon: const Icon(LucideIcons.externalLink, size: 14, color: Colors.white),
                  label: Text('فتح في Google Maps', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Selected Lead Pop-up Card
          if (activeLead != null)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
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
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeLead.name,
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                activeLead.category,
                                style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '•  ${activeLead.distanceKm.toStringAsFixed(1)} كم',
                                style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionCircleBtn(LucideIcons.navigation, AppColors.secondaryBlue, () => _openMap(activeLead.latitude, activeLead.longitude, activeLead.name), 'ملاحة'),
                        const SizedBox(width: 4),
                        _actionCircleBtn(LucideIcons.phoneCall, AppColors.primary, () => _launchCall(activeLead), 'اتصال'),
                        const SizedBox(width: 4),
                        _actionCircleBtn(LucideIcons.messageSquare, AppColors.success, () => _launchWhatsApp(activeLead), 'واتساب'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
                    _actionCircleBtn(LucideIcons.phoneCall, AppColors.primary, () => _launchCall(lead), 'اتصال'),
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

class _RadarMapPainter extends CustomPainter {
  final int radiusKm;
  _RadarMapPainter({required this.radiusKm});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.2;

    final paintCircle = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxRadius * 0.33, paintCircle);
    canvas.drawCircle(center, maxRadius * 0.66, paintCircle);
    canvas.drawCircle(center, maxRadius, paintCircle);

    final paintAxis = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paintAxis);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paintAxis);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
