import 'dart:io';

/// Copy to `api_config.dart` and set [pcLocalIp] to your computer's Wi-Fi IP.
/// Find it with: `ipconfig` → IPv4 under your Wi-Fi adapter.
class ApiConfig {
  static const String pcLocalIp = 'YOUR_PC_WIFI_IP';

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
}
