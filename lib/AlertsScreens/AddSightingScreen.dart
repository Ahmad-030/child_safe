// lib/AlertsScreens/AddSightingScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';
import '../face_verification_sheet.dart';
import '../face_verification_service.dart';

class AddSightingScreen extends StatefulWidget {
  final String alertId;
  final String childName;
  final String? childPhotoUrl;
  const AddSightingScreen({
    super.key,
    required this.alertId,
    required this.childName,
    this.childPhotoUrl,
  });

  @override
  State<AddSightingScreen> createState() => _AddSightingScreenState();
}

class _AddSightingScreenState extends State<AddSightingScreen> {
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  File? _verifiedPhoto;
  FaceVerificationResult? _verificationResult;
  bool _isLoading = false;
  bool _fetchingLocation = false;
  bool _uploadingPhoto = false;
  bool _faceVerified = false;
  double? _lat, _lng;

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
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

  void _openFaceVerification() {
    FaceVerificationSheet.show(
      context,
      originalPhotoUrl: widget.childPhotoUrl,
      childName: widget.childName,
      actionLabel: 'Use This Photo',
      onVerified: (File photo, FaceVerificationResult result) {
        setState(() {
          _verifiedPhoto = photo;
          _verificationResult = result;
          // Only mark as truly verified on an actual match
          _faceVerified = result.isMatch;
        });
      },
      onCancelled: () {},
    );
  }

  Future<void> _submit() async {
    if (_locationCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        _contactCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all required fields'),
            backgroundColor: AppTheme.danger),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseService.currentUid!;
      final user = await FirebaseService.getUserProfile(uid);
      String? photoUrl;
      if (_verifiedPhoto != null) {
        setState(() => _uploadingPhoto = true);
        photoUrl =
        await FirebaseService.uploadImage(_verifiedPhoto!, 'sightings');
        setState(() => _uploadingPhoto = false);
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
        reporterContact: _contactCtrl.text.trim(),
        reportedAt: DateTime.now(),
      );
      await FirebaseService.addSighting(sighting);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sighting reported! +10 points added.'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers for verification card display ────────────────────────────────

  Color get _cardBorderColor {
    if (_faceVerified) return AppTheme.success.withOpacity(0.4);
    if (_verificationResult != null) return AppTheme.warning.withOpacity(0.4);
    return AppTheme.primary.withOpacity(0.25);
  }

  Color get _cardBgColor {
    if (_faceVerified) return AppTheme.success.withOpacity(0.07);
    if (_verificationResult != null) return AppTheme.warning.withOpacity(0.07);
    return AppTheme.primary.withOpacity(0.06);
  }

  Color get _cardIconColor {
    if (_faceVerified) return AppTheme.success;
    if (_verificationResult != null) return AppTheme.warning;
    return AppTheme.primary;
  }

  String get _cardTitle {
    if (_faceVerified) return 'Face Verified ✅';
    if (_verificationResult != null) {
      if (_verificationResult!.isInconclusive) return 'Verification Incomplete ⚠️';
      return 'Face Did Not Match ❌';
    }
    return 'Add Photo & Verify Face';
  }

  String get _cardSubtitle {
    if (_faceVerified) {
      return 'Face API confirmed this is ${widget.childName}';
    }
    if (_verificationResult != null) {
      return _verificationResult!.message;
    }
    return 'Take a photo — Face API will compare with original';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
          title: const Text('Report Sighting'),
          backgroundColor: AppTheme.warning),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
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
            const SizedBox(height: 20),

            // Face verification card
            GestureDetector(
              onTap: _openFaceVerification,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorderColor, width: 1.5),
                ),
                child: Row(children: [
                  // Photo thumbnail or icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _cardIconColor.withOpacity(0.12),
                    ),
                    child: _verifiedPhoto != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_verifiedPhoto!,
                          fit: BoxFit.cover),
                    )
                        : Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 32,
                      color: _cardIconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cardTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _cardIconColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _cardSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _faceVerified
                                ? AppTheme.success
                                : _verificationResult != null
                                ? AppTheme.warning
                                : AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _faceVerified
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: _cardIconColor,
                    size: _faceVerified ? 24 : 16,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Location field
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

            // Reporter contact field
            Text('Your Contact Number *',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppTextField(
              controller: _contactCtrl,
              label: 'Phone number (so family can reach you)',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Description field
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
              label: _isLoading
                  ? (_uploadingPhoto ? 'Uploading photo...' : 'Submitting...')
                  : 'Submit Sighting (+10 pts)',
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