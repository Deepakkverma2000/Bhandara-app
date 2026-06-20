import 'package:flutter/material.dart';

import '../models/bhandara.dart';
import '../theme/app_colors.dart';

class LiveActivityCard extends StatelessWidget {
  final Bhandara? bhandara;

  const LiveActivityCard({super.key, this.bhandara});

  @override
  Widget build(BuildContext context) {
    final publisherName = bhandara?.publisherName ?? 'Priya Verma';
    final bhandaraName = bhandara?.bhandaraName ?? 'Free Food Listing';
    final location = bhandara != null
        ? '${bhandara!.village}, ${bhandara!.pinCode}'
        : 'Lucknow, Uttar Pradesh';
    final action = bhandara != null
        ? 'Added "$bhandaraName"'
        : 'Added One Free Food Listing';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.iconBg,
            backgroundImage: bhandara?.imageUrl != null
                ? NetworkImage(bhandara!.imageUrl!)
                : const NetworkImage('https://i.pravatar.cc/150?img=32'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        publisherName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.liveRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Live',
                          style: TextStyle(
                            color: AppColors.liveRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
