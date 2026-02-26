// lib/Alerts/AddSightingScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';

class AddSightingScreen extends StatefulWidget {
  final String alertId;
  const AddSightingScreen({super.key, required this.alertId});

  @override
  State<AddSightingScreen> createState() => _AddSightingScreenState();
}

class _AddSightingScreenState extends State<AddSightingScreen> {
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _photo;
  bool _isLoading = false;
  bool _fetchingLocation = false;
  double? _lat, _lng;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationCtrl.text =
        'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Location error: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_locationCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseService.currentUid!;
      final user = await FirebaseService.getUserProfile(uid);
      String? photoUrl;

      if (_photo != null) {
        photoUrl = await FirebaseService.uploadImage(
          _photo!,
          'sightings/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final sighting = Sighting(
        id: '',
        alertId: widget.alertId,
        reportedBy: uid,
        reporterName: user?.name ?? 'Anonymous',
        location: _locationCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        description: _descCtrl.text.trim(),
        photoUrl: photoUrl,
        reportedAt: DateTime.now(),
      );

      await FirebaseService.addSighting(sighting);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sighting reported! +10 points added.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Report Sighting'),
        backgroundColor: AppTheme.warning,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: AppTheme.warning.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.info_rounded, color: AppTheme.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reporting a sighting earns you +10 points and helps locate the child faster.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textDark),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Photo
            Center(
              child: GestureDetector(
                onTap: () async {
                  final file =
                  await _picker.pickImage(source: ImageSource.camera);
                  if (file != null) setState(() => _photo = File(file.path));
                },
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.warning.withOpacity(0.4), width: 2),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_photo!, fit: BoxFit.cover))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_rounded,
                          size: 36, color: AppTheme.warning),
                      const SizedBox(height: 8),
                      Text('Add Photo\n(Optional)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: AppTheme.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Sighting Location *',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: AppTextField(
                  controller: _locationCtrl,
                  label: 'Where did you see the child?',
                  icon: Icons.location_on_rounded,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _fetchingLocation ? null : _getLocation,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _fetchingLocation
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded,
                      color: AppTheme.primary),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            Text('Description *',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              controller: _descCtrl,
              label: 'Describe what you saw...',
              icon: Icons.description_rounded,
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            GradientButton(
              label: _isLoading ? 'Submitting...' : 'Submit Sighting (+10 pts)',
              icon: Icons.send_rounded,
              isLoading: _isLoading,
              onTap: _submit,
              colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            ),
          ],
        ),
      ),
    );
  }
}