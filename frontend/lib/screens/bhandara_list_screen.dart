import 'package:flutter/material.dart';

import '../models/bhandara.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bhandara_card.dart';
import 'bhandara_detail_screen.dart';

class BhandaraListScreen extends StatefulWidget {
  const BhandaraListScreen({super.key});

  @override
  State<BhandaraListScreen> createState() => BhandaraListScreenState();
}

class BhandaraListScreenState extends State<BhandaraListScreen> {
  final _apiService = ApiService();
  final _locationService = LocationService();

  List<Bhandara> _bhandaras = [];
  bool _isLoading = true;
  String? _error;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    loadBhandaras();
  }

  Future<void> loadBhandaras() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final granted = await _locationService.requestPermission();
      double? lat;
      double? lng;

      if (granted) {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      }

      final list = await _apiService.fetchBhandaras(
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        setState(() {
          _bhandaras = list;
          _locationEnabled = lat != null && lng != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Find Bhandara',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: loadBhandaras,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.primaryOrange,
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Could not connect to server.\nMake sure backend is running.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loadBhandaras,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bhandaras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.soup_kitchen_rounded, size: 72, color: Colors.orange.shade200),
            const SizedBox(height: 16),
            Text(
              'No Bhandara found yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_locationEnabled)
          _LocationBanner(
            icon: Icons.near_me_rounded,
            text: 'Showing nearest Bhandara first',
            color: Colors.green.shade50,
            textColor: Colors.green.shade800,
          )
        else
          _LocationBanner(
            icon: Icons.location_off_rounded,
            text: 'Enable location to see nearest Bhandara first',
            color: Colors.amber.shade50,
            textColor: Colors.amber.shade900,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadBhandaras,
            color: AppColors.primaryOrange,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _bhandaras.length,
              itemBuilder: (context, index) {
                final bhandara = _bhandaras[index];
                return BhandaraCard(
                  bhandara: bhandara,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BhandaraDetailScreen(bhandara: bhandara),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  const _LocationBanner({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
