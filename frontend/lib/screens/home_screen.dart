import 'dart:async';

import 'package:flutter/material.dart';

import '../models/bhandara.dart';
import '../models/food_share_post.dart';
import '../models/home_activity_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../widgets/deity_carousel.dart';
import '../widgets/live_activity_card.dart';
import '../widgets/services_grid.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onFindBhandara;
  final VoidCallback onPostFood;

  const HomeScreen({
    super.key,
    required this.onFindBhandara,
    required this.onPostFood,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  final _locationService = LocationService();

  List<HomeActivityItem> _activityItems = [];
  int _activityIndex = 0;
  Timer? _activityTimer;

  @override
  void initState() {
    super.initState();
    _loadActivityFeed();
    NotificationService.instance.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    NotificationService.instance.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openNotifications() async {
    if (!mounted) return;

    unawaited(NotificationService.instance.markAllAsRead());

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );

    if (mounted) setState(() {});
  }

  Future<void> _loadActivityFeed() async {
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

      final results = await Future.wait([
        _apiService.fetchBhandaras(latitude: lat, longitude: lng),
        _apiService.fetchFoodSharePosts(latitude: lat, longitude: lng),
      ]);

      final bhandaras = results[0] as List<Bhandara>;
      final foodShares = results[1] as List<FoodSharePost>;

      final items = <HomeActivityItem>[
        ...bhandaras.map(HomeActivityItem.fromBhandara),
        ...foodShares.map(HomeActivityItem.fromFoodShare),
      ];

      items.sort((a, b) {
        final aDist = a.distanceKm;
        final bDist = b.distanceKm;
        if (aDist == null && bDist == null) return 0;
        if (aDist == null) return 1;
        if (bDist == null) return -1;
        return aDist.compareTo(bDist);
      });

      if (!mounted) return;

      setState(() {
        _activityItems = items.take(6).toList();
        _activityIndex = 0;
      });

      _startActivityRotation();
    } catch (_) {}
  }

  void _startActivityRotation() {
    _activityTimer?.cancel();

    if (_activityItems.length <= 1) return;

    _activityTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _activityItems.isEmpty) return;
      setState(() {
        _activityIndex = (_activityIndex + 1) % _activityItems.length;
      });
    });
  }

  HomeActivityItem? get _currentActivity {
    if (_activityItems.isEmpty) return null;
    return _activityItems[_activityIndex.clamp(0, _activityItems.length - 1)];
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        backgroundColor: AppColors.maroon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (AuthService.instance.displayName ?? 'Devotee').split(' ').first;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroHeader(
              firstName: firstName,
              unreadCount: NotificationService.instance.unreadCount,
              onNotificationsTap: _openNotifications,
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: LiveActivityCard(
                item: _currentActivity,
                itemCount: _activityItems.length,
                activeIndex: _activityIndex,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppStyles.sectionHeader(
                    'Quick Actions',
                    subtitle: 'Find seva near you or share your Bhandara',
                    icon: Icons.bolt_rounded,
                  ),
                  ServicesGrid(
                    onFindBhandara: widget.onFindBhandara,
                    onPostFood: widget.onPostFood,
                    onPanchang: () => _showComingSoon('Panchang'),
                    onRewards: () => _showComingSoon('Rewards'),
                  ),
                  const SizedBox(height: 20),
                  _OperationalBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String firstName;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  const _HeroHeader({
    required this.firstName,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Icon(
              Icons.temple_hindu_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _UserAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaste, $firstName',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Bhandara Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _NotificationBellButton(
                      unreadCount: unreadCount,
                      onTap: onNotificationsTap,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.lightGold, AppColors.gold, Colors.white],
                  ).createShader(bounds),
                  child: const Text(
                    "India's First Live\nBhandara App",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppStyles.liveBadge(scale: 1.1),
                    const SizedBox(width: 10),
                    Text(
                      'Seva • Food • Community',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const DeityCarousel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final avatarUrl = AuthService.instance.avatarUrl;
    final name = AuthService.instance.displayName ?? 'User';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            image: avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: avatarUrl == null
                ? LinearGradient(
                    colors: [
                      AppColors.maroon.withValues(alpha: 0.7),
                      AppColors.deepMaroon.withValues(alpha: 0.9),
                    ],
                  )
                : null,
          ),
          child: avatarUrl == null
              ? Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBellButton({
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
              if (unreadCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.templeRed,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 1.5),
                        ),
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
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

class _OperationalBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.maroon,
            AppColors.deepMaroon.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: AppStyles.borderRadiusMd,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: AppStyles.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.lightGold, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operational in Delhi NCR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Discover live Bhandaras around you',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AppStyles.liveBadge(scale: 1.05),
        ],
      ),
    );
  }
}
