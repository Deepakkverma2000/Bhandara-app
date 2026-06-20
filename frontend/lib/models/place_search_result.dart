class PlaceSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? street;
  final String? village;
  final String? pinCode;

  PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.street,
    this.village,
    this.pinCode,
  });
}
