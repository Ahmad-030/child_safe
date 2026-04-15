// lib/AlertsScreens/CreateAlertScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared.dart';
import '../../firebase_service.dart';
import '../../app_models.dart';

class CreateAlertScreen extends StatefulWidget {
  final ChildProfile? child;
  const CreateAlertScreen({super.key, this.child});

  @override
  State<CreateAlertScreen> createState() => _CreateAlertScreenState();
}

class _CreateAlertScreenState extends State<CreateAlertScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _clothingCtrl = TextEditingController();
  File? _photo;
  bool _isLoading = false;
  bool _uploadingPhoto = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _nameCtrl.text = widget.child!.name;
      _ageCtrl.text = widget.child!.age.toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _clothingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (file != null) setState(() => _photo = File(file.path));
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty ||
        _ageCtrl.text.isEmpty ||
        _locationCtrl.text.isEmpty) {
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

      if (_photo != null) {
        setState(() => _uploadingPhoto = true);
        // Upload to Cloudinary — secure URL stored in Firestore
        photoUrl = await FirebaseService.uploadImage(_photo!, 'alerts');
        setState(() => _uploadingPhoto = false);
      } else if (widget.child?.photoUrl != null) {
        // Reuse existing Cloudinary URL from child profile
        photoUrl = widget.child!.photoUrl;
      }

      final alert = MissingAlert(
        id: '',
        childId: widget.child?.id ?? '',
        childName: _nameCtrl.text.trim(),
        childAge: int.tryParse(_ageCtrl.text) ?? 0,
        childPhotoUrl: photoUrl,
        reportedBy: uid,
        reporterName: user?.name ?? 'Unknown',
        lastSeenLocation: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        clothingDescription: _clothingCtrl.text.trim(),
        status: 'active',
        reportedAt: DateTime.now(),
      );

      await FirebaseService.createMissingAlert(alert);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing alert created! Community notified.'),
            backgroundColor: AppTheme.success,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Create Missing Alert'),
        backgroundColor: AppTheme.danger,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_rounded, color: AppTheme.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This will immediately alert all nearby volunteers and authorities.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.danger),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // Photo picker
            Center(
              child: GestureDetector(
                onTap: _uploadingPhoto ? null : _pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: _uploadingPhoto
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: AppTheme.primary, strokeWidth: 2),
                        SizedBox(height: 8),
                        Text('Uploading...',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.primary)),
                      ],
                    ),
                  )
                      : _photo != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_photo!, fit: BoxFit.cover))
                      : widget.child?.photoUrl != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                          widget.child!.photoUrl!,
                          fit: BoxFit.cover))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 40,
                          color: AppTheme.primary),
                      const SizedBox(height: 8),
                      Text('Add Photo',
                          style: GoogleFonts.poppins(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),

            // Cloudinary label
            const SizedBox(height: 6),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_upload_rounded,
                      size: 12, color: AppTheme.textLight),
                  const SizedBox(width: 4),

                ],
              ),
            ),

            const SizedBox(height: 24),

            _label("Child's Full Name *"),
            const SizedBox(height: 8),
            AppTextField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_rounded),
            const SizedBox(height: 16),

            _label('Age *'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _ageCtrl,
                label: 'Age',
                icon: Icons.cake_rounded,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            _label('Last Seen Location *'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _locationCtrl,
                label: 'e.g. Near City Park, Sector 7',
                icon: Icons.location_on_rounded),
            const SizedBox(height: 16),

            _label('Clothing Description'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _clothingCtrl,
                label: 'e.g. Blue shirt, red cap',
                icon: Icons.checkroom_rounded),
            const SizedBox(height: 16),

            _label('Additional Details'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _descCtrl,
                label: 'Physical features, marks, etc.',
                icon: Icons.description_rounded,
                maxLines: 3),

            const SizedBox(height: 32),

            DangerButton(
              label: _isLoading
                  ? (_uploadingPhoto
                  ? 'Uploading photo...'
                  : 'Creating Alert...')
                  : 'Create Missing Alert',
              icon: Icons.warning_rounded,
              isLoading: _isLoading,
              onTap: _submit,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark),
  );
}