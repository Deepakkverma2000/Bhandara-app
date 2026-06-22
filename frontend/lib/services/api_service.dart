import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/admin_user_reports.dart';
import '../models/app_notification.dart';
import '../models/bhandara.dart';
import '../models/bhandara_report.dart';
import '../models/food_share_post.dart';
import '../services/auth_service.dart';
import '../services/device_id_service.dart';

class ApiService {
  Map<String, String> _authHeaders() {
    final token = AuthService.instance.session?.accessToken;
    if (token == null) {
      throw Exception('Login required');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
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
    final token = AuthService.instance.session?.accessToken;
    if (token == null) {
      throw Exception('Login required to post a Bhandara');
    }

    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.bhandarasUrl));
    request.headers['Authorization'] = 'Bearer $token';

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

  Future<Bhandara> updateBhandara({
    required String id,
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
    final token = AuthService.instance.session?.accessToken;
    if (token == null) {
      throw Exception('Login required to edit a Bhandara');
    }

    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.bhandarasUrl}/$id'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['bhandaraName'] = bhandaraName;
    request.fields['publisherName'] = publisherName;
    request.fields['street'] = street;
    request.fields['village'] = village;
    request.fields['pinCode'] = pinCode;
    request.fields['date'] = date.toIso8601String();
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();

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

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return Bhandara.fromJson(body['data'] as Map<String, dynamic>);
    }

    String message = 'Failed to update Bhandara (${response.statusCode})';
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
    String? userId,
    bool unreadOnly = true,
  }) async {
    final unreadParam = unreadOnly ? '&unreadOnly=true' : '';
    final userParam = userId != null ? '&userId=$userId' : '';
    final url = '${ApiConfig.notificationsUrl}?deviceId=$deviceId$userParam$unreadParam';
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

  Future<int> fetchUnreadCount(String deviceId, {String? userId}) async {
    final userParam = userId != null ? '&userId=$userId' : '';
    final url = '${ApiConfig.notificationsUrl}/unread-count?deviceId=$deviceId$userParam';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['count'] as int? ?? 0;
    }

    return 0;
  }

  Future<void> markNotificationRead(
    String notificationId,
    String deviceId, {
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.notificationsUrl}/$notificationId/read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        if (userId != null) 'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification read');
    }
  }

  Future<void> markAllNotificationsRead(
    String deviceId, {
    String? userId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.notificationsUrl}/read-all'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'deviceId': deviceId,
        if (userId != null) 'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications read');
    }
  }

  Future<void> reportBhandara({
    required String bhandaraId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.reportsUrl),
      headers: _authHeaders(),
      body: jsonEncode({
        'bhandaraId': bhandaraId,
        'reason': reason,
      }),
    );

    if (response.statusCode == 201) {
      return;
    }

    String message = 'Failed to submit report (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {
      if (response.body.isNotEmpty && !response.body.startsWith('<')) {
        message = response.body;
      }
    }
    throw Exception(message);
  }

  Future<List<Bhandara>> fetchMyBhandaras() async {
    final response = await http.get(
      Uri.parse(ApiConfig.myBhandarasUrl),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data.map((e) => Bhandara.fromJson(e as Map<String, dynamic>)).toList();
    }

    String message = 'Failed to load your Bhandaras (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<List<AdminUserReports>> fetchAdminReportsByUser() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminReportsByUserUrl),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => AdminUserReports.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String message = 'Failed to load user reports (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<void> setUserBlocked({
    required String userId,
    required bool blocked,
  }) async {
    final response = await http.patch(
      Uri.parse(ApiConfig.adminUserBlockUrl(userId)),
      headers: _authHeaders(),
      body: jsonEncode({'blocked': blocked}),
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Failed to update user (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<List<BhandaraReport>> fetchAdminReports() async {
    final response = await http.get(
      Uri.parse(ApiConfig.adminReportsUrl),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => BhandaraReport.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    String message = 'Failed to load reports (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<List<FoodSharePost>> fetchFoodSharePosts({
    double? latitude,
    double? longitude,
  }) async {
    var url = ApiConfig.foodSharesUrl;
    if (latitude != null && longitude != null) {
      url += '?lat=$latitude&lng=$longitude';
    }

    final token = AuthService.instance.session?.accessToken;
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => FoodSharePost.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load food posts (${response.statusCode})');
  }

  Future<FoodSharePost> createFoodSharePost({
    required String contactName,
    required String phoneNumber,
    required String eventName,
    required String foodDescription,
    required String quantity,
    required String street,
    required String village,
    required String pinCode,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.foodSharesUrl),
      headers: _authHeaders(),
      body: jsonEncode({
        'contactName': contactName,
        'phoneNumber': phoneNumber,
        'eventName': eventName.isEmpty ? null : eventName,
        'foodDescription': foodDescription,
        'quantity': quantity.isEmpty ? null : quantity,
        'street': street,
        'village': village,
        'pinCode': pinCode,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return FoodSharePost.fromJson(body['data'] as Map<String, dynamic>);
    }

    String message = 'Failed to create food post (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<FoodSharePost> updateFoodSharePost({
    required String id,
    required String contactName,
    required String phoneNumber,
    required String eventName,
    required String foodDescription,
    required String quantity,
    required String street,
    required String village,
    required String pinCode,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConfig.foodShareUrl(id)),
      headers: _authHeaders(),
      body: jsonEncode({
        'contactName': contactName,
        'phoneNumber': phoneNumber,
        'eventName': eventName.isEmpty ? null : eventName,
        'foodDescription': foodDescription,
        'quantity': quantity.isEmpty ? null : quantity,
        'street': street,
        'village': village,
        'pinCode': pinCode,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return FoodSharePost.fromJson(body['data'] as Map<String, dynamic>);
    }

    String message = 'Failed to update food post (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<FoodSharePost> acceptFoodSharePost({
    required String id,
    required String contactName,
    required String phoneNumber,
    required DateTime pickupTime,
    required int platesRequired,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.foodShareAcceptUrl(id)),
      headers: _authHeaders(),
      body: jsonEncode({
        'contactName': contactName,
        'phoneNumber': phoneNumber,
        'pickupTime': pickupTime.toIso8601String(),
        'platesRequired': platesRequired,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return FoodSharePost.fromJson(body['data'] as Map<String, dynamic>);
    }

    String message = 'Failed to accept food post (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }

  Future<void> deleteFoodSharePost(String id) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.foodShareDeleteUrl(id)),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      return;
    }

    String message = 'Failed to remove post (${response.statusCode})';
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      message = error['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
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
