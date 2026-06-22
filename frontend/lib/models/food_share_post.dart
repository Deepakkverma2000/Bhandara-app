class FoodSharePost {
  final String id;
  final String? postedBy;
  final String contactName;
  final String phoneNumber;
  final String? eventName;
  final String foodDescription;
  final String? quantity;
  final String street;
  final String village;
  final String pinCode;
  final double latitude;
  final double longitude;
  final String status;
  final String? acceptedBy;
  final String? acceptedByName;
  final String? acceptedByPhone;
  final DateTime? acceptedPickupTime;
  final int? acceptedPlatesRequired;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final double? distanceKm;
  final bool isOwner;

  const FoodSharePost({
    required this.id,
    this.postedBy,
    required this.contactName,
    required this.phoneNumber,
    this.eventName,
    required this.foodDescription,
    this.quantity,
    required this.street,
    required this.village,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.acceptedBy,
    this.acceptedByName,
    this.acceptedByPhone,
    this.acceptedPickupTime,
    this.acceptedPlatesRequired,
    this.acceptedAt,
    required this.createdAt,
    this.distanceKm,
    this.isOwner = false,
  });

  bool get isOpen => status == 'open';
  bool get isAccepted => status == 'accepted';

  String get fullAddress => '$street, $village - $pinCode';

  factory FoodSharePost.fromJson(Map<String, dynamic> json) {
    return FoodSharePost(
      id: json['id'] as String,
      postedBy: json['postedBy'] as String?,
      contactName: json['contactName'] as String? ?? 'Unknown',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      eventName: json['eventName'] as String?,
      foodDescription: json['foodDescription'] as String? ?? '',
      quantity: json['quantity'] as String?,
      street: json['street'] as String? ?? '',
      village: json['village'] as String? ?? '',
      pinCode: json['pinCode'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String? ?? 'open',
      acceptedBy: json['acceptedBy'] as String?,
      acceptedByName: json['acceptedByName'] as String?,
      acceptedByPhone: json['acceptedByPhone'] as String?,
      acceptedPickupTime: json['acceptedPickupTime'] != null
          ? DateTime.parse(json['acceptedPickupTime'] as String)
          : null,
      acceptedPlatesRequired: json['acceptedPlatesRequired'] != null
          ? (json['acceptedPlatesRequired'] as num).toInt()
          : null,
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      distanceKm: json['distanceKm'] != null
          ? (json['distanceKm'] as num).toDouble()
          : null,
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }
}
