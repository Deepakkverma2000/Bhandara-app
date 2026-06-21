import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/bhandara.dart';
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
      appBar: AppBar(
        title: const Text('Bhandara Details'),
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
                    Icon(Icons.flag_outlined, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Report'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          if (bhandara.imageUrl != null)
            Image.network(
              bhandara.imageUrl!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 220,
                color: Colors.orange.shade100,
                child: const Icon(Icons.image_not_supported, size: 64),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bhandara.bhandaraName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Published by ${bhandara.publisherName}',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (bhandara.distanceKm != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(Icons.near_me, size: 18, color: Colors.orange.shade900),
                    label: Text(
                      '${bhandara.distanceKm!.toStringAsFixed(1)} km away',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ],
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date & Time',
                  value: dateFormat.format(bhandara.date),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.signpost,
                  label: 'Street',
                  value: bhandara.street,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.location_city,
                  label: 'Village / City',
                  value: bhandara.village,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.pin,
                  label: 'Pin Code',
                  value: bhandara.pinCode,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Location on Map',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                BhandaraMapView(
                  latitude: bhandara.latitude,
                  longitude: bhandara.longitude,
                  onTap: () => openInGoogleMaps(
                    bhandara.latitude,
                    bhandara.longitude,
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
                        icon: const Icon(Icons.map),
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
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
        Icon(icon, size: 20, color: Colors.orange.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
