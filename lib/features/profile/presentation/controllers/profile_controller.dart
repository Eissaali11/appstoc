import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/utils/ui_helper.dart';
import '../../data/datasources/employee_profile_remote_data_source.dart';
import '../../data/models/employee_profile_model.dart';

class ProfileFieldItem {
  final String label;
  final String value;
  final IconData? icon;

  const ProfileFieldItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

class ProfileController extends GetxController {
  final EmployeeProfileRemoteDataSource remote;

  ProfileController(this.remote);

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isEditing = false.obs;
  final username = ''.obs;
  final jobTitle = ''.obs;
  final employeeNumber = ''.obs;
  final displayName = ''.obs;
  final profileImageUrl = ''.obs;

  /// Filled fields for professional view mode
  final filledPersonal = <ProfileFieldItem>[].obs;
  final filledJob = <ProfileFieldItem>[].obs;
  final filledCustody = <ProfileFieldItem>[].obs;
  final missingFields = <String>[].obs;

  final fullNameCtrl = TextEditingController();
  final nationalIdCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final birthDateCtrl = TextEditingController();
  final idExpiryCtrl = TextEditingController();
  final sponsorCtrl = TextEditingController();
  final licenseExpiryCtrl = TextEditingController();
  final passportCtrl = TextEditingController();
  final passportExpiryCtrl = TextEditingController();
  final nationalityCtrl = TextEditingController();
  final absherCtrl = TextEditingController();
  final qualificationCtrl = TextEditingController();
  final projectCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final carPlateCtrl = TextEditingController();
  final carTypeCtrl = TextEditingController();
  final carModelCtrl = TextEditingController();
  final carYearCtrl = TextEditingController();
  final phoneTypeCtrl = TextEditingController();
  final phoneSerialCtrl = TextEditingController();
  final businessPhoneCtrl = TextEditingController();
  final simType = 'eSIM'.obs;

  final jobOfferFile = Rxn<EmployeeStoredFile>();
  final carHandoverFile = Rxn<EmployeeStoredFile>();
  final otherFiles = <EmployeeStoredFile>[].obs;

  String? _userId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in [
      fullNameCtrl,
      nationalIdCtrl,
      phoneCtrl,
      birthDateCtrl,
      idExpiryCtrl,
      sponsorCtrl,
      licenseExpiryCtrl,
      passportCtrl,
      passportExpiryCtrl,
      nationalityCtrl,
      absherCtrl,
      qualificationCtrl,
      projectCtrl,
      cityCtrl,
      carPlateCtrl,
      carTypeCtrl,
      carModelCtrl,
      carYearCtrl,
      phoneTypeCtrl,
      phoneSerialCtrl,
      businessPhoneCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  void startEditing() => isEditing.value = true;

  void cancelEditing() {
    isEditing.value = false;
    // Reload from last saved server state
    load();
  }

  Future<void> load() async {
    final auth = Get.find<AuthController>();
    final user = auth.user;
    if (user == null) return;

    _userId = user.id;
    username.value = user.username;
    fullNameCtrl.text = user.fullName;
    displayName.value = user.fullName;
    profileImageUrl.value = user.profileImage ?? '';
    cityCtrl.text = user.city ?? '';

    try {
      isLoading.value = true;
      final res = await remote.getProfile(user.id);
      _applyResponse(res);
      isEditing.value = false;
      _rebuildViewLists();
    } catch (e) {
      UIHelper.showErrorSnackBar('تعذر تحميل الملف الشخصي: $e');
      _rebuildViewLists();
    } finally {
      isLoading.value = false;
    }
  }

  void _applyResponse(EmployeeProfileResponse res) {
    username.value = res.username;
    fullNameCtrl.text = res.fullName;
    displayName.value = res.fullName;
    profileImageUrl.value = res.profileImage ?? profileImageUrl.value;
    final p = res.profile;
    jobTitle.value = p.jobTitle ?? (res.role == 'technician' ? 'مندوب / فني' : res.role);
    employeeNumber.value = p.employeeNumber ?? '';
    nationalIdCtrl.text = p.nationalId ?? '';
    phoneCtrl.text = p.phoneNumber ?? '';
    birthDateCtrl.text = p.birthDate ?? '';
    idExpiryCtrl.text = p.nationalIdExpiryDate ?? '';
    sponsorCtrl.text = p.sponsorName ?? '';
    licenseExpiryCtrl.text = p.licenseExpiryDate ?? '';
    passportCtrl.text = p.passportNumber ?? '';
    passportExpiryCtrl.text = p.passportExpiryDate ?? '';
    nationalityCtrl.text = p.nationality ?? '';
    absherCtrl.text = p.absherNumber ?? '';
    qualificationCtrl.text = p.qualification ?? '';
    projectCtrl.text = p.projectName ?? '';
    cityCtrl.text = p.city ?? cityCtrl.text;
    carPlateCtrl.text = p.carPlateNumber ?? '';
    carTypeCtrl.text = p.carType ?? '';
    carModelCtrl.text = p.carModel ?? '';
    carYearCtrl.text = p.carYear ?? '';
    phoneTypeCtrl.text = p.phoneType ?? '';
    phoneSerialCtrl.text = p.phoneSerial ?? '';
    businessPhoneCtrl.text = p.businessPhoneNumber ?? '';
    simType.value = p.simType?.isNotEmpty == true ? p.simType! : 'eSIM';
    jobOfferFile.value = p.jobOfferFile;
    carHandoverFile.value = p.carHandoverFile;
    otherFiles.assignAll(p.otherFiles);
  }

  bool _has(String? v) => v != null && v.trim().isNotEmpty;

  void _rebuildViewLists() {
    final personal = <ProfileFieldItem>[];
    final missing = <String>[];

    void addText({
      required List<ProfileFieldItem> target,
      required String labelKey,
      required String value,
      IconData? icon,
      bool trackMissing = true,
    }) {
      final label = labelKey.tr;
      if (_has(value)) {
        target.add(ProfileFieldItem(label: label, value: value.trim(), icon: icon));
      } else if (trackMissing) {
        missing.add(label);
      }
    }

    addText(target: personal, labelKey: 'profile_full_name', value: fullNameCtrl.text, icon: Icons.person);
    addText(target: personal, labelKey: 'profile_national_id', value: nationalIdCtrl.text, icon: Icons.badge);
    addText(target: personal, labelKey: 'profile_phone', value: phoneCtrl.text, icon: Icons.phone);
    addText(target: personal, labelKey: 'profile_birth_date', value: birthDateCtrl.text, icon: Icons.cake_outlined);
    addText(target: personal, labelKey: 'profile_id_expiry', value: idExpiryCtrl.text, icon: Icons.event);
    addText(target: personal, labelKey: 'profile_sponsor', value: sponsorCtrl.text, icon: Icons.business);
    addText(target: personal, labelKey: 'profile_license_expiry', value: licenseExpiryCtrl.text, icon: Icons.event_available);
    addText(target: personal, labelKey: 'profile_passport', value: passportCtrl.text, icon: Icons.menu_book);
    addText(target: personal, labelKey: 'profile_passport_expiry', value: passportExpiryCtrl.text, icon: Icons.event);
    addText(target: personal, labelKey: 'profile_nationality', value: nationalityCtrl.text, icon: Icons.public);
    addText(target: personal, labelKey: 'profile_absher', value: absherCtrl.text, icon: Icons.verified_user);
    addText(target: personal, labelKey: 'profile_qualification', value: qualificationCtrl.text, icon: Icons.school);

    final job = <ProfileFieldItem>[
      ProfileFieldItem(label: 'profile_username'.tr, value: '@${username.value}', icon: Icons.lock_outline),
      ProfileFieldItem(
        label: 'profile_job_title'.tr,
        value: jobTitle.value.isEmpty ? '—' : jobTitle.value,
        icon: Icons.work_outline,
      ),
    ];
    if (_has(employeeNumber.value)) {
      job.add(ProfileFieldItem(
        label: 'profile_employee_number'.tr,
        value: employeeNumber.value,
        icon: Icons.tag,
      ));
    }
    addText(target: job, labelKey: 'profile_project', value: projectCtrl.text, icon: Icons.apartment);
    addText(target: job, labelKey: 'city', value: cityCtrl.text, icon: Icons.location_city);

    if (jobOfferFile.value != null) {
      job.add(ProfileFieldItem(
        label: 'profile_job_offer'.tr,
        value: jobOfferFile.value!.name,
        icon: Icons.insert_drive_file,
      ));
    } else {
      missing.add('profile_job_offer'.tr);
    }
    if (otherFiles.isNotEmpty) {
      job.add(ProfileFieldItem(
        label: 'profile_other_files'.tr,
        value: '${otherFiles.length}/5 — ${otherFiles.map((e) => e.name).join(' · ')}',
        icon: Icons.folder_open,
      ));
    }

    final custody = <ProfileFieldItem>[];
    addText(target: custody, labelKey: 'profile_car_plate', value: carPlateCtrl.text, icon: Icons.directions_car);
    addText(target: custody, labelKey: 'profile_car_type', value: carTypeCtrl.text, icon: Icons.directions_car_filled);
    addText(target: custody, labelKey: 'profile_car_model', value: carModelCtrl.text, icon: Icons.car_rental);
    addText(target: custody, labelKey: 'profile_car_year', value: carYearCtrl.text, icon: Icons.calendar_today);
    if (carHandoverFile.value != null) {
      custody.add(ProfileFieldItem(
        label: 'profile_car_handover'.tr,
        value: carHandoverFile.value!.name,
        icon: Icons.upload_file,
      ));
    } else {
      missing.add('profile_car_handover'.tr);
    }
    addText(target: custody, labelKey: 'profile_phone_type', value: phoneTypeCtrl.text, icon: Icons.smartphone);
    addText(target: custody, labelKey: 'profile_phone_imei', value: phoneSerialCtrl.text, icon: Icons.qr_code);
    addText(target: custody, labelKey: 'profile_work_number', value: businessPhoneCtrl.text, icon: Icons.phone_in_talk);
    final hasPhoneCustody = _has(phoneTypeCtrl.text) || _has(phoneSerialCtrl.text) || _has(businessPhoneCtrl.text);
    if (hasPhoneCustody && _has(simType.value)) {
      custody.add(ProfileFieldItem(
        label: 'profile_sim_type'.tr,
        value: simType.value,
        icon: Icons.sim_card,
      ));
    } else if (!hasPhoneCustody) {
      missing.add('profile_sim_type'.tr);
    }

    filledPersonal.assignAll(personal);
    filledJob.assignAll(job);
    filledCustody.assignAll(custody);
    missingFields.assignAll(missing);
  }

  Future<void> pickSingleFile({
    required void Function(EmployeeStoredFile file) onPicked,
  }) async {
    try {
      final source = await Get.bottomSheet<ImageSource>(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2F36),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF18B2B0)),
                title: Text('camera'.tr, style: const TextStyle(color: Colors.white, fontFamily: 'BeIN')),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF18B2B0)),
                title: Text('gallery'.tr, style: const TextStyle(color: Colors.white, fontFamily: 'BeIN')),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;
      final file = await remote.pickImageAsStoredFile(source: source);
      if (file != null) onPicked(file);
    } catch (e) {
      UIHelper.showErrorSnackBar('$e');
    }
  }

  Future<void> addOtherFile() async {
    if (otherFiles.length >= 5) {
      UIHelper.showErrorSnackBar('يمكن رفع 5 مرفقات كحد أقصى');
      return;
    }
    await pickSingleFile(onPicked: (f) => otherFiles.add(f));
  }

  Future<void> pickProfilePhoto() async {
    try {
      final source = await Get.bottomSheet<ImageSource>(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2F36),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF18B2B0)),
                title: Text('camera'.tr, style: const TextStyle(color: Colors.white, fontFamily: 'BeIN')),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF18B2B0)),
                title: Text('gallery'.tr, style: const TextStyle(color: Colors.white, fontFamily: 'BeIN')),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;
      final dataUrl = await remote.pickProfileImageDataUrl(source: source);
      if (dataUrl != null) profileImageUrl.value = dataUrl;
    } catch (e) {
      UIHelper.showErrorSnackBar('$e');
    }
  }

  Future<void> clearProfilePhoto() async {
    profileImageUrl.value = '';
  }

  Future<void> save() async {
    if (_userId == null) return;

    try {
      isSaving.value = true;
      final profile = EmployeeProfileData(
        nationalId: nationalIdCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        birthDate: birthDateCtrl.text.trim(),
        nationalIdExpiryDate: idExpiryCtrl.text.trim(),
        sponsorName: sponsorCtrl.text.trim(),
        licenseExpiryDate: licenseExpiryCtrl.text.trim(),
        passportNumber: passportCtrl.text.trim(),
        passportExpiryDate: passportExpiryCtrl.text.trim(),
        nationality: nationalityCtrl.text.trim(),
        absherNumber: absherCtrl.text.trim(),
        qualification: qualificationCtrl.text.trim(),
        projectName: projectCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        carPlateNumber: carPlateCtrl.text.trim(),
        carType: carTypeCtrl.text.trim(),
        carModel: carModelCtrl.text.trim(),
        carYear: carYearCtrl.text.trim(),
        phoneType: phoneTypeCtrl.text.trim(),
        phoneSerial: phoneSerialCtrl.text.trim(),
        businessPhoneNumber: businessPhoneCtrl.text.trim(),
        simType: simType.value,
        jobOfferFile: jobOfferFile.value,
        carHandoverFile: carHandoverFile.value,
        otherFiles: List.of(otherFiles),
      );

      final res = await remote.saveProfile(
        userId: _userId!,
        profile: profile,
        profileImage: profileImageUrl.value,
      );
      _applyResponse(res);
      _rebuildViewLists();
      isEditing.value = false;

      final auth = Get.find<AuthController>();
      await auth.applyLocalUserPatch(
        city: cityCtrl.text.trim(),
        profileImage: profileImageUrl.value,
      );
      await auth.checkAuth();

      UIHelper.showSuccessSnackBar('تم حفظ الملف الشخصي بنجاح');
    } catch (e) {
      UIHelper.showErrorSnackBar('فشل الحفظ: $e');
    } finally {
      isSaving.value = false;
    }
  }
}
