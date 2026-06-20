import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/app_notification.dart';
import '../models/bhandara.dart';
import 'device_id_service.dart';

class ApiService {
  Future<List<Bhandara>> fetchBhandaras({
    double? latitude,
    double? longitude,
  }) async {
    var url = ApiConfig.bhandarasUrl;
    if (latitude != null && longitude != null) {
      url += '?lat=$latitude&lng=$longitude';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data.map((e) => Bhandara.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load Bhandaras (${response.statusCode})');
  }

  Future<Bhandara> createBhandara({
    required String bhandaraName,
    required String publisherName,
    required String street,
    required String village,
    required String pinCode,
    required DateTime date,
    required double latitude,
    required double longitude,
    File? image,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.bhandarasUrl));

    request.fields['bhandaraName'] = bhandaraName;
    request.fields['publisherName'] = publisherName;
    request.fields['street'] = street;
    request.fields['village'] = village;
    request.fields['pinCode'] = pinCode;
    request.fields['date'] = date.toIso8601String();
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

    final deviceId = await DeviceIdService.getDeviceId();
    request.fields['deviceId'] = deviceId;

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(_imageContentType(image.path)),
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return Bhandara.fromJson(body['data'] as Map<String, dynamic>);
    }

    String message = 'Failed to create Bhandara (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = '$message: ${response.body}';
      }
    }
    throw Exception(message);
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.healthUrl));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> registerDeviceToken({
    required String deviceId,
    String? fcmToken,
    required String platform,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.deviceTokensUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'platform': platform,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register device (${response.statusCode})');
    }
  }

  Future<List<AppNotification>> fetchNotifications(
    String deviceId, {
    bool unreadOnly = true,
  }) async {
    final unreadParam = unreadOnly ? '&unreadOnly=true' : '';
    final url = '${ApiConfig.notificationsUrl}?deviceId=$deviceId$unreadParam';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load notifications (${response.statusCode})');
  }

  Future<int> fetchUnreadCount(String deviceId) async {
    final url = '${ApiConfig.notificationsUrl}/unread-count?deviceId=$deviceId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['count'] as int? ?? 0;
    }

    return 0;
  }

  Future<void> markNotificationRead(String notificationId, String deviceId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.notificationsUrl}/$notificationId/read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification read');
    }
  }

  Future<void> markAllNotificationsRead(String deviceId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.notificationsUrl}/read-all'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications read');
    }
  }

  String _imageContentType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
