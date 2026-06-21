class Bhandara {
  final String id;
  final String bhandaraName;
  final String publisherName;
  final String street;
  final String village;
  final String pinCode;
  final DateTime date;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? postedBy;
  final DateTime createdAt;
  final double? distanceKm;

  Bhandara({
    required this.id,
    required this.bhandaraName,
    required this.publisherName,
    required this.street,
    required this.village,
    required this.pinCode,
    required this.date,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.postedBy,
    required this.createdAt,
    this.distanceKm,
  });

  String get fullAddress => '$street, $village - $pinCode';

  factory Bhandara.fromJson(Map<String, dynamic> json) {
    return Bhandara(
      id: json['id'] as String,
      bhandaraName: (json['bhandaraName'] ?? json['name']) as String,
      publisherName: (json['publisherName'] ?? 'Unknown') as String,
      street: json['street'] as String,
      village: json['village'] as String,
      pinCode: json['pinCode'] as String,
      date: DateTime.parse(json['date'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      postedBy: json['postedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      distanceKm: json['distanceKm'] != null
          ? (json['distanceKm'] as num).toDouble()
          : null,
    );
  }
}
