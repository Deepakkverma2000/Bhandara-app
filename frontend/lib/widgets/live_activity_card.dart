import 'package:flutter/material.dart';

import '../models/bhandara.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class LiveActivityCard extends StatelessWidget {
  final Bhandara? bhandara;

  const LiveActivityCard({super.key, this.bhandara});

  @override
  Widget build(BuildContext context) {
    final publisherName = bhandara?.publisherName ?? 'Community Member';
    final bhandaraName = bhandara?.bhandaraName ?? 'Free Food Listing';
    final location = bhandara != null
        ? '${bhandara!.village}, ${bhandara!.pinCode}'
        : 'Delhi NCR';

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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.saffron, AppColors.maroon],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.iconBg,
                          image: bhandara?.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(bhandara!.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: bhandara?.imageUrl == null
                            ? const Icon(
                                Icons.soup_kitchen_rounded,
                                color: AppColors.maroon,
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
                                    publisherName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                AppStyles.liveBadge(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
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
                                  const TextSpan(text: 'Added '),
                                  TextSpan(
                                    text: '"$bhandaraName"',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.maroon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
