// lib/widgets/face_verification_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../shared.dart';
import 'face_verification_service.dart';

/// A bottom sheet that:
/// 1. Asks the user to take / pick a photo of the child they see.
/// 2. Runs ML Kit face comparison against [originalPhotoUrl].
/// 3. Calls [onVerified] with the taken photo file when done
///    (either matched, inconclusive, or user chooses to proceed anyway).
/// 4. Calls [onCancelled] if the user bails out.
class FaceVerificationSheet extends StatefulWidget {
  final String? originalPhotoUrl;
  final String childName;
  final String actionLabel; // e.g. "Submit Sighting" / "Mark as Found"
  final ValueChanged<File> onVerified;
  final VoidCallback onCancelled;

  const FaceVerificationSheet({
    super.key,
    required this.originalPhotoUrl,
    required this.childName,
    required this.actionLabel,
    required this.onVerified,
    required this.onCancelled,
  });

  /// Convenience: show as a modal bottom sheet.
  static Future<void> show(
      BuildContext context, {
        required String? originalPhotoUrl,
        required String childName,
        required String actionLabel,
        required ValueChanged<File> onVerified,
        required VoidCallback onCancelled,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => FaceVerificationSheet(
        originalPhotoUrl: originalPhotoUrl,
        childName: childName,
        actionLabel: actionLabel,
        onVerified: onVerified,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<FaceVerificationSheet> createState() => _FaceVerificationSheetState();
}

class _FaceVerificationSheetState extends State<FaceVerificationSheet> {
  final _picker = ImagePicker();

  File? _capturedPhoto;
  FaceVerificationResult? _result;
  bool _isVerifying = false;
  _SheetStep _step = _SheetStep.capture;

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (xfile == null) return;

      final file = File(xfile.path);
      setState(() {
        _capturedPhoto = file;
        _result = null;
        _step = _SheetStep.preview;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Camera error: $e'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _runVerification() async {
    if (_capturedPhoto == null) return;

    setState(() {
      _isVerifying = true;
      _step = _SheetStep.verifying;
    });

    try {
      FaceVerificationResult result;

      if (widget.originalPhotoUrl == null ||
          widget.originalPhotoUrl!.isEmpty) {
        // No original photo — skip verification, proceed directly
        result = FaceVerificationResult(
          status: VerificationStatus.noFaceInOriginal,
          similarity: 0,
          message:
          'No original photo on file. Proceeding without face verification.',
        );
      } else {
        result = await FaceVerificationService.verify(
          originalImageUrl: widget.originalPhotoUrl!,
          newImageFile: _capturedPhoto!,
        );
      }

      setState(() {
        _result = result;
        _step = _SheetStep.result;
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _result = FaceVerificationResult(
          status: VerificationStatus.insufficientLandmarks,
          similarity: 0,
          message: 'Verification error: $e',
        );
        _step = _SheetStep.result;
        _isVerifying = false;
      });
    }
  }

  void _proceed() {
    Navigator.pop(context);
    widget.onVerified(_capturedPhoto!);
  }

  void _retake() {
    setState(() {
      _capturedPhoto = null;
      _result = null;
      _step = _SheetStep.capture;
    });
  }

  void _cancel() {
    Navigator.pop(context);
    widget.onCancelled();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title row
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.face_retouching_natural_rounded,
                  color: AppTheme.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Face Verification',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('Confirm this is ${widget.childName}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textLight)),
                ],
              ),
            ),
            IconButton(
              onPressed: _cancel,
              icon: const Icon(Icons.close_rounded, color: AppTheme.textLight),
            ),
          ]),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _SheetStep.capture:
        return _CaptureStep(
          childName: widget.childName,
          originalPhotoUrl: widget.originalPhotoUrl,
          onCamera: () => _capturePhoto(ImageSource.camera),
          onGallery: () => _capturePhoto(ImageSource.gallery),
          onSkip: _cancel,
        );

      case _SheetStep.preview:
        return _PreviewStep(
          photo: _capturedPhoto!,
          onVerify: _runVerification,
          onRetake: _retake,
        );

      case _SheetStep.verifying:
        return const _VerifyingStep();

      case _SheetStep.result:
        return _ResultStep(
          result: _result!,
          photo: _capturedPhoto!,
          actionLabel: widget.actionLabel,
          onProceed: _proceed,
          onRetake: _retake,
          onCancel: _cancel,
        );
    }
  }
}

enum _SheetStep { capture, preview, verifying, result }

// ─── STEP: CAPTURE ────────────────────────────────────────────────────────────
class _CaptureStep extends StatelessWidget {
  final String childName;
  final String? originalPhotoUrl;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onSkip;

  const _CaptureStep({
    required this.childName,
    required this.originalPhotoUrl,
    required this.onCamera,
    required this.onGallery,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('capture'),
      children: [
        // Original photo preview
        if (originalPhotoUrl != null && originalPhotoUrl!.isNotEmpty) ...[
          Row(
            children: [
              Text('Original photo of $childName:',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                originalPhotoUrl!,
                height: 140,
                width: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  width: 140,
                  color: AppTheme.bg,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppTheme.textLight, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Instruction banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
          ),
          child: Row(children: [
            const Icon(Icons.info_rounded,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Take or upload a clear photo of the child you see. ML Kit will compare faces.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textDark),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Camera button
        _ActionButton(
          icon: Icons.camera_alt_rounded,
          label: 'Take Photo Now',
          subtitle: 'Recommended — best accuracy',
          color: AppTheme.primary,
          onTap: onCamera,
        ),
        const SizedBox(height: 10),

        // Gallery button
        _ActionButton(
          icon: Icons.photo_library_rounded,
          label: 'Choose from Gallery',
          subtitle: 'Select an existing photo',
          color: AppTheme.accent,
          onTap: onGallery,
        ),

        const SizedBox(height: 16),

        TextButton(
          onPressed: onSkip,
          child: Text('Cancel',
              style: GoogleFonts.poppins(
                  color: AppTheme.textLight, fontSize: 14)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── STEP: PREVIEW ────────────────────────────────────────────────────────────
class _PreviewStep extends StatelessWidget {
  final File photo;
  final VoidCallback onVerify;
  final VoidCallback onRetake;

  const _PreviewStep({
    required this.photo,
    required this.onVerify,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('preview'),
      children: [
        Text('Review your photo',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(photo,
                height: 200, width: 200, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text('Make sure the face is clearly visible.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppTheme.textLight)),
        const SizedBox(height: 20),
        _GradientBtn(
          label: 'Run Face Verification',
          icon: Icons.face_retouching_natural_rounded,
          colors: [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
          onTap: onVerify,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.replay_rounded),
          label: Text('Retake', style: GoogleFonts.poppins()),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── STEP: VERIFYING ─────────────────────────────────────────────────────────
class _VerifyingStep extends StatelessWidget {
  const _VerifyingStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('verifying'),
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: AppTheme.primary),
        const SizedBox(height: 20),
        Text('Analyzing facial features...',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Text('ML Kit is comparing landmarks',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textLight)),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── STEP: RESULT ─────────────────────────────────────────────────────────────
class _ResultStep extends StatelessWidget {
  final FaceVerificationResult result;
  final File photo;
  final String actionLabel;
  final VoidCallback onProceed;
  final VoidCallback onRetake;
  final VoidCallback onCancel;

  const _ResultStep({
    required this.result,
    required this.photo,
    required this.actionLabel,
    required this.onProceed,
    required this.onRetake,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = result.isMatch
        ? AppTheme.success
        : result.isInconclusive
        ? AppTheme.warning
        : AppTheme.danger;

    final String statusTitle = result.isMatch
        ? 'Face Match Confirmed!'
        : result.isInconclusive
        ? 'Verification Incomplete'
        : 'Face Did Not Match';

    final percent = (result.similarity * 100).toStringAsFixed(1);

    return Column(
      key: const ValueKey('result'),
      children: [
        // Result banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(result.emoji,
                style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(statusTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: statusColor)),
            const SizedBox(height: 6),
            Text(result.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textMid)),
            if (result.similarity > 0) ...[
              const SizedBox(height: 12),
              _SimilarityBar(similarity: result.similarity, color: statusColor),
              const SizedBox(height: 6),
              Text('$percent% similarity score',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ],
          ]),
        ),

        const SizedBox(height: 20),

        // Captured photo thumb
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(photo,
                  height: 80, width: 80, fit: BoxFit.cover),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Actions
        if (result.isMatch) ...[
          _GradientBtn(
            label: actionLabel,
            icon: Icons.check_circle_rounded,
            colors: [AppTheme.success, const Color(0xFF059669)],
            onTap: onProceed,
          ),
        ] else if (result.isInconclusive) ...[
          _GradientBtn(
            label: 'Proceed Anyway',
            icon: Icons.arrow_forward_rounded,
            colors: [AppTheme.warning, const Color(0xFFD97706)],
            onTap: onProceed,
          ),
        ] else ...[
          // No match — warn but allow proceeding
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_rounded,
                  color: AppTheme.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This may not be the same child. Please verify carefully before proceeding.',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.danger),
                ),
              ),
            ]),
          ),
          _GradientBtn(
            label: 'Proceed Anyway',
            icon: Icons.warning_rounded,
            colors: [AppTheme.danger, const Color(0xFFDC2626)],
            onTap: onProceed,
          ),
        ],

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.replay_rounded),
          label: Text('Retake Photo', style: GoogleFonts.poppins()),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: onCancel,
          child: Text('Cancel',
              style: GoogleFonts.poppins(
                  color: AppTheme.textLight, fontSize: 14)),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── SIMILARITY BAR ───────────────────────────────────────────────────────────
class _SimilarityBar extends StatelessWidget {
  final double similarity;
  final Color color;

  const _SimilarityBar({required this.similarity, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: similarity.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textLight)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color, size: 16),
          ]),
        ),
      ),
    );
  }
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GradientBtn({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}