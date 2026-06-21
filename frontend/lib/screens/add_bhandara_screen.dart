import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../models/bhandara.dart';
import '../models/place_search_result.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/map_widget.dart';

class AddBhandaraScreen extends StatefulWidget {
  final Bhandara? existingBhandara;

  const AddBhandaraScreen({super.key, this.existingBhandara});

  bool get isEditing => existingBhandara != null;

  @override
  State<AddBhandaraScreen> createState() => _AddBhandaraScreenState();
}

class _AddBhandaraScreenState extends State<AddBhandaraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bhandaraNameController = TextEditingController();
  final _publisherNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _villageController = TextEditingController();
  final _pinCodeController = TextEditingController();

  final _apiService = ApiService();
  final _locationService = LocationService();
  final _imagePicker = ImagePicker();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  File? _invitationImage;
  String? _existingImageUrl;
  LatLng? _mapPosition;
  bool _isSubmitting = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingBhandara;
    if (existing != null) {
      _bhandaraNameController.text = existing.bhandaraName;
      _publisherNameController.text = existing.publisherName;
      _streetController.text = existing.street;
      _villageController.text = existing.village;
      _pinCodeController.text = existing.pinCode;
      _selectedDate = existing.date;
      _existingImageUrl = existing.imageUrl;
      _mapPosition = LatLng(existing.latitude, existing.longitude);
      _isLoadingLocation = false;
    } else {
      _initMapLocation();
      final displayName = AuthService.instance.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        _publisherNameController.text = displayName;
      }
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

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _invitationImage = File(picked.path);
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time != null) {
      setState(() {
        _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mapPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select location on map')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.isEditing) {
        await _apiService.updateBhandara(
          id: widget.existingBhandara!.id,
          bhandaraName: _bhandaraNameController.text.trim(),
          publisherName: _publisherNameController.text.trim(),
          street: _streetController.text.trim(),
          village: _villageController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          date: _selectedDate,
          latitude: _mapPosition!.latitude,
          longitude: _mapPosition!.longitude,
          image: _invitationImage,
        );
      } else {
        await _apiService.createBhandara(
          bhandaraName: _bhandaraNameController.text.trim(),
          publisherName: _publisherNameController.text.trim(),
          street: _streetController.text.trim(),
          village: _villageController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          date: _selectedDate,
          latitude: _mapPosition!.latitude,
          longitude: _mapPosition!.longitude,
          image: _invitationImage,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Bhandara updated successfully!'
                  : 'Bhandara added successfully!',
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
    _bhandaraNameController.dispose();
    _publisherNameController.dispose();
    _streetController.dispose();
    _villageController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Bhandara' : 'Add Bhandara'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 88 + bottomInset),
          children: [
            TextFormField(
              controller: _bhandaraNameController,
              decoration: const InputDecoration(
                labelText: 'Bhandara Name *',
                hintText: 'e.g. Shri Ram Ji Ka Bhandara',
                prefixIcon: Icon(Icons.soup_kitchen_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bhandara name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _publisherNameController,
              decoration: const InputDecoration(
                labelText: 'Publisher Name *',
                hintText: 'Your name (jo add kar rahe hain)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Publisher name is required' : null,
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
                  v == null || v.trim().isEmpty ? 'Village is required' : null,
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
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Pin code is required';
                if (v.trim().length != 6) return 'Enter valid 6-digit pin code';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date & Time *'),
              subtitle: Text(dateFormat.format(_selectedDate)),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Invitation Image',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child: _invitationImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_invitationImage!, fit: BoxFit.cover),
                      )
                    : _existingImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 48, color: Colors.grey.shade500),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload invitation image',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoadingLocation)
              const Center(child: CircularProgressIndicator())
            else if (_mapPosition != null)
              MapPickerWidget(
                initialPosition: _mapPosition!,
                onPositionChanged: (pos) => setState(() => _mapPosition = pos),
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
                      widget.isEditing ? 'Save Changes' : 'Save Bhandara',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
