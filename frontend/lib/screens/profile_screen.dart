import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/admin_user_reports.dart';
import '../models/bhandara.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'add_bhandara_screen.dart';
import 'bhandara_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  List<Bhandara> _myBhandaras = [];
  List<AdminUserReports> _adminGroups = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _loadingAdmin = false;
  String? _error;
  String? _adminError;
  final Set<String> _expandedUsers = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isAdmin = await AuthService.instance.isCurrentUserAdmin();
      final list = await _apiService.fetchMyBhandaras();

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _myBhandaras = list;
          _isLoading = false;
        });
      }

      if (isAdmin) {
        await _loadAdminReports();
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

  Future<void> _loadAdminReports() async {
    setState(() {
      _loadingAdmin = true;
      _adminError = null;
    });

    try {
      final groups = await _apiService.fetchAdminReportsByUser();
      if (mounted) {
        setState(() {
          _adminGroups = groups;
          _loadingAdmin = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _adminError = error.toString().replaceFirst('Exception: ', '');
          _loadingAdmin = false;
        });
      }
    }
  }

  Future<void> _toggleUserBlock(AdminUserReports group) async {
    final willBlock = !group.isBlocked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(willBlock ? 'Block user?' : 'Unblock user?'),
        content: Text(
          willBlock
              ? '${group.name} will not be able to use the app.'
              : '${group.name} will be able to use the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(willBlock ? 'Block' : 'Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.setUserBlocked(userId: group.userId, blocked: willBlock);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(willBlock ? 'User blocked' : 'User unblocked'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadAdminReports();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.templeRed,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to login with Google again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await AuthService.instance.signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _openBhandara(Bhandara bhandara) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BhandaraDetailScreen(bhandara: bhandara)),
    );
  }

  Future<void> _editBhandara(Bhandara bhandara) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBhandaraScreen(existingBhandara: bhandara),
      ),
    );

    if (updated == true) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.displayName ?? 'User';
    final email = AuthService.instance.email ?? '';
    final avatarUrl = AuthService.instance.avatarUrl;
    final dateFormat = DateFormat('dd MMM yyyy');
    final reportDateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProfile();
        },
        color: AppColors.maroon,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.iconBg,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.maroon,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            if (_isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.maroon.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: AppColors.maroon,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined, color: AppColors.maroon, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Reports by User (${_adminGroups.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingAdmin)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.maroon)),
                )
              else if (_adminError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text(_adminError!, style: const TextStyle(color: AppColors.templeRed)),
                      TextButton(onPressed: _loadAdminReports, child: const Text('Retry')),
                    ],
                  ),
                )
              else if (_adminGroups.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'No reports submitted yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ..._adminGroups.map((group) => _AdminUserCard(
                      group: group,
                      isExpanded: _expandedUsers.contains(group.userId),
                      reportDateFormat: reportDateFormat,
                      onExpandToggle: () {
                        setState(() {
                          if (_expandedUsers.contains(group.userId)) {
                            _expandedUsers.remove(group.userId);
                          } else {
                            _expandedUsers.add(group.userId);
                          }
                        });
                      },
                      onToggleBlock: group.canBlock ? () => _toggleUserBlock(group) : null,
                    )),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.restaurant_menu_rounded, color: AppColors.maroon, size: 22),
                const SizedBox(width: 8),
                Text(
                  'My Bhandaras (${_myBhandaras.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: AppColors.maroon)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.templeRed),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_myBhandaras.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No Bhandaras added yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Post a Bhandara from the home screen to see it here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                ),
              )
            else
              ..._myBhandaras.map(
                (bhandara) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => _openBhandara(bhandara),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.iconBg,
                                borderRadius: BorderRadius.circular(10),
                                image: bhandara.imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(bhandara.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: bhandara.imageUrl == null
                                  ? const Icon(
                                      Icons.restaurant_rounded,
                                      color: AppColors.primaryOrange,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bhandara.bhandaraName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${bhandara.village} • ${dateFormat.format(bhandara.date)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _editBhandara(bhandara),
                              icon: const Icon(Icons.edit_outlined, color: AppColors.maroon),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.maroon,
                  side: const BorderSide(color: AppColors.maroon),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final AdminUserReports group;
  final bool isExpanded;
  final DateFormat reportDateFormat;
  final VoidCallback onExpandToggle;
  final VoidCallback? onToggleBlock;

  const _AdminUserCard({
    required this.group,
    required this.isExpanded,
    required this.reportDateFormat,
    required this.onExpandToggle,
    this.onToggleBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onExpandToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.iconBg,
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.maroon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (group.email.isNotEmpty)
                          Text(
                            group.email,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${group.reports.length} report(s) • Total count: ${group.reportCount}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (group.isBlocked)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
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
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...group.reports.map(
              (report) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.bhandaraName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reporter: ${report.reporterName.isNotEmpty ? report.reporterName : report.reporterEmail}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.reason,
                      style: const TextStyle(color: AppColors.textDark, height: 1.35),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reportDateFormat.format(report.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                  ],
                ),
              ),
            ),
            if (onToggleBlock != null)
              Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onToggleBlock,
                    icon: Icon(group.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded),
                    label: Text(group.isBlocked ? 'Unblock User' : 'Block User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: group.isBlocked ? Colors.green.shade700 : AppColors.templeRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  'Unlinked listing — block unavailable until poster logs in.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
