import 'bhandara_report.dart';

class AdminUserReports {
  final String userId;
  final String name;
  final String email;
  final int reportCount;
  final bool isBlocked;
  final bool canBlock;
  final List<BhandaraReport> reports;

  AdminUserReports({
    required this.userId,
    required this.name,
    required this.email,
    required this.reportCount,
    required this.isBlocked,
    required this.canBlock,
    required this.reports,
  });

  factory AdminUserReports.fromJson(Map<String, dynamic> json) {
    final reportsJson = json['reports'] as List<dynamic>? ?? [];
    return AdminUserReports(
      userId: json['userId'] as String,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      reportCount: json['reportCount'] as int? ?? 0,
      isBlocked: json['isBlocked'] as bool? ?? false,
      canBlock: json['canBlock'] as bool? ?? true,
      reports: reportsJson
          .map((e) => BhandaraReport.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
