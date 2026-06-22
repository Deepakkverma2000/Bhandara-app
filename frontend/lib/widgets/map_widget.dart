import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/place_search_result.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';

class MapPickerWidget extends StatefulWidget {
  final LatLng initialPosition;
  final ValueChanged<LatLng> onPositionChanged;
  final ValueChanged<PlaceSearchResult>? onPlaceSelected;

  const MapPickerWidget({
    super.key,
    required this.initialPosition,
    required this.onPositionChanged,
    this.onPlaceSelected,
  });

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late LatLng _selectedPosition;
  late MapController _mapController;
  final _searchController = TextEditingController();
  final _geocodingService = GeocodingService();
  final _locationService = LocationService();

  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLocating = false;
  bool _suppressSearchListener = false;
  int _searchRequestId = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(MapPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_samePosition(widget.initialPosition, _selectedPosition)) {
      _moveToPosition(widget.initialPosition, notifyParent: false);
    }
  }

  bool _samePosition(LatLng a, LatLng b) =>
      a.latitude == b.latitude && a.longitude == b.longitude;

  void _moveToPosition(LatLng position, {bool notifyParent = true}) {
    if (_samePosition(_selectedPosition, position)) return;

    setState(() => _selectedPosition = position);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(position, 16);
      if (notifyParent) widget.onPositionChanged(position);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (_suppressSearchListener) return;

    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < 3) {
      _searchRequestId++;
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final requestId = ++_searchRequestId;
      if (!mounted) return;

      setState(() => _isSearching = true);
      try {
        final results = await _geocodingService.searchPlaces(trimmed);
        if (!mounted || requestId != _searchRequestId) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted || requestId != _searchRequestId) return;
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  void _selectPlace(PlaceSearchResult place) {
    _debounceTimer?.cancel();
    _searchRequestId++;

    final position = LatLng(place.latitude, place.longitude);
    final label = place.displayName.split(',').first.trim();

    setState(() {
      _searchResults = [];
      _isSearching = false;
      _selectedPosition = position;
    });

    _suppressSearchListener = true;
    _searchController.text = label;
    _suppressSearchListener = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(position, 16);
      widget.onPositionChanged(position);
      widget.onPlaceSelected?.call(place);
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      await _locationService.requestPermission();
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get current location')),
          );
        }
        return;
      }
      _moveToPosition(LatLng(position.latitude, position.longitude));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchRequestId++;
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select location on map',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search place (e.g. Karol Bagh, Delhi)',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _debounceTimer?.cancel();
                      _searchRequestId++;
                      _suppressSearchListener = true;
                      _searchController.clear();
                      _suppressSearchListener = false;
                      setState(() {
                        _searchResults = [];
                        _isSearching = false;
                      });
                    },
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          ),
          onChanged: _searchPlaces,
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < _searchResults.length; index++) ...[
                  if (index > 0)
                    Divider(height: 1, color: Colors.grey.shade200),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place, color: AppColors.primaryOrange),
                    title: Text(
                      _searchResults[index].displayName.split(',').take(2).join(','),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () => _selectPlace(_searchResults[index]),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLocating ? null : _useCurrentLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_isLocating ? 'Getting location...' : 'Use your current location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryOrange,
              side: const BorderSide(color: AppColors.primaryOrange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPosition,
                initialZoom: 15,
                onTap: (_, point) => _moveToPosition(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bhandaralive.bhandara_live',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lat: ${_selectedPosition.latitude.toStringAsFixed(5)}, '
          'Lng: ${_selectedPosition.longitude.toStringAsFixed(5)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap map or search a place to set location',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

class BhandaraMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback? onTap;

  const BhandaraMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final position = LatLng(latitude, longitude);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bhandaralive.bhandara_live',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onTap != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Open in Maps',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
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
