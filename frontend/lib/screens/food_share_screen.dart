import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/food_share_post.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../widgets/food_share_card.dart';
import 'create_food_share_screen.dart';

class FoodShareScreen extends StatefulWidget {
  const FoodShareScreen({super.key});

  @override
  State<FoodShareScreen> createState() => FoodShareScreenState();
}

class FoodShareScreenState extends State<FoodShareScreen> {
  final _apiService = ApiService();
  final _locationService = LocationService();

  List<FoodSharePost> _posts = [];
  bool _isLoading = true;
  String? _error;
  bool _locationEnabled = false;
  String? _processingPostId;

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
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

      final list = await _apiService.fetchFoodSharePosts(
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        setState(() {
          _posts = list;
          _locationEnabled = lat != null && lng != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreatePost() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateFoodShareScreen()),
    );
    if (added == true) {
      await loadPosts();
    }
  }

  Future<void> _editPost(FoodSharePost post) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFoodShareScreen(existingPost: post),
      ),
    );
    if (updated == true) {
      await loadPosts();
    }
  }

  Future<void> _acceptPost(FoodSharePost post) async {
    final nameController = TextEditingController(
      text: AuthService.instance.displayName ?? '',
    );
    final phoneController = TextEditingController();
    final platesController = TextEditingController(text: '1');
    var pickupTime = TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 1)),
    );

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final pickupLabel = pickupTime.format(context);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Accept food pickup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fill your details so ${post.contactName} can coordinate pickup.',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Your Phone *',
                        hintText: '10-digit number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Pickup Time *'),
                      subtitle: Text(pickupLabel),
                      trailing: const Icon(Icons.edit_outlined, size: 18),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: pickupTime,
                        );
                        if (picked != null) {
                          setDialogState(() => pickupTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: platesController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Plates Required *',
                        hintText: 'e.g. 5',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter your name')),
                      );
                      return;
                    }
                    if (phoneController.text.trim().length != 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter valid 10-digit phone')),
                      );
                      return;
                    }
                    final plates = int.tryParse(platesController.text.trim());
                    if (plates == null || plates < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter valid number of plates')),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Accept'),
                ),
              ],
            );
          },
        ),
      );

      if (confirmed != true || !mounted) return;

      final now = DateTime.now();
      var pickupDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickupTime.hour,
        pickupTime.minute,
      );
      if (!pickupDateTime.isAfter(now)) {
        pickupDateTime = pickupDateTime.add(const Duration(days: 1));
      }

      final platesRequired = int.parse(platesController.text.trim());

      setState(() => _processingPostId = post.id);

      await _apiService.acceptFoodSharePost(
        id: post.id,
        contactName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        pickupTime: pickupDateTime,
        platesRequired: platesRequired,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Accepted! Call ${post.contactName} at ${post.phoneNumber} for pickup.',
            ),
          ),
        );
        await loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
      platesController.dispose();
      if (mounted) setState(() => _processingPostId = null);
    }
  }

  Future<void> _deletePost(FoodSharePost post) async {
    final isAccepted = post.isAccepted;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove post?'),
        content: Text(
          isAccepted
              ? 'Food has been collected? This will remove your post from the list.'
              : 'Food is empty or no longer available? This will remove your post from the list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingPostId = post.id);

    try {
      await _apiService.deleteFoodSharePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed')),
        );
        await loadPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingPostId = null);
    }
  }

  bool _isPostOwner(FoodSharePost post) {
    if (post.isOwner) return true;
    final userId = AuthService.instance.currentUser?.id;
    return userId != null && post.postedBy == userId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppStyles.screenHeader(
          title: 'Share Food',
          subtitle: _isLoading
              ? 'Loading posts...'
              : '${_posts.length} leftover food post${_posts.length == 1 ? '' : 's'}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: loadPosts,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.maroon,
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _openCreatePost,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.saffron,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppStyles.cardDecoration(
              radius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.saffron,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Why Share Food?\n'
                    'After weddings, pujas, or any event, if extra food is left, post it here. '
                    'Nearby people or groups can accept and collect it — so good food is not wasted and seva reaches more people.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
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
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: loadPosts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'No leftover food posts yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Had an event with extra food? Post here so others can collect it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openCreatePost,
                icon: const Icon(Icons.add),
                label: const Text('Post Leftover Food'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadPosts,
      color: AppColors.maroon,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (_locationEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.near_me, size: 14, color: AppColors.saffron),
                  const SizedBox(width: 6),
                  Text(
                    'Sorted by nearest pickup location',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ..._posts.map(
            (post) {
              final isOwner = _isPostOwner(post);
              return FoodShareCard(
                post: post,
                isOwner: isOwner,
                isProcessing: _processingPostId == post.id,
                onAccept: post.isOpen && !isOwner ? () => _acceptPost(post) : null,
                onEdit: isOwner ? () => _editPost(post) : null,
                onDelete: isOwner ? () => _deletePost(post) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
