import 'dart:io';

/// Backend API base URL configuration.
///
/// **Physical phone:** set [pcLocalIp] to your computer's Wi-Fi IP.
/// Find it with: `ipconfig` → look for IPv4 under your Wi-Fi adapter.
///
/// **Android emulator:** set [pcLocalIp] to `10.0.2.2`
class ApiConfig {
  /// Your PC's local Wi-Fi IP (phone & PC must be on same Wi-Fi)
  static const String pcLocalIp = '192.168.29.106';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$pcLocalIp:3000';
    }
    return 'http://localhost:3000';
  }

  static String get bhandarasUrl => '$baseUrl/api/bhandaras';
  static String get healthUrl => '$baseUrl/api/health';
  static String get deviceTokensUrl => '$baseUrl/api/device-tokens';
  static String get notificationsUrl => '$baseUrl/api/notifications';
  static String get reportsUrl => '$baseUrl/api/reports';
  static String get adminReportsUrl => '$baseUrl/api/admin/reports';
  static String get adminReportsByUserUrl => '$baseUrl/api/admin/reports/by-user';
  static String adminUserBlockUrl(String userId) => '$baseUrl/api/admin/users/$userId/block';
  static String get myBhandarasUrl => '$baseUrl/api/users/me/bhandaras';
  static String get foodSharesUrl => '$baseUrl/api/food-shares';
  static String foodShareAcceptUrl(String id) => '$baseUrl/api/food-shares/$id/accept';
  static String foodShareUrl(String id) => '$baseUrl/api/food-shares/$id';
  static String foodShareDeleteUrl(String id) => foodShareUrl(id);
}
