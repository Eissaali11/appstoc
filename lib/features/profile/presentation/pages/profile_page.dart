import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/ui_helper.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/rassco_app_bar.dart';
import '../controllers/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      body: Obx(() {
        final user = authController.user;
        if (user == null) return _LoggedOutView();

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                fullName: controller.displayName.value.isNotEmpty
                    ? controller.displayName.value
                    : controller.fullNameCtrl.text,
                username: controller.username.value,
                jobTitle: controller.jobTitle.value,
                employeeNumber: controller.employeeNumber.value,
                profileImage: controller.profileImageUrl.value,
                showEditPhoto: controller.isEditing.value,
                onEditPhoto: controller.pickProfilePhoto,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (controller.isEditing.value) ..._buildEditForm(authController) else ..._buildViewMode(),
                  const SizedBox(height: 14),
                  _LanguageBlock(),
                  const SizedBox(height: 14),
                  _LogoutButton(authController: authController),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildViewMode() {
    return [
      if (controller.filledPersonal.isNotEmpty)
        _ViewSection(
          icon: Icons.badge_outlined,
          title: 'profile_personal_section'.tr,
          items: controller.filledPersonal.toList(),
        ),
      if (controller.filledPersonal.isNotEmpty) const SizedBox(height: 14),
      if (controller.filledJob.isNotEmpty)
        _ViewSection(
          icon: Icons.work_outline_rounded,
          title: 'profile_job_section'.tr,
          items: controller.filledJob.toList(),
        ),
      if (controller.filledJob.isNotEmpty) const SizedBox(height: 14),
      if (controller.filledCustody.isNotEmpty)
        _ViewSection(
          icon: Icons.inventory_2_outlined,
          title: 'profile_custody_section'.tr,
          items: controller.filledCustody.toList(),
        ),
      if (controller.filledCustody.isNotEmpty) const SizedBox(height: 14),
      if (controller.filledPersonal.isEmpty &&
          controller.filledJob.length <= 2 &&
          controller.filledCustody.isEmpty)
        _EmptyProfileCard(),
      if (controller.missingFields.isNotEmpty) ...[
        _MissingFieldsCard(labels: controller.missingFields.toList()),
        const SizedBox(height: 14),
      ],
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: controller.startEditing,
          icon: const Icon(Icons.edit_rounded),
          label: Text(
            'profile_edit'.tr,
            style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildEditForm(AuthController authController) {
    return [
      _SectionCard(
        icon: Icons.badge_outlined,
        title: 'profile_personal_section'.tr,
        subtitle: 'profile_personal_hint'.tr,
        children: [
          _ReadOnlyField(label: 'profile_full_name'.tr, value: controller.displayName.value),
          _EditableField(label: 'profile_national_id'.tr, controller: controller.nationalIdCtrl, hint: '10XXXXXXXX'),
          _EditableField(label: 'profile_phone'.tr, controller: controller.phoneCtrl, hint: '05XXXXXXXX', keyboard: TextInputType.phone),
          _EditableField(label: 'profile_birth_date'.tr, controller: controller.birthDateCtrl, hint: 'yyyy-mm-dd'),
          _EditableField(label: 'profile_id_expiry'.tr, controller: controller.idExpiryCtrl, hint: 'yyyy-mm-dd'),
          _EditableField(label: 'profile_sponsor'.tr, controller: controller.sponsorCtrl),
          _EditableField(label: 'profile_license_expiry'.tr, controller: controller.licenseExpiryCtrl, hint: 'yyyy-mm-dd'),
          _EditableField(label: 'profile_passport'.tr, controller: controller.passportCtrl),
          _EditableField(label: 'profile_passport_expiry'.tr, controller: controller.passportExpiryCtrl, hint: 'yyyy-mm-dd'),
          _EditableField(label: 'profile_nationality'.tr, controller: controller.nationalityCtrl),
          _EditableField(label: 'profile_absher'.tr, controller: controller.absherCtrl),
          _EditableField(label: 'profile_qualification'.tr, controller: controller.qualificationCtrl, hint: 'بكالوريوس، ماجستير...'),
        ],
      ),
      const SizedBox(height: 14),
      _SectionCard(
        icon: Icons.work_outline_rounded,
        title: 'profile_job_section'.tr,
        subtitle: 'profile_job_hint'.tr,
        children: [
          _ReadOnlyField(label: 'profile_username'.tr, value: '@${controller.username.value}'),
          _ReadOnlyField(label: 'profile_job_title'.tr, value: controller.jobTitle.value),
          _ReadOnlyField(
            label: 'profile_employee_number'.tr,
            value: controller.employeeNumber.value.isEmpty ? '—' : controller.employeeNumber.value,
          ),
          _EditableField(label: 'profile_project'.tr, controller: controller.projectCtrl),
          _EditableField(label: 'city'.tr, controller: controller.cityCtrl),
          const SizedBox(height: 8),
          _FilePickerTile(
            title: 'profile_job_offer'.tr,
            fileName: controller.jobOfferFile.value?.name,
            onPick: () => controller.pickSingleFile(onPicked: (f) => controller.jobOfferFile.value = f),
            onClear: () => controller.jobOfferFile.value = null,
          ),
          _FilePickerTile(
            title: 'profile_other_files'.tr,
            fileName: controller.otherFiles.isEmpty ? null : '${controller.otherFiles.length}/5',
            subtitle: controller.otherFiles.map((e) => e.name).join(' · '),
            onPick: controller.addOtherFile,
            onClear: () => controller.otherFiles.clear(),
          ),
          const SizedBox(height: 4),
          Text(
            'profile_photo_hint'.tr,
            style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _SectionCard(
        icon: Icons.inventory_2_outlined,
        title: 'profile_custody_section'.tr,
        subtitle: 'profile_custody_hint'.tr,
        children: [
          Text(
            'profile_car_custody'.tr,
            style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
          ),
          const SizedBox(height: 8),
          _EditableField(label: 'profile_car_plate'.tr, controller: controller.carPlateCtrl),
          _EditableField(label: 'profile_car_type'.tr, controller: controller.carTypeCtrl),
          _EditableField(label: 'profile_car_model'.tr, controller: controller.carModelCtrl),
          _EditableField(label: 'profile_car_year'.tr, controller: controller.carYearCtrl),
          _FilePickerTile(
            title: 'profile_car_handover'.tr,
            fileName: controller.carHandoverFile.value?.name,
            onPick: () => controller.pickSingleFile(onPicked: (f) => controller.carHandoverFile.value = f),
            onClear: () => controller.carHandoverFile.value = null,
          ),
          const SizedBox(height: 12),
          Text(
            'profile_phone_custody'.tr,
            style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 15),
          ),
          const SizedBox(height: 8),
          _EditableField(label: 'profile_phone_type'.tr, controller: controller.phoneTypeCtrl),
          _EditableField(label: 'profile_phone_imei'.tr, controller: controller.phoneSerialCtrl),
          _EditableField(label: 'profile_work_number'.tr, controller: controller.businessPhoneCtrl, keyboard: TextInputType.phone),
          _SimTypeSelector(value: controller.simType),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.isSaving.value ? null : controller.cancelEditing,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('cancel'.tr, style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: controller.isSaving.value ? null : controller.save,
              icon: controller.isSaving.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: Text(
                controller.isSaving.value ? 'loading'.tr : 'profile_save'.tr,
                style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

class _EmptyProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add_alt_1, size: 42, color: AppColors.primary.withOpacity(0.8)),
          const SizedBox(height: 12),
          Text(
            'profile_empty_hint'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ViewSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<ProfileFieldItem> items;

  const _ViewSection({required this.icon, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceDark, AppColors.backgroundMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontFamily: 'BeIN', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x33FFFFFF)),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast = entry.key == items.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: const TextStyle(fontFamily: 'BeIN', fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(item.value, style: const TextStyle(fontFamily: 'BeIN', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MissingFieldsCard extends StatelessWidget {
  final List<String> labels;

  const _MissingFieldsCard({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'profile_missing_section'.tr,
                  style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${labels.length}',
                  style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'profile_missing_hint'.tr,
            style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                    ),
                    child: Text(label, style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String username;
  final String jobTitle;
  final String employeeNumber;
  final String? profileImage;
  final bool showEditPhoto;
  final VoidCallback? onEditPhoto;

  const _ProfileHeader({
    required this.fullName,
    required this.username,
    required this.jobTitle,
    required this.employeeNumber,
    this.profileImage,
    this.showEditPhoto = false,
    this.onEditPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark, Color(0xFF1F2328)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 28),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: RasscoAppBarLogo(height: 26),
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                profileImage: profileImage,
                size: 104,
                borderWidth: 3,
                borderColor: Colors.white.withOpacity(0.9),
              ),
              if (showEditPhoto)
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEditPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(fullName, style: const TextStyle(fontFamily: 'BeIN', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          if (jobTitle.isNotEmpty)
            Text(jobTitle, style: TextStyle(fontFamily: 'BeIN', fontSize: 14, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _HeaderChip(text: '@$username'),
              if (employeeNumber.isNotEmpty) _HeaderChip(text: employeeNumber),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final String text;
  const _HeaderChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(fontFamily: 'BeIN', fontSize: 13, color: Colors.white.withOpacity(0.95))),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceDark, AppColors.backgroundMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'BeIN', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;

  const _EditableField({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(fontFamily: 'BeIN', color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontFamily: 'BeIN', color: AppColors.textMuted.withOpacity(0.7), fontSize: 13),
              filled: true,
              fillColor: AppColors.backgroundDark.withOpacity(0.55),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.brandGray.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandGray.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: const TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 15))),
                const Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final String title;
  final String? fileName;
  final String? subtitle;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FilePickerTile({
    required this.title,
    required this.fileName,
    required this.onPick,
    required this.onClear,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null && fileName!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withOpacity(0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hasFile ? AppColors.primary.withOpacity(0.55) : AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(hasFile ? Icons.insert_drive_file : Icons.upload_file, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      hasFile ? (subtitle?.isNotEmpty == true ? subtitle! : fileName!) : 'profile_choose_file'.tr,
                      style: const TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hasFile)
                IconButton(onPressed: onClear, icon: const Icon(Icons.close, color: AppColors.error, size: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimTypeSelector extends StatelessWidget {
  final RxString value;
  const _SimTypeSelector({required this.value});

  @override
  Widget build(BuildContext context) {
    final options = ['eSIM', 'Physical SIM', 'Both'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('profile_sim_type'.tr, style: const TextStyle(fontFamily: 'BeIN', fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Obx(
            () => Wrap(
              spacing: 8,
              children: options.map((opt) {
                final selected = value.value == opt;
                return ChoiceChip(
                  label: Text(opt, style: TextStyle(fontFamily: 'BeIN', color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => value.value = opt,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.backgroundDark,
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.brandGray.withOpacity(0.4)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text('change_language'.tr, style: const TextStyle(fontFamily: 'BeIN', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LangChip(
                  label: 'language_ar'.tr,
                  selected: Get.locale?.languageCode == 'ar',
                  onTap: () async {
                    await LocalCache.setAppLanguage('ar');
                    Get.updateLocale(const Locale('ar'));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LangChip(
                  label: 'language_en'.tr,
                  selected: Get.locale?.languageCode == 'en',
                  onTap: () async {
                    await LocalCache.setAppLanguage('en');
                    Get.updateLocale(const Locale('en'));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.25) : AppColors.surfaceDark.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border.withOpacity(0.3), width: selected ? 2 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'BeIN',
              fontSize: 15,
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
              color: selected ? AppColors.primary : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final AuthController authController;
  const _LogoutButton({required this.authController});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: Text('confirm'.tr, style: const TextStyle(fontFamily: 'BeIN', color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text('logout_confirm'.tr, style: const TextStyle(fontFamily: 'BeIN', color: Colors.white)),
            actions: [
              TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr, style: const TextStyle(fontFamily: 'BeIN', color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: Text('logout'.tr, style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await authController.logout();
          if (authController.error != null) {
            UIHelper.showErrorSnackBar(authController.error!);
          }
        }
      },
      icon: const Icon(Icons.logout),
      label: Text('logout'.tr, style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('user_not_logged_in'.tr, style: const TextStyle(fontFamily: 'BeIN', fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/login'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('login'.tr, style: const TextStyle(fontFamily: 'BeIN', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
