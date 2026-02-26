// lib/Alerts/CreateAlertScreen.dart
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
    final file = await _picker.pickImage(source: ImageSource.gallery);
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
        photoUrl = await FirebaseService.uploadImage(
          _photo!,
          'alerts/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else if (widget.child?.photoUrl != null) {
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

            // Photo
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_photo!, fit: BoxFit.cover))
                      : widget.child?.photoUrl != null
                      ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(widget.child!.photoUrl!,
                          fit: BoxFit.cover))
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_rounded,
                          size: 40, color: AppTheme.primary),
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

            const SizedBox(height: 24),

            _label('Child\'s Full Name *'),
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
              label: _isLoading ? 'Creating Alert...' : 'Create Missing Alert',
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

// Local DangerButton override with colors support
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final List<Color>? colors;

  const DangerButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors:
          colors ?? [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        boxShadow: [
          BoxShadow(
            color: (colors?.first ?? AppTheme.danger).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}