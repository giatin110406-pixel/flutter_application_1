import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../features/drawer_menu/menu_nav_item.dart';

class StudentApi {
  StudentApi({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const baseUrl = 'https://api.ngoisaoviet.info';
  static const _tokenKey = 'ueh_student_tokens';

  final http.Client _client;
  final FlutterSecureStorage _storage;
  Future<bool>? _refreshInProgress;

  Future<bool> hasSession() async => await _readTokens() != null;

  Future<void> login({required String mssv, required String password}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'mssv': mssv.trim(), 'mat_khau': password}),
    );

    if (response.statusCode != 200) {
      throw ApiException(_messageFrom(response));
    }

    await _saveTokenResponse(_decodeObject(response));
  }

  Future<StudentProfile> getStudentInfo() async {
    final response = await _authorizedRequest(
      (token) => _client.get(
        Uri.parse('$baseUrl/api/student-info'),
        headers: _authorizedHeaders(token),
      ),
    );
    return StudentProfile.fromJson(_decodeObject(response));
  }

  Future<AttendanceReceipt> submitAttendance(
    String code, {
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, Object?>{'code': code.trim().toUpperCase()};
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }

    final response = await _authorizedRequest(
      (token) => _client.post(
        Uri.parse('$baseUrl/api/attendance'),
        headers: _authorizedHeaders(token),
        body: jsonEncode(body),
      ),
    );
    return AttendanceReceipt.fromJson(_decodeObject(response));
  }

  /// Menu drawer từ `/api/menu`, đã sắp theo `ordering`. Cần đăng nhập.
  Future<List<MenuNavItem>> getMenu() async {
    final response = await _authorizedRequest(
      (token) => _client.get(
        Uri.parse('$baseUrl/api/menu'),
        headers: _authorizedHeaders(token),
      ),
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List<dynamic>) {
      throw const ApiException('Phản hồi menu không hợp lệ.');
    }
    final items = decoded
        .map((e) => MenuNavItem.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.ordering.compareTo(b.ordering));
    return items;
  }

  Future<void> logout() => _storage.delete(key: _tokenKey);

  Map<String, String> _authorizedHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    var tokens = await _readTokens();
    if (tokens == null) {
      throw const ApiException('Vui lòng đăng nhập để tiếp tục.');
    }

    var response = await request(tokens.accessToken);
    if (response.statusCode == 401) {
      if (!await _refreshTokens()) {
        throw const ApiException(
          'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      tokens = await _readTokens();
      if (tokens == null) {
        throw const ApiException(
          'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
        );
      }
      response = await request(tokens.accessToken);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFrom(response),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  Future<bool> _refreshTokens() {
    return _refreshInProgress ??= _performRefresh().whenComplete(() {
      _refreshInProgress = null;
    });
  }

  Future<bool> _performRefresh() async {
    final tokens = await _readTokens();
    if (tokens == null) return false;

    final response = await _client.post(
      Uri.parse('$baseUrl/api/refresh-token'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': tokens.refreshToken}),
    );

    if (response.statusCode == 400 || response.statusCode == 401) {
      await logout();
      return false;
    }
    if (response.statusCode != 200) {
      throw ApiException(_messageFrom(response));
    }

    await _saveTokenResponse(_decodeObject(response));
    return true;
  }

  Future<_StoredTokens?> _readTokens() async {
    final value = await _storage.read(key: _tokenKey);
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final accessToken = json['token'] as String?;
      final refreshToken = json['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) return null;
      return _StoredTokens(accessToken, refreshToken);
    } on FormatException {
      await logout();
      return null;
    }
  }

  Future<void> _saveTokenResponse(Map<String, dynamic> json) async {
    final accessToken = json['token'];
    final refreshToken = json['refresh_token'];
    if (accessToken is! String || refreshToken is! String) {
      throw const ApiException('Phản hồi đăng nhập không hợp lệ.');
    }
    await _storage.write(
      key: _tokenKey,
      value: jsonEncode({'token': accessToken, 'refresh_token': refreshToken}),
    );
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException('Phản hồi từ máy chủ không hợp lệ.');
  }

  String _messageFrom(http.Response response) {
    try {
      final json = _decodeObject(response);
      final message = json['message'] ?? json['title'];
      if (message is String && message.isNotEmpty) return message;
      final errors = json['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
        }
      }
    } on FormatException {
      return 'Không thể đọc phản hồi từ máy chủ.';
    } on ApiException {
      return 'Không thể đọc phản hồi từ máy chủ.';
    }
    return 'Yêu cầu thất bại (${response.statusCode}).';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.fullName,
    required this.birthDate,
    required this.isMale,
    required this.cohort,
    required this.birthPlace,
    required this.program,
    required this.academicYears,
    required this.avatarUrl,
  });

  final String studentId;
  final String fullName;
  final String birthDate;
  final bool isMale;
  final String cohort;
  final String birthPlace;
  final String program;
  final String academicYears;
  final String avatarUrl;

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['mssv']?.toString() ?? '',
      fullName: json['hoVaTen']?.toString() ?? '',
      birthDate: json['ngaySinh']?.toString() ?? '',
      isMale: json['gioiTinh'] == true,
      cohort: json['nienKhoa']?.toString() ?? '',
      birthPlace: json['noiSinh']?.toString() ?? '',
      program: json['heDaoTao']?.toString() ?? '',
      academicYears: json['nienHoc']?.toString() ?? '',
      avatarUrl: json['hinhDaiDien']?.toString() ?? '',
    );
  }

  String get formattedBirthDate {
    final date = DateTime.tryParse(birthDate);
    if (date == null) return birthDate;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class AttendanceReceipt {
  const AttendanceReceipt({
    required this.message,
    required this.sessionName,
    required this.studentId,
    required this.fullName,
    required this.checkedInAt,
    required this.distanceMeters,
    required this.checkInNumber,
  });

  final String message;
  final String sessionName;
  final String studentId;
  final String fullName;
  final String checkedInAt;
  final num? distanceMeters;

  /// Lần điểm danh thứ mấy trong buổi. Buổi chỉ cho 1 lần thì luôn là 1.
  final int checkInNumber;

  factory AttendanceReceipt.fromJson(Map<String, dynamic> json) {
    return AttendanceReceipt(
      message: json['message']?.toString() ?? 'Điểm danh thành công.',
      sessionName: json['sessionName']?.toString() ?? '',
      studentId: json['mssv']?.toString() ?? '',
      fullName: json['hoVaTen']?.toString() ?? '',
      checkedInAt: json['checkedInAt']?.toString() ?? '',
      distanceMeters: json['distanceMeters'] as num?,
      checkInNumber: (json['checkInNumber'] as num?)?.toInt() ?? 1,
    );
  }
}

class _StoredTokens {
  const _StoredTokens(this.accessToken, this.refreshToken);

  final String accessToken;
  final String refreshToken;
}
