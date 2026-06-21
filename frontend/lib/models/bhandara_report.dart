class BhandaraReport {
  final String id;
  final String reason;
  final DateTime createdAt;
  final String bhandaraId;
  final String bhandaraName;
  final String bhandaraVillage;
  final String bhandaraPinCode;
  final String reporterEmail;
  final String reporterName;
  final String reportedUserEmail;
  final String reportedUserName;
  final String? reportedUserId;
  final int reportedUserReportCount;
  final bool reportedUserBlocked;

  BhandaraReport({
    required this.id,
    required this.reason,
    required this.createdAt,
    required this.bhandaraId,
    required this.bhandaraName,
    required this.bhandaraVillage,
    required this.bhandaraPinCode,
    required this.reporterEmail,
    required this.reporterName,
    required this.reportedUserEmail,
    required this.reportedUserName,
    this.reportedUserId,
    required this.reportedUserReportCount,
    required this.reportedUserBlocked,
  });

  factory BhandaraReport.fromJson(Map<String, dynamic> json) {
    return BhandaraReport(
      id: json['id'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      bhandaraId: json['bhandaraId'] as String,
      bhandaraName: json['bhandaraName'] as String? ?? 'Unknown',
      bhandaraVillage: json['bhandaraVillage'] as String? ?? '',
      bhandaraPinCode: json['bhandaraPinCode'] as String? ?? '',
      reporterEmail: json['reporterEmail'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? '',
      reportedUserEmail: json['reportedUserEmail'] as String? ?? '',
      reportedUserName: json['reportedUserName'] as String? ?? '',
      reportedUserId: json['reportedUserId'] as String?,
      reportedUserReportCount: json['reportedUserReportCount'] as int? ?? 0,
      reportedUserBlocked: json['reportedUserBlocked'] as bool? ?? false,
    );
  }
}
