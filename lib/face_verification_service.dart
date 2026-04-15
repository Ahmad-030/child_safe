// lib/services/face_verification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Replace with your actual Gemini API key (store securely, e.g. via --dart-define).
const String _kGeminiApiKey = ;

/// Gemini model used for vision tasks.
const String _kGeminiModel = 'gemini-flash-latest';

const String _kGeminiEndpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/$_kGeminiModel:generateContent';
class FaceVerificationService {
  // ─── Public API ─────────────────────────────────────────────────────────────

  static Future<FaceVerificationResult> verify({
    required String originalImageUrl,
    required File newImageFile,
  }) async {
    File? tempOriginal;
    try {
      tempOriginal = await _downloadToTemp(originalImageUrl);

      final originalBytes = await tempOriginal.readAsBytes();
      final newBytes = await newImageFile.readAsBytes();

      return await _callGemini(
        originalB64: base64Encode(originalBytes),
        newB64: base64Encode(newBytes),
      );
    } on SocketException catch (e) {
      return FaceVerificationResult(
        status: VerificationStatus.error,
        similarity: 0,
        confidence: ConfidenceLevel.low,
        message: 'Network error: ${e.message}',
        rawAnalysis: null,
      );
    } catch (e) {
      return FaceVerificationResult(
        status: VerificationStatus.error,
        similarity: 0,
        confidence: ConfidenceLevel.low,
        message: 'Verification failed: $e',
        rawAnalysis: null,
      );
    } finally {
      try {
        await tempOriginal?.delete();
      } catch (_) {}
    }
  }

  // ─── Gemini call ─────────────────────────────────────────────────────────────

  static Future<FaceVerificationResult> _callGemini({
    required String originalB64,
    required String newB64,
  }) async {
    const prompt = '''
Compare the two faces. Reply ONLY with this JSON (no markdown, no extra text):
{"same_person":true,"similarity_score":0.95,"confidence":"high","no_face_in_image1":false,"no_face_in_image2":false,"reasoning":"Faces match."}

Fields:
- same_person: true/false/null
- similarity_score: number 0.0 to 1.0 (always include decimal, e.g. 1.0 not 1.)
- confidence: "high" or "medium" or "low"
- no_face_in_image1: true/false
- no_face_in_image2: true/false
- reasoning: one short sentence, no special characters
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': originalB64}
            },
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': newB64}
            },
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'topP': 1,
        'topK': 1,
        'maxOutputTokens': 1000,
        'responseMimeType': 'application/json',
      },
      // FIX 2: Relax safety thresholds so face photos aren't blocked.
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    });

    final response = await http.post(
      Uri.parse(_kGeminiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _kGeminiApiKey,
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return FaceVerificationResult(
        status: VerificationStatus.error,
        similarity: 0,
        confidence: ConfidenceLevel.low,
        message:
        'Face API API error ${response.statusCode}: ${response.body}',
        rawAnalysis: response.body,
      );
    }

    return _parseGeminiResponse(response.body);
  }

  // ─── Response parser ─────────────────────────────────────────────────────────

  static FaceVerificationResult _parseGeminiResponse(String responseBody) {
    // FIX 4: Log raw response during development to diagnose issues.
    // ignore: avoid_print
    assert(() {
      // ignore: avoid_print
      print('=== RAW Face API RESPONSE ===\n$responseBody\n===========================');
      return true;
    }());

    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return _errorResult('Face API returned no candidates.', responseBody);
      }

      // FIX 1a: Check finishReason before attempting to parse content.
      final finishReason =
      candidates[0]['finishReason'] as String?;
      if (finishReason != null && finishReason != 'STOP') {
        return _errorResult(
          'Face API blocked response (reason: $finishReason). '
              'Ensure the face is well-lit, clearly visible, and try again.',
          responseBody,
        );
      }

      final content =
      candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        return _errorResult('Face API returned empty content.', responseBody);
      }

      String rawText = (parts[0]['text'] as String? ?? '').trim();

      // FIX 1b: Guard against blank text before attempting JSON parse.
      if (rawText.isEmpty) {
        return _errorResult(
          'Face API returned an empty response. Please retake the photo '
              'ensuring the face is clearly visible.',
          responseBody,
        );
      }

      // ── Robust JSON extraction + repair ──────────────────────────────────
      rawText = _extractAndRepairJson(rawText);

      // FIX 1c: Guard against still-empty text after repair attempt.
      if (rawText.isEmpty) {
        return _errorResult(
          'Could not extract JSON from Face API response.',
          responseBody,
        );
      }

      final Map<String, dynamic> parsed = jsonDecode(rawText);

      final bool noFaceInImage1 = parsed['no_face_in_image1'] == true;
      final bool noFaceInImage2 = parsed['no_face_in_image2'] == true;
      final dynamic samePerson = parsed['same_person'];
      final double similarity = _parseDouble(parsed['similarity_score']);
      final String confidenceStr =
          (parsed['confidence'] as String?)?.toLowerCase() ?? 'low';
      final String reasoning =
          parsed['reasoning'] as String? ?? 'No reasoning provided.';
      final confidence = _parseConfidence(confidenceStr);

      if (noFaceInImage1) {
        return FaceVerificationResult(
          status: VerificationStatus.noFaceInOriginal,
          similarity: 0,
          confidence: confidence,
          message:
          'No face detected in the original photo. Verification skipped.',
          rawAnalysis: rawText,
        );
      }
      if (noFaceInImage2) {
        return FaceVerificationResult(
          status: VerificationStatus.noFaceInNew,
          similarity: 0,
          confidence: confidence,
          message:
          'No face detected in your photo. Please retake clearly.',
          rawAnalysis: rawText,
        );
      }
      if (samePerson == null) {
        return FaceVerificationResult(
          status: VerificationStatus.inconclusive,
          similarity: similarity,
          confidence: confidence,
          message: 'Could not determine: $reasoning',
          rawAnalysis: rawText,
        );
      }

      final bool isMatch = samePerson == true;
      final String percent = (similarity * 100).toStringAsFixed(1);

      return FaceVerificationResult(
        status:
        isMatch ? VerificationStatus.match : VerificationStatus.noMatch,
        similarity: similarity,
        confidence: confidence,
        message: isMatch
            ? 'Face matched! ($percent% similarity) — $reasoning'
            : 'Face did NOT match ($percent% similarity). $reasoning',
        rawAnalysis: rawText,
      );
    } catch (e) {
      return _errorResult('Failed to parse Face API response: $e', responseBody);
    }
  }

  // ─── JSON repair helpers ──────────────────────────────────────────────────

  static String _extractAndRepairJson(String raw) {
    // 1. Strip markdown fences
    raw = raw
        .replaceAll(RegExp(r'```json', multiLine: true), '')
        .replaceAll(RegExp(r'```', multiLine: true), '')
        .trim();

    // 2. Extract only the JSON object
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      raw = raw.substring(start, end + 1);
    } else {
      // No JSON object found at all — return empty so caller can handle it.
      return '';
    }

    // 3. Fix bare numbers like `1.` → `1.0` (invalid JSON)
    raw = raw.replaceAllMapped(
      RegExp(r':\s*(\d+)\.\s*([,}\n\r])'),
          (m) => ': ${m.group(1)}.0${m.group(2)}',
    );

    // 4. Repair truncated JSON (unclosed strings / missing closing brace)
    raw = _repairTruncatedJson(raw);

    return raw;
  }

  static String _repairTruncatedJson(String json) {
    // Already valid — nothing to do
    try {
      jsonDecode(json);
      return json;
    } catch (_) {}

    var repaired = json.trimRight();

    if (!repaired.endsWith('}')) {
      // Odd number of quotes → unclosed string
      final quoteCount = '"'.allMatches(repaired).length;
      if (quoteCount % 2 != 0) repaired += '"';
      repaired += '}';
    }

    try {
      jsonDecode(repaired);
      return repaired;
    } catch (_) {}
    return json; // Give up — caller will surface the parse error
  }

  // ─── Misc helpers ─────────────────────────────────────────────────────────

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static FaceVerificationResult _errorResult(String message, String? raw) {
    return FaceVerificationResult(
      status: VerificationStatus.error,
      similarity: 0,
      confidence: ConfidenceLevel.low,
      message: message,
      rawAnalysis: raw,
    );
  }

  static ConfidenceLevel _parseConfidence(String s) {
    switch (s) {
      case 'high':
        return ConfidenceLevel.high;
      case 'medium':
        return ConfidenceLevel.medium;
      default:
        return ConfidenceLevel.low;
    }
  }

  static Future<File> _downloadToTemp(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to download image (HTTP ${response.statusCode})');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/gemini_verify_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}

// ─── RESULT MODEL ─────────────────────────────────────────────────────────────

enum VerificationStatus {
  match,
  noMatch,
  noFaceInOriginal,
  noFaceInNew,
  inconclusive,
  error,
}

enum ConfidenceLevel { high, medium, low }

class FaceVerificationResult {
  final VerificationStatus status;
  final double similarity;
  final ConfidenceLevel confidence;
  final String message;
  final String? rawAnalysis;

  const FaceVerificationResult({
    required this.status,
    required this.similarity,
    required this.confidence,
    required this.message,
    required this.rawAnalysis,
  });

  bool get isMatch => status == VerificationStatus.match;

  bool get isInconclusive =>
      status == VerificationStatus.noFaceInOriginal ||
          status == VerificationStatus.inconclusive ||
          status == VerificationStatus.error;

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
      case VerificationStatus.inconclusive:
        return '🔍';
      case VerificationStatus.error:
        return '⚠️';
    }
  }

  String get confidenceLabel {
    switch (confidence) {
      case ConfidenceLevel.high:
        return 'High Confidence';
      case ConfidenceLevel.medium:
        return 'Medium Confidence';
      case ConfidenceLevel.low:
        return 'Low Confidence';
    }
  }
}
