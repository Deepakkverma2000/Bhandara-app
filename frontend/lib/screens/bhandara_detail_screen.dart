import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bhandara.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/map_utils.dart';
import '../widgets/map_widget.dart';
import '../widgets/report_bhandara_dialog.dart';

class BhandaraDetailScreen extends StatelessWidget {
  final Bhandara bhandara;

  const BhandaraDetailScreen({super.key, required this.bhandara});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: bhandara.imageUrl != null ? 260 : 160,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.maroon,
            foregroundColor: AppColors.lightGold,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) async {
                  if (value == 'report') {
                    await ReportBhandaraDialog.show(context, bhandara);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: AppColors.templeRed),
                        SizedBox(width: 10),
                        Text('Report'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bhandara.imageUrl != null)
                    Image.network(
                      bhandara.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _heroFallback(),
                    )
                  else
                    _heroFallback(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppStyles.liveBadge(scale: 1.1),
                        const SizedBox(height: 8),
                        Text(
                          bhandara.bhandaraName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Published by ${bhandara.publisherName}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (bhandara.distanceKm != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.iconBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 16, color: AppColors.deepSaffron),
                          const SizedBox(width: 6),
                          Text(
                            '${bhandara.distanceKm!.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              color: AppColors.deepSaffron,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _DetailCard(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date & Time',
                        value: dateFormat.format(bhandara.date),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.signpost_rounded,
                        label: 'Street',
                        value: bhandara.street,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.location_city_rounded,
                        label: 'Village / City',
                        value: bhandara.village,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.pin_rounded,
                        label: 'Pin Code',
                        value: bhandara.pinCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppStyles.sectionHeader('Location', icon: Icons.map_rounded),
                  ClipRRect(
                    borderRadius: AppStyles.borderRadiusMd,
                    child: BhandaraMapView(
                      latitude: bhandara.latitude,
                      longitude: bhandara.longitude,
                      onTap: () => openInGoogleMaps(
                        bhandara.latitude,
                        bhandara.longitude,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => openInGoogleMaps(
                            bhandara.latitude,
                            bhandara.longitude,
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Google Maps'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => openWhatsAppWithLocation(
                            bhandara.latitude,
                            bhandara.longitude,
                            bhandara.bhandaraName,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.heroGradient,
        ),
      ),
      child: const Center(
        child: Icon(Icons.soup_kitchen_rounded, size: 72, color: Colors.white70),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppStyles.cardDecoration(),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.maroon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
