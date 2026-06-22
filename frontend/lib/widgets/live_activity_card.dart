import 'package:flutter/material.dart';

import '../models/home_activity_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class LiveActivityCard extends StatelessWidget {
  final HomeActivityItem? item;
  final int itemCount;
  final int activeIndex;

  const LiveActivityCard({
    super.key,
    this.item,
    this.itemCount = 0,
    this.activeIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final activity = item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: AppStyles.cardDecoration(radius: AppStyles.borderRadiusLg),
      child: ClipRRect(
        borderRadius: AppStyles.borderRadiusLg,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: activity?.type == HomeActivityType.foodShare
                        ? [AppColors.gold, AppColors.saffron]
                        : [AppColors.saffron, AppColors.maroon],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: activity == null
                        ? _EmptyContent(key: const ValueKey('empty'))
                        : _ActivityContent(
                            key: ValueKey(activity.id),
                            item: activity,
                            itemCount: itemCount,
                            activeIndex: activeIndex,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.iconBg,
          ),
          child: const Icon(Icons.soup_kitchen_rounded, color: AppColors.maroon),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No nearby listings yet',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Check back soon for Bhandaras and shared food near you',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityContent extends StatelessWidget {
  final HomeActivityItem item;
  final int itemCount;
  final int activeIndex;

  const _ActivityContent({
    super.key,
    required this.item,
    required this.itemCount,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.iconBg,
            image: item.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.imageUrl == null
              ? Icon(
                  item.type == HomeActivityType.foodShare
                      ? Icons.restaurant_rounded
                      : Icons.soup_kitchen_rounded,
                  color: item.type == HomeActivityType.foodShare
                      ? AppColors.saffron
                      : AppColors.maroon,
                )
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.publisherName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.saffron.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.typeLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepSaffron,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.distanceKm != null
                    ? '${item.location} • ${item.distanceKm!.toStringAsFixed(1)} km'
                    : item.location,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(text: '${item.actionVerb} '),
                    TextSpan(
                      text: '"${item.title}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.maroon,
                      ),
                    ),
                  ],
                ),
              ),
              if (itemCount > 1) ...[
                const SizedBox(height: 10),
                Row(
                  children: List.generate(itemCount.clamp(0, 6), (index) {
                    final active = index == activeIndex;
                    return Container(
                      width: active ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.maroon
                            : AppColors.maroon.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
