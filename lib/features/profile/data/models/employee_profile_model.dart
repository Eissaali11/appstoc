import 'dart:convert';

class EmployeeStoredFile {
  final String name;
  final String type;
  final int size;
  final String dataUrl;
  final String uploadedAt;

  const EmployeeStoredFile({
    required this.name,
    required this.type,
    required this.size,
    required this.dataUrl,
    required this.uploadedAt,
  });

  factory EmployeeStoredFile.fromJson(Map<String, dynamic> json) {
    return EmployeeStoredFile(
      name: json['name'] as String? ?? 'file',
      type: json['type'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
      dataUrl: json['dataUrl'] as String? ?? '',
      uploadedAt: json['uploadedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'size': size,
        'dataUrl': dataUrl,
        'uploadedAt': uploadedAt,
      };
}

class EmployeeProfileData {
  final String? nationalId;
  final String? phoneNumber;
  final String? birthDate;
  final String? nationalIdExpiryDate;
  final String? sponsorName;
  final String? licenseExpiryDate;
  final String? passportNumber;
  final String? passportExpiryDate;
  final String? nationality;
  final String? absherNumber;
  final String? qualification;
  final String? jobTitle;
  final String? employeeNumber;
  final String? projectName;
  final String? city;
  final String? carPlateNumber;
  final String? carType;
  final String? carModel;
  final String? carYear;
  final String? phoneType;
  final String? phoneSerial;
  final String? businessPhoneNumber;
  final String? simType;
  final EmployeeStoredFile? jobOfferFile;
  final EmployeeStoredFile? promissoryNoteFile;
  final EmployeeStoredFile? carHandoverFile;
  final List<EmployeeStoredFile> otherFiles;

  const EmployeeProfileData({
    this.nationalId,
    this.phoneNumber,
    this.birthDate,
    this.nationalIdExpiryDate,
    this.sponsorName,
    this.licenseExpiryDate,
    this.passportNumber,
    this.passportExpiryDate,
    this.nationality,
    this.absherNumber,
    this.qualification,
    this.jobTitle,
    this.employeeNumber,
    this.projectName,
    this.city,
    this.carPlateNumber,
    this.carType,
    this.carModel,
    this.carYear,
    this.phoneType,
    this.phoneSerial,
    this.businessPhoneNumber,
    this.simType,
    this.jobOfferFile,
    this.promissoryNoteFile,
    this.carHandoverFile,
    this.otherFiles = const [],
  });

  factory EmployeeProfileData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmployeeProfileData();
    EmployeeStoredFile? fileOf(dynamic v) {
      if (v is Map) {
        return EmployeeStoredFile.fromJson(Map<String, dynamic>.from(v));
      }
      return null;
    }

    final others = <EmployeeStoredFile>[];
    final rawOthers = json['otherFiles'];
    if (rawOthers is List) {
      for (final item in rawOthers) {
        if (item is Map) {
          others.add(EmployeeStoredFile.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return EmployeeProfileData(
      nationalId: json['nationalId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      birthDate: json['birthDate'] as String?,
      nationalIdExpiryDate: json['nationalIdExpiryDate'] as String?,
      sponsorName: json['sponsorName'] as String?,
      licenseExpiryDate: json['licenseExpiryDate'] as String?,
      passportNumber: json['passportNumber'] as String?,
      passportExpiryDate: json['passportExpiryDate'] as String?,
      nationality: json['nationality'] as String?,
      absherNumber: json['absherNumber'] as String?,
      qualification: json['qualification'] as String?,
      jobTitle: json['jobTitle'] as String?,
      employeeNumber: json['employeeNumber'] as String?,
      projectName: json['projectName'] as String?,
      city: json['city'] as String?,
      carPlateNumber: json['carPlateNumber'] as String?,
      carType: json['carType'] as String?,
      carModel: json['carModel'] as String?,
      carYear: json['carYear'] as String?,
      phoneType: json['phoneType'] as String?,
      phoneSerial: json['phoneSerial'] as String?,
      businessPhoneNumber: json['businessPhoneNumber'] as String?,
      simType: json['simType'] as String?,
      jobOfferFile: fileOf(json['jobOfferFile']),
      promissoryNoteFile: fileOf(json['promissoryNoteFile']),
      carHandoverFile: fileOf(json['carHandoverFile']),
      otherFiles: others,
    );
  }

  Map<String, dynamic> toJson() => {
        'nationalId': nationalId,
        'phoneNumber': phoneNumber,
        'birthDate': birthDate,
        'nationalIdExpiryDate': nationalIdExpiryDate,
        'sponsorName': sponsorName,
        'licenseExpiryDate': licenseExpiryDate,
        'passportNumber': passportNumber,
        'passportExpiryDate': passportExpiryDate,
        'nationality': nationality,
        'absherNumber': absherNumber,
        'qualification': qualification,
        'projectName': projectName,
        'city': city,
        'carPlateNumber': carPlateNumber,
        'carType': carType,
        'carModel': carModel,
        'carYear': carYear,
        'phoneType': phoneType,
        'phoneSerial': phoneSerial,
        'businessPhoneNumber': businessPhoneNumber,
        'simType': simType,
        'jobOfferFile': jobOfferFile?.toJson(),
        'carHandoverFile': carHandoverFile?.toJson(),
        'otherFiles': otherFiles.map((e) => e.toJson()).toList(),
      };
}

class EmployeeProfileResponse {
  final String userId;
  final String username;
  final String fullName;
  final String role;
  final String? profileImage;
  final EmployeeProfileData profile;

  const EmployeeProfileResponse({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.role,
    this.profileImage,
    required this.profile,
  });

  factory EmployeeProfileResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};

    Map<String, dynamic>? profile;
    final rawProfile = json['profile'];
    if (rawProfile is Map) {
      profile = Map<String, dynamic>.from(rawProfile);
    } else if (rawProfile is String && rawProfile.trim().isNotEmpty) {
      // Defensive: some drivers/stores may double-encode jsonb as a string.
      try {
        final decoded = jsonDecode(rawProfile);
        if (decoded is Map) {
          profile = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        profile = null;
      }
    }

    return EmployeeProfileResponse(
      userId: user['id'] as String? ?? '',
      username: user['username'] as String? ?? '',
      fullName: user['fullName'] as String? ?? '',
      role: user['role'] as String? ?? '',
      profileImage: user['profileImage'] as String?,
      profile: EmployeeProfileData.fromJson(profile),
    );
  }
}
