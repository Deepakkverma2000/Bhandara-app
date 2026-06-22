import 'bhandara.dart';
import 'food_share_post.dart';

enum HomeActivityType { bhandara, foodShare }

class HomeActivityItem {
  final String id;
  final HomeActivityType type;
  final String publisherName;
  final String title;
  final String location;
  final String? imageUrl;
  final double? distanceKm;

  const HomeActivityItem({
    required this.id,
    required this.type,
    required this.publisherName,
    required this.title,
    required this.location,
    this.imageUrl,
    this.distanceKm,
  });

  factory HomeActivityItem.fromBhandara(Bhandara b) {
    return HomeActivityItem(
      id: 'bhandara-${b.id}',
      type: HomeActivityType.bhandara,
      publisherName: b.publisherName,
      title: b.bhandaraName,
      location: '${b.village}, ${b.pinCode}',
      imageUrl: b.imageUrl,
      distanceKm: b.distanceKm,
    );
  }

  factory HomeActivityItem.fromFoodShare(FoodSharePost post) {
    return HomeActivityItem(
      id: 'food-${post.id}',
      type: HomeActivityType.foodShare,
      publisherName: post.contactName,
      title: post.foodDescription,
      location: post.fullAddress,
      imageUrl: null,
      distanceKm: post.distanceKm,
    );
  }

  String get typeLabel =>
      type == HomeActivityType.bhandara ? 'Bhandara' : 'Share Food';

  String get actionVerb =>
      type == HomeActivityType.bhandara ? 'Added' : 'Shared';
}
