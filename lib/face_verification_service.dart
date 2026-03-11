// lib/services/face_verification_service.dart
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FaceVerificationService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.1,
    ),
  );

  /// Downloads image from [url] to a temp file, returns the file.
  static Future<File> _downloadToTemp(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download image from $url');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/face_verify_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Detects faces in [imageFile] and returns list of detected faces.
  static Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return await _detector.processImage(inputImage);
  }

  /// Extracts a simple landmark-based feature vector from a [Face].
  /// Returns null if not enough landmarks are available.
  static List<double>? _extractFeatures(Face face) {
    final landmarks = face.landmarks;

    final leftEye = landmarks[FaceLandmarkType.leftEye];
    final rightEye = landmarks[FaceLandmarkType.rightEye];
    final nose = landmarks[FaceLandmarkType.noseBase];
    final leftMouth = landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = landmarks[FaceLandmarkType.rightMouth];
    final leftEar = landmarks[FaceLandmarkType.leftEar];
    final rightEar = landmarks[FaceLandmarkType.rightEar];

    if (leftEye == null ||
        rightEye == null ||
        nose == null ||
        leftMouth == null ||
        rightMouth == null) {
      return null;
    }

    // Normalize by inter-eye distance so features are scale-invariant
    final eyeDist = _dist(leftEye.position, rightEye.position);
    if (eyeDist < 1) return null;

    // Build normalized feature vector
    final cx = (leftEye.position.x + rightEye.position.x) / 2;
    final cy = (leftEye.position.y + rightEye.position.y) / 2;

    List<double> feat = [];

    void addNorm(Point<int> p) {
      feat.add((p.x - cx) / eyeDist);
      feat.add((p.y - cy) / eyeDist);
    }

    addNorm(leftEye.position);
    addNorm(rightEye.position);
    addNorm(nose.position);
    addNorm(leftMouth.position);
    addNorm(rightMouth.position);
    if (leftEar != null) addNorm(leftEar.position);
    if (rightEar != null) addNorm(rightEar.position);

    // Also include head angles as features
    feat.add((face.headEulerAngleX ?? 0) / 90.0);
    feat.add((face.headEulerAngleY ?? 0) / 90.0);
    feat.add((face.headEulerAngleZ ?? 0) / 90.0);

    return feat;
  }

  static double _dist(Point<int> a, Point<int> b) {
    final dx = (a.x - b.x).toDouble();
    final dy = (a.y - b.y).toDouble();
    return sqrt(dx * dx + dy * dy);
  }

  /// Cosine similarity between two vectors.
  static double _cosineSimilarity(List<double> a, List<double> b) {
    final len = min(a.length, b.length);
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < len; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Main verification method.
  ///
  /// [originalImageUrl] — Cloudinary URL of the child's original photo.
  /// [newImageFile]     — Photo just taken by the reporter.
  ///
  /// Returns a [FaceVerificationResult].
  static Future<FaceVerificationResult> verify({
    required String originalImageUrl,
    required File newImageFile,
  }) async {
    File? tempOriginal;
    try {
      // 1. Download original image
      tempOriginal = await _downloadToTemp(originalImageUrl);

      // 2. Detect faces in both images
      final originalFaces = await detectFaces(tempOriginal);
      final newFaces = await detectFaces(newImageFile);

      if (originalFaces.isEmpty) {
        return FaceVerificationResult(
          status: VerificationStatus.noFaceInOriginal,
          similarity: 0,
          message:
          'No face detected in the original child photo. Verification skipped.',
        );
      }

      if (newFaces.isEmpty) {
        return FaceVerificationResult(
          status: VerificationStatus.noFaceInNew,
          similarity: 0,
          message:
          'No face detected in the photo you took. Please retake with the face clearly visible.',
        );
      }

      // 3. Use the largest face from each image
      final origFace = _largestFace(originalFaces);
      final newFace = _largestFace(newFaces);

      // 4. Extract feature vectors
      final origFeats = _extractFeatures(origFace);
      final newFeats = _extractFeatures(newFace);

      if (origFeats == null || newFeats == null) {
        return FaceVerificationResult(
          status: VerificationStatus.insufficientLandmarks,
          similarity: 0,
          message:
          'Could not extract enough facial landmarks. Please ensure the face is well-lit and fully visible.',
        );
      }

      // 5. Compare
      final similarity = _cosineSimilarity(origFeats, newFeats);
      // Also compare bounding-box aspect ratios as a sanity check
      final origAR = origFace.boundingBox.width / origFace.boundingBox.height;
      final newAR = newFace.boundingBox.width / newFace.boundingBox.height;
      final arDiff = (origAR - newAR).abs();

      // Threshold: cosine similarity > 0.82 = likely same person
      // Slightly relaxed if aspect ratios are very close
      final threshold = arDiff < 0.15 ? 0.80 : 0.84;
      final isMatch = similarity >= threshold;

      final percent = (similarity * 100).toStringAsFixed(1);

      return FaceVerificationResult(
        status:
        isMatch ? VerificationStatus.match : VerificationStatus.noMatch,
        similarity: similarity,
        message: isMatch
            ? 'Face matched! ($percent% similarity) — Likely the same child.'
            : 'Face did NOT match ($percent% similarity). This may not be the same child.',
      );
    } finally {
      // Clean up temp file
      try {
        await tempOriginal?.delete();
      } catch (_) {}
    }
  }

  static Face _largestFace(List<Face> faces) {
    return faces.reduce((a, b) =>
    a.boundingBox.width * a.boundingBox.height >
        b.boundingBox.width * b.boundingBox.height
        ? a
        : b);
  }

  static void dispose() {
    _detector.close();
  }
}

// ─── RESULT MODEL ─────────────────────────────────────────────────────────────
enum VerificationStatus {
  match,
  noMatch,
  noFaceInOriginal,
  noFaceInNew,
  insufficientLandmarks,
}

class FaceVerificationResult {
  final VerificationStatus status;
  final double similarity;
  final String message;

  const FaceVerificationResult({
    required this.status,
    required this.similarity,
    required this.message,
  });

  bool get isMatch => status == VerificationStatus.match;

  /// True when verification could not run (not a definitive non-match)
  bool get isInconclusive =>
      status == VerificationStatus.noFaceInOriginal ||
          status == VerificationStatus.insufficientLandmarks;

  String get emoji {
    switch (status) {
      case VerificationStatus.match:
        return '✅';
      case VerificationStatus.noMatch:
        return '❌';
      case VerificationStatus.noFaceInOriginal:
        return '⚠️';
      case VerificationStatus.noFaceInNew:
        return '📷';
      case VerificationStatus.insufficientLandmarks:
        return '⚠️';
    }
  }
}