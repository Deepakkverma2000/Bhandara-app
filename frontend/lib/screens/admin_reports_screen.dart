import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bhandara_report.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _apiService = ApiService();
  List<BhandaraReport> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await _apiService.fetchAdminReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Reports'),
        actions: [
          IconButton(
            onPressed: _loadReports,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.maroon),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppColors.templeRed),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReports,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Text(
          'No reports yet',
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return RefreshIndicator(
      onRefresh: _loadReports,
      color: AppColors.maroon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.bhandaraName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (report.reportedUserBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.templeRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Blocked',
                          style: TextStyle(
                            color: AppColors.templeRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${report.bhandaraVillage}${report.bhandaraPinCode.isNotEmpty ? ' • ${report.bhandaraPinCode}' : ''}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: 'Reported user',
                  value: report.reportedUserName.isNotEmpty
                      ? '${report.reportedUserName} (${report.reportedUserEmail})'
                      : report.reportedUserEmail,
                ),
                _InfoLine(
                  label: 'Total reports',
                  value: '${report.reportedUserReportCount}',
                ),
                _InfoLine(
                  label: 'Reporter',
                  value: report.reporterName.isNotEmpty
                      ? '${report.reporterName} (${report.reporterEmail})'
                      : report.reporterEmail,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.reason,
                  style: const TextStyle(color: AppColors.textDark, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  dateFormat.format(report.createdAt),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
