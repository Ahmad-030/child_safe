// lib/EmergencyScreen/EmergencyAlert.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../firebase_service.dart';
import '../app_models.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _lastSeenController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late AnimationController _fadeController;
  bool _isSubmitting = false;
  bool _uploadingPhoto = false;
  bool _fetchingLocation = false;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _lastSeenController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _fadeController.dispose();
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
        _lastSeenController.text =
        'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Select Photo Source',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A))),
              const SizedBox(height: 20),
              _buildImageSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take Photo',
                subtitle: 'Use camera',
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _buildImageSourceOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from Gallery',
                subtitle: 'Select existing photo',
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border:
          Border.all(color: const Color(0xFFEF4444).withOpacity(0.1)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFEF4444), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A))),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Color(0xFF94A3B8), size: 18),
        ]),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}',
                style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _lastSeenController.text.isEmpty ||
        _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload a photo of the child',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload to Cloudinary — secure URL then stored in Firestore
      setState(() => _uploadingPhoto = true);
      final photoUrl =
      await FirebaseService.uploadImage(_selectedImage!, 'emergency');
      setState(() => _uploadingPhoto = false);

      final uid = FirebaseService.currentUid ?? 'anonymous_emergency';
      final alert = MissingAlert(
        id: '',
        childId: '',
        childName: _nameController.text.trim(),
        childAge: int.tryParse(_ageController.text.trim()) ?? 0,
        childPhotoUrl: photoUrl,
        reportedBy: uid,
        reporterName: 'Emergency Report',
        lastSeenLocation: _lastSeenController.text.trim(),
        lastSeenLat: _lat,
        lastSeenLng: _lng,
        description: _descriptionController.text.trim(),
        clothingDescription: '',
        status: 'active',
        reportedAt: DateTime.now(),
        emergencyContact: _contactController.text.trim(),
        isEmergency: true,
      );

      await FirebaseService.createEmergencyAlert(alert);

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Submission failed: $e', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 64),
            ),
            const SizedBox(height: 24),
            Text('Report Submitted',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Text(
              'Your emergency report photo has been saved to Cloudinary and the alert is live in the database. All nearby volunteers have been notified.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                  height: 1.6),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Done',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEF4444).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor:
                        const Color(0xFFEF4444).withOpacity(0.08),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Report',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A))),
                          Text('Report a missing child — saves to database',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emergency_rounded,
                          color: Color(0xFFEF4444), size: 24),
                    ),
                  ]),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo upload
                          Center(
                            child: GestureDetector(
                              onTap:
                              _uploadingPhoto ? null : _pickImage,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: _selectedImage == null
                                      ? const Color(0xFFEF4444)
                                      .withOpacity(0.08)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: _uploadingPhoto
                                    ? const Center(
                                  child: Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                          color: Color(0xFFEF4444),
                                          strokeWidth: 2),
                                      SizedBox(height: 10),
                                      Text('Uploading to\nCloudinary...',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFEF4444))),
                                    ],
                                  ),
                                )
                                    : _selectedImage == null
                                    ? Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons
                                            .add_photo_alternate_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 48),
                                    const SizedBox(height: 12),
                                    Text('Upload Photo',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: const Color(
                                                0xFFEF4444))),
                                    Text('Required',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(
                                                0xFF64748B))),
                                  ],
                                )
                                    : ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(18),
                                  child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),

                          // Cloudinary badge
                          const SizedBox(height: 8),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_upload_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text('Photo stored via Cloudinary',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B))),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          _buildLabel("Child's Full Name *"),
                          const SizedBox(height: 8),
                          _buildTextField(
                              controller: _nameController,
                              hint: 'Enter full name',
                              icon: Icons.person_outline_rounded),
                          const SizedBox(height: 16),

                          _buildLabel('Age *'),
                          const SizedBox(height: 8),
                          _buildTextField(
                              controller: _ageController,
                              hint: 'Enter age',
                              icon: Icons.cake_rounded,
                              keyboardType: TextInputType.number),
                          const SizedBox(height: 16),

                          _buildLabel('Last Seen Location *'),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: _buildTextField(
                                  controller: _lastSeenController,
                                  hint: 'Enter location details',
                                  icon: Icons.location_on_outlined),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap:
                              _fetchingLocation ? null : _getLocation,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: _fetchingLocation
                                    ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFEF4444)))
                                    : const Icon(Icons.my_location_rounded,
                                    color: Color(0xFFEF4444)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          _buildLabel('Reporter Contact Number *'),
                          const SizedBox(height: 8),
                          _buildTextField(
                              controller: _contactController,
                              hint: 'Your phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),

                          _buildLabel('Additional Details (Optional)'),
                          const SizedBox(height: 8),
                          _buildTextField(
                              controller: _descriptionController,
                              hint: 'Clothing, physical features, etc.',
                              icon: Icons.description_outlined,
                              maxLines: 4),
                          const SizedBox(height: 24),

                          // Notice
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B)
                                      .withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_rounded,
                                    color: Color(0xFFF59E0B), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Photo will be uploaded to Cloudinary. The alert and photo URL will be saved in Firestore and all registered volunteers will be notified instantly.',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: const Color(0xFF92400E),
                                        height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(colors: [
                                Color(0xFFEF4444),
                                Color(0xFFDC2626)
                              ]),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444)
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSubmitting
                                    ? null
                                    : _submitReport,
                                borderRadius: BorderRadius.circular(18),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    if (_isSubmitting)
                                      const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5),
                                      )
                                    else ...[
                                      const Icon(Icons.send_rounded,
                                          color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                          _uploadingPhoto
                                              ? 'Uploading to Cloudinary...'
                                              : 'Submit Report to Database',
                                          style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone_rounded,
                                  color: Color(0xFF2563EB), size: 20),
                              label: Text('Call Emergency Helpline: 1122',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB))),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A)));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
            fontSize: 15, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: 15, color: const Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFFEF4444)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 20, vertical: maxLines > 1 ? 18 : 18),
        ),
      ),
    );
  }
}