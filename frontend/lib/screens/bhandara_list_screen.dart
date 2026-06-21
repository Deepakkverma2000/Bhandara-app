import 'package:flutter/material.dart';

import '../models/bhandara.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppStyles.screenHeader(
          title: 'Find Bhandara',
          subtitle: _isLoading
              ? 'Loading nearby events...'
              : '${_bhandaras.length} active listing${_bhandaras.length == 1 ? '' : 's'}',
          trailing: IconButton(
            onPressed: loadBhandaras,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.maroon,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.maroon),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppStyles.cardShadow,
                ),
                child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              const Text(
                'Could not connect to server',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure backend is running on your PC.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loadBhandaras,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bhandaras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.soup_kitchen_rounded, size: 64, color: AppColors.saffron.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Bhandara yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to post a Bhandara using the + button below.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _LocationBanner(
          enabled: _locationEnabled,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadBhandaras,
            color: AppColors.maroon,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
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
  final bool enabled;

  const _LocationBanner({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
        borderRadius: AppStyles.borderRadiusSm,
        border: Border.all(
          color: enabled ? Colors.green.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.near_me_rounded : Icons.location_off_rounded,
            size: 18,
            color: enabled ? Colors.green.shade700 : Colors.amber.shade900,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enabled
                  ? 'Sorted by nearest Bhandara first'
                  : 'Enable location to sort by distance',
              style: TextStyle(
                color: enabled ? Colors.green.shade800 : Colors.amber.shade900,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
