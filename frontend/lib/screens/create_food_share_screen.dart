import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../models/food_share_post.dart';
import '../models/place_search_result.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/map_widget.dart';

class CreateFoodShareScreen extends StatefulWidget {
  final FoodSharePost? existingPost;

  const CreateFoodShareScreen({super.key, this.existingPost});

  bool get isEditing => existingPost != null;

  @override
  State<CreateFoodShareScreen> createState() => _CreateFoodShareScreenState();
}

class _CreateFoodShareScreenState extends State<CreateFoodShareScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _foodDescriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _streetController = TextEditingController();
  final _villageController = TextEditingController();
  final _pinCodeController = TextEditingController();

  final _apiService = ApiService();
  final _locationService = LocationService();

  LatLng? _mapPosition;
  bool _isSubmitting = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPost;
    if (existing != null) {
      _contactNameController.text = existing.contactName;
      _phoneController.text = existing.phoneNumber;
      _eventNameController.text = existing.eventName ?? '';
      _foodDescriptionController.text = existing.foodDescription;
      _quantityController.text = existing.quantity ?? '';
      _streetController.text = existing.street;
      _villageController.text = existing.village;
      _pinCodeController.text = existing.pinCode;
      _mapPosition = LatLng(existing.latitude, existing.longitude);
      _isLoadingLocation = false;
    } else {
      final displayName = AuthService.instance.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        _contactNameController.text = displayName;
      }
      _initMapLocation();
    }
  }

  Future<void> _initMapLocation() async {
    await _locationService.requestPermission();
    final position = await _locationService.getCurrentPosition();

    if (mounted) {
      setState(() {
        _mapPosition = position != null
            ? LatLng(position.latitude, position.longitude)
            : const LatLng(28.6139, 77.2090);
        _isLoadingLocation = false;
      });
    }
  }

  void _onPlaceSelected(PlaceSearchResult place) {
    if (place.street != null && place.street!.isNotEmpty) {
      _streetController.text = place.street!;
    }
    if (place.village != null && place.village!.isNotEmpty) {
      _villageController.text = place.village!;
    }
    if (place.pinCode != null && place.pinCode!.isNotEmpty) {
      _pinCodeController.text = place.pinCode!;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mapPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup location on map')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        await _apiService.updateFoodSharePost(
          id: widget.existingPost!.id,
          contactName: _contactNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          eventName: _eventNameController.text.trim(),
          foodDescription: _foodDescriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          street: _streetController.text.trim(),
          village: _villageController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          latitude: _mapPosition!.latitude,
          longitude: _mapPosition!.longitude,
        );
      } else {
        await _apiService.createFoodSharePost(
          contactName: _contactNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          eventName: _eventNameController.text.trim(),
          foodDescription: _foodDescriptionController.text.trim(),
          quantity: _quantityController.text.trim(),
          street: _streetController.text.trim(),
          village: _villageController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          latitude: _mapPosition!.latitude,
          longitude: _mapPosition!.longitude,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Food share post updated!'
                  : 'Food share post added!',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _phoneController.dispose();
    _eventNameController.dispose();
    _foodDescriptionController.dispose();
    _quantityController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Food Post' : 'Share Leftover Food'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 88 + bottomInset),
          children: [
            Text(
              'After an event, if food is remaining, post here so others can come and collect it.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name *',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '10-digit mobile number',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              validator: (v) {
                if (v == null || v.trim().length != 10) {
                  return 'Enter valid 10-digit phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: 'Event Name (optional)',
                hintText: 'e.g. Wedding, Temple function',
                prefixIcon: Icon(Icons.event_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foodDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Food Available *',
                hintText: 'e.g. Dal, roti, sabzi, sweets',
                prefixIcon: Icon(Icons.restaurant_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Describe the food available' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity (optional)',
                hintText: 'e.g. 20 plates, 5 kg',
                prefixIcon: Icon(Icons.scale_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Street / Mohalla *',
                prefixIcon: Icon(Icons.signpost),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Street is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _villageController,
              decoration: const InputDecoration(
                labelText: 'Village / City *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'City is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinCodeController,
              decoration: const InputDecoration(
                labelText: 'Pin Code *',
                prefixIcon: Icon(Icons.pin),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              validator: (v) {
                if (v == null || v.trim().length != 6) {
                  return 'Enter valid 6-digit pin code';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (_isLoadingLocation)
              const Center(child: CircularProgressIndicator())
            else if (_mapPosition != null)
              MapPickerWidget(
                initialPosition: _mapPosition!,
                onPositionChanged: (pos) {
                  if (_mapPosition != null && _mapPosition == pos) return;
                  setState(() => _mapPosition = pos);
                },
                onPlaceSelected: _onPlaceSelected,
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Save Changes' : 'Post Food',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
