import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'admin_reports_screen.dart';
import 'profile_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _isAdmin = false;
  bool _checkingAdmin = true;

  @override
  void initState() {
    super.initState();
    _loadAdminStatus();
  }

  Future<void> _loadAdminStatus() async {
    try {
      final isAdmin = await AuthService.instance.isCurrentUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _checkingAdmin = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkingAdmin = false);
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

    await AuthService.instance.signOut();
  }

  void _openAdminReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.instance.displayName ?? 'User';
    final email = AuthService.instance.email ?? '';
    final avatarUrl = AuthService.instance.avatarUrl;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
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
                        radius: 30,
                        backgroundColor: AppColors.iconBg,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 22,
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
                                      fontSize: 18,
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
                            const SizedBox(height: 6),
                            const Text(
                              'Tap to view profile',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openAdminReports,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('View All Reports'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.maroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            const Spacer(),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.iconBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 48,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAdmin
                  ? 'Review user reports from the admin panel above.'
                  : 'Connect with people sharing Bhandara seva.\nComing soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const Spacer(),
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
            if (_checkingAdmin) ...[
              const SizedBox(height: 12),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
