import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bhandara.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'report_bhandara_dialog.dart';
import 'bhandara_more_menu.dart';

class BhandaraCard extends StatelessWidget {
  final Bhandara bhandara;
  final VoidCallback onTap;

  const BhandaraCard({
    super.key,
    required this.bhandara,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AppStyles.cardDecoration(radius: AppStyles.borderRadiusLg),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: AppStyles.borderRadiusLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardImage(bhandara: bhandara),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                bhandara.bhandaraName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (bhandara.distanceKm != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.saffron.withValues(alpha: 0.15),
                                      AppColors.iconBg,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      size: 14,
                                      color: AppColors.deepSaffron,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${bhandara.distanceKm!.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: AppColors.deepSaffron,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          text: dateFormat.format(bhandara.date),
                        ),
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.person_outline_rounded,
                          text: bhandara.publisherName,
                        ),
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.location_on_rounded,
                          text: bhandara.fullAddress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: BhandaraMoreMenu(
                onReport: () => ReportBhandaraDialog.show(context, bhandara),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final Bhandara bhandara;

  const _CardImage({required this.bhandara});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Stack(
        children: [
          if (bhandara.imageUrl != null)
            Image.network(
              bhandara.imageUrl!,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(height: 170),
            )
          else
            _placeholder(height: 120),
          Positioned(
            left: 12,
            bottom: 12,
            child: AppStyles.liveBadge(),
          ),
        ],
      ),
    );
  }

  Widget _placeholder({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightSaffron, AppColors.iconBg],
        ),
      ),
      child: const Icon(
        Icons.soup_kitchen_rounded,
        size: 52,
        color: AppColors.maroon,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.maroon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
