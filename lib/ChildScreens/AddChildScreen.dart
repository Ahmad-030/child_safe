// lib/ChildScreens/AddChildScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../shared.dart';
import '../firebase_service.dart';
import '../app_models.dart';

class AddChildScreen extends StatefulWidget {
  final ChildProfile? existingChild;
  const AddChildScreen({super.key, this.existingChild});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _medCtrl = TextEditingController();
  String _gender = 'Male';
  File? _photo;
  bool _isLoading = false;
  bool _uploadingPhoto = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingChild != null) {
      final c = widget.existingChild!;
      _nameCtrl.text = c.name;
      _ageCtrl.text = c.age.toString();
      _bloodCtrl.text = c.bloodGroup;
      _descCtrl.text = c.description;
      _contactCtrl.text = c.emergencyContact;
      _gender = c.gender;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _bloodCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    _medCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty ||
        _ageCtrl.text.isEmpty ||
        _contactCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill required fields'),
            backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseService.currentUid!;
      String? photoUrl = widget.existingChild?.photoUrl;

      if (_photo != null) {
        setState(() => _uploadingPhoto = true);
        // Upload to Cloudinary — returns secure URL saved in Firestore
        photoUrl = await FirebaseService.uploadImage(_photo!, 'children');
        setState(() => _uploadingPhoto = false);
      }

      final meds = _medCtrl.text.trim().isNotEmpty
          ? _medCtrl.text.split(',').map((e) => e.trim()).toList()
          : <String>[];

      final child = ChildProfile(
        id: widget.existingChild?.id ?? '',
        parentUid: uid,
        name: _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        gender: _gender,
        photoUrl: photoUrl,
        bloodGroup: _bloodCtrl.text.trim().isEmpty
            ? 'Unknown'
            : _bloodCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        emergencyContact: _contactCtrl.text.trim(),
        medicalConditions: meds,
      );

      if (widget.existingChild != null) {
        await FirebaseService.updateChildProfile(child.id, child.toMap());
      } else {
        await FirebaseService.addChildProfile(child);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingChild != null
                ? 'Child profile updated!'
                : 'Child profile added!'),
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
        title: Text(
            widget.existingChild != null ? 'Edit Child' : 'Add Child Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo picker
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _uploadingPhoto
                        ? null
                        : () async {
                      final file = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1800,
                          maxHeight: 1800,
                          imageQuality: 85);
                      if (file != null) {
                        setState(() => _photo = File(file.path));
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.1),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                            width: 3),
                      ),
                      child: _uploadingPhoto
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary, strokeWidth: 2))
                          : _photo != null
                          ? ClipOval(
                          child:
                          Image.file(_photo!, fit: BoxFit.cover))
                          : widget.existingChild?.photoUrl != null
                          ? ClipOval(
                          child: Image.network(
                              widget.existingChild!.photoUrl!,
                              fit: BoxFit.cover))
                          : const Icon(Icons.child_care_rounded,
                          size: 50, color: AppTheme.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Cloudinary badge
            const SizedBox(height: 8),


            const SizedBox(height: 28),

            _label('Full Name *'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _nameCtrl,
                label: "Child's full name",
                icon: Icons.person_rounded),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Age *'),
                    const SizedBox(height: 8),
                    AppTextField(
                        controller: _ageCtrl,
                        label: 'Age',
                        icon: Icons.cake_rounded,
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Gender'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.15),
                            width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          isExpanded: true,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppTheme.textDark),
                          items: ['Male', 'Female', 'Other']
                              .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _gender = v ?? 'Male'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            _label('Blood Group'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _bloodCtrl,
                label: 'e.g. O+, A-, B+',
                icon: Icons.bloodtype_rounded),
            const SizedBox(height: 16),

            _label('Emergency Contact *'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _contactCtrl,
                label: 'Phone number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            _label('Medical Conditions'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _medCtrl,
                label: 'Comma separated (e.g. Asthma, Allergies)',
                icon: Icons.medical_services_rounded),
            const SizedBox(height: 16),

            _label('Description / Identifying Features'),
            const SizedBox(height: 8),
            AppTextField(
                controller: _descCtrl,
                label: 'Height, marks, features...',
                icon: Icons.description_rounded,
                maxLines: 3),

            const SizedBox(height: 32),

            GradientButton(
              label: _isLoading
                  ? (_uploadingPhoto
                  ? 'Uploading photo...'
                  : 'Saving...')
                  : widget.existingChild != null
                  ? 'Update Profile'
                  : 'Add Child',
              icon: Icons.save_rounded,
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