import 'package:flutter/material.dart';

import '../models/bhandara.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ReportBhandaraDialog extends StatefulWidget {
  final Bhandara bhandara;

  const ReportBhandaraDialog({super.key, required this.bhandara});

  static Future<void> show(BuildContext context, Bhandara bhandara) async {
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReportBhandaraDialog(bhandara: bhandara),
    );

    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your report has been submitted. Thank you.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  State<ReportBhandaraDialog> createState() => _ReportBhandaraDialogState();
}

class _ReportBhandaraDialogState extends State<ReportBhandaraDialog> {
  final _reasonController = TextEditingController();
  final _apiService = ApiService();
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isOwnListing {
    final currentUserId = AuthService.instance.currentUser?.id;
    return widget.bhandara.postedBy != null &&
        widget.bhandara.postedBy == currentUserId;
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();

    if (reason.length < 5) {
      setState(() => _error = 'Please enter at least 5 characters');
      return;
    }

    if (_isOwnListing) {
      setState(() => _error = 'You cannot report your own Bhandara');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _apiService.reportBhandara(
        bhandaraId: widget.bhandara.id,
        reason: reason,
      );

      if (!mounted) return;

      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });

      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AlertDialog(
        title: const Text('Report Bhandara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Your report has been submitted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for helping keep the community safe.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: const Text('Report Bhandara'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bhandara.bhandaraName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (_isOwnListing)
              const Text(
                'You cannot report your own listing.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else ...[
              const Text(
                'Tell us why you are reporting this Bhandara:',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 500,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for report...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.templeRed, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        if (!_isOwnListing)
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Report'),
          ),
      ],
    );
  }
}
