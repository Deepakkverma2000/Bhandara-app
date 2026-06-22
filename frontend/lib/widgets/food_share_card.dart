import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/food_share_post.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class FoodShareCard extends StatelessWidget {
  final FoodSharePost post;
  final bool isOwner;
  final VoidCallback? onAccept;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isProcessing;

  const FoodShareCard({
    super.key,
    required this.post,
    this.isOwner = false,
    this.onAccept,
    this.onEdit,
    this.onDelete,
    this.isProcessing = false,
  });

  bool get _isOwner =>
      isOwner ||
      (post.postedBy != null &&
          post.postedBy == AuthService.instance.currentUser?.id);

  Future<void> _callPhone(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call $phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('dd MMM, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.saffron.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.saffron,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.foodDescription,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (post.eventName != null && post.eventName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Event: ${post.eventName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (post.quantity != null && post.quantity!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Quantity: ${post.quantity}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusChip(status: post.status),
            ],
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.person_outline,
            label: 'Contact',
            value: post.contactName,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: post.phoneNumber,
            onTap: () => _callPhone(context, post.phoneNumber),
            valueColor: AppColors.maroon,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: post.fullAddress,
          ),
          if (post.distanceKm != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.near_me_outlined,
              label: 'Distance',
              value: '${post.distanceKm!.toStringAsFixed(1)} km away',
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Posted ${timeFormat.format(post.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          if (post.isAccepted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accepted for pickup',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.maroon,
                      fontSize: 13,
                    ),
                  ),
                  if (post.acceptedByName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'By: ${post.acceptedByName}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (post.acceptedByPhone != null) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _callPhone(context, post.acceptedByPhone!),
                      child: Text(
                        'Phone: ${post.acceptedByPhone}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.maroon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (post.acceptedPickupTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pickup time: ${timeFormat.format(post.acceptedPickupTime!)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (post.acceptedPlatesRequired != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Plates required: ${post.acceptedPlatesRequired}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (post.isOpen && !_isOwner && onAccept != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isProcessing ? null : onAccept,
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(isProcessing ? 'Accepting...' : 'Accept & Pickup'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_isOwner && (onEdit != null || onDelete != null))
            Row(
              children: [
                if (onEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.saffron,
                        side: const BorderSide(color: AppColors.saffron),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (onEdit != null && onDelete != null) const SizedBox(width: 10),
                if (onDelete != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(post.isAccepted ? 'Delete Post' : 'Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.maroon,
                        side: const BorderSide(color: AppColors.maroon),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withValues(alpha: 0.12)
            : AppColors.saffron.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Available' : 'Accepted',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isOpen ? Colors.green.shade700 : AppColors.deepSaffron,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: 13,
        color: valueColor ?? AppColors.textDark,
        fontWeight: onTap != null ? FontWeight.w600 : FontWeight.normal,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              onTap != null
                  ? InkWell(onTap: onTap, child: valueWidget)
                  : valueWidget,
            ],
          ),
        ),
      ],
    );
  }
}
