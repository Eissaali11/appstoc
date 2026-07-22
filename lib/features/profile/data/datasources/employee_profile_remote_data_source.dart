import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/employee_profile_model.dart';

class EmployeeProfileRemoteDataSource {
  final ApiClient apiClient;

  EmployeeProfileRemoteDataSource(this.apiClient);

  Map<String, dynamic> _asJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.startsWith('<') || trimmed.startsWith('<!')) {
        throw Exception(
          'خادم الملف الشخصي غير متاح حالياً (استجابة HTML بدل JSON)',
        );
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw Exception('استجابة غير متوقعة من الخادم');
    }
    throw Exception('استجابة غير متوقعة من الخادم');
  }

  Future<EmployeeProfileResponse> getProfile(String userId) async {
    final response = await apiClient.get(ApiEndpoints.employeeProfile(userId));
    return EmployeeProfileResponse.fromJson(_asJsonMap(response.data));
  }

  Future<EmployeeProfileResponse> saveProfile({
    required String userId,
    required EmployeeProfileData profile,
    String? profileImage,
  }) async {
    final payload = <String, dynamic>{
      ...profile.toJson(),
      if (profileImage != null) 'profileImage': profileImage,
    };
    // Never send promissory from mobile — field is hidden for technicians
    payload.remove('promissoryNoteFile');

    final response = await apiClient.put(
      ApiEndpoints.employeeProfile(userId),
      data: payload,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    return EmployeeProfileResponse.fromJson(_asJsonMap(response.data));
  }

  Future<String?> pickProfileImageDataUrl({
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await pickImageAsStoredFile(source: source);
    return file?.dataUrl;
  }

  Future<EmployeeStoredFile?> pickImageAsStoredFile({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1280,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      if (bytes.length > 1.5 * 1024 * 1024) {
        throw Exception('حجم الملف كبير جداً (الحد الأقصى 1.5 ميجابايت)');
      }

      return _bytesToStoredFile(
        bytes: bytes,
        name: picked.name,
        mime: picked.mimeType ?? 'image/jpeg',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('pickImageAsStoredFile: $e');
      rethrow;
    }
  }

  EmployeeStoredFile _bytesToStoredFile({
    required Uint8List bytes,
    required String name,
    required String mime,
  }) {
    final b64 = base64Encode(bytes);
    return EmployeeStoredFile(
      name: name,
      type: mime,
      size: bytes.length,
      dataUrl: 'data:$mime;base64,$b64',
      uploadedAt: DateTime.now().toIso8601String(),
    );
  }
}
