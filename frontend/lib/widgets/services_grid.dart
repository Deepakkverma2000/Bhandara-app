import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ServicesGrid extends StatelessWidget {
  final VoidCallback onFindBhandara;
  final VoidCallback onPostFood;
  final VoidCallback onPanchang;
  final VoidCallback onRewards;

  const ServicesGrid({
    super.key,
    required this.onFindBhandara,
    required this.onPostFood,
    required this.onPanchang,
    required this.onRewards,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        icon: Icons.search_rounded,
        label: 'Find\nBhandara',
        onTap: onFindBhandara,
      ),
      _ServiceItem(
        icon: Icons.add_rounded,
        label: 'Post Free\nFood',
        onTap: onPostFood,
        isLargeIcon: true,
      ),
      _ServiceItem(
        icon: Icons.calendar_month_rounded,
        label: 'Panchang',
        onTap: onPanchang,
      ),
      _ServiceItem(
        icon: Icons.emoji_events_rounded,
        label: 'Rewards',
        onTap: onRewards,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) => services[index],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLargeIcon;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLargeIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.maroon,
              size: isLargeIcon ? 32 : 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.2,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
