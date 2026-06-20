import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_search_result.dart';

class GeocodingService {
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.trim().length < 3) return [];

    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'q': query.trim(),
        'format': 'json',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'in',
      },
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'BhandaraLive/1.0 (com.bhandaralive.bhandara_live)'},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      final address = map['address'] as Map<String, dynamic>? ?? {};

      final street = _firstNonEmpty([
        address['road'],
        address['neighbourhood'],
        address['suburb'],
        address['hamlet'],
      ]);

      final village = _firstNonEmpty([
        address['city'],
        address['town'],
        address['village'],
        address['state_district'],
        address['county'],
      ]);

      final pinCode = address['postcode']?.toString();

      return PlaceSearchResult(
        displayName: map['display_name'] as String? ?? query,
        latitude: double.parse(map['lat'] as String),
        longitude: double.parse(map['lon'] as String),
        street: street,
        village: village,
        pinCode: pinCode,
      );
    }).toList();
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
