import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeaturedServiceCard(
                icon: Icons.add_rounded,
                label: 'Post Bhandara',
                subtitle: 'Share free food seva',
                onTap: onPostFood,
                gradient: const [AppColors.saffron, AppColors.deepSaffron],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeaturedServiceCard(
                icon: Icons.search_rounded,
                label: 'Find Bhandara',
                subtitle: 'Discover Bhandara Events',
                onTap: onFindBhandara,
                gradient: [AppColors.maroon, AppColors.deepMaroon],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CompactServiceCard(
                icon: Icons.calendar_month_rounded,
                label: 'Panchang',
                onTap: onPanchang,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactServiceCard(
                icon: Icons.emoji_events_rounded,
                label: 'Rewards',
                onTap: onRewards,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _FeaturedServiceCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.borderRadiusMd,
        child: Ink(
          height: 118,
          decoration: AppStyles.gradientCard(colors: gradient),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CompactServiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: AppStyles.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppStyles.borderRadiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: AppStyles.cardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.maroon, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
