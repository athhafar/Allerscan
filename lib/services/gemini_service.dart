import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';

class GeminiAnalysisResult {
  final String? productName;
  final List<String> cleanedIngredients;
  final List<String> traceWarnings;
  final List<String> flaggedIngredients;
  final String aiSummary;
  final RiskLevel? riskLevel;

  GeminiAnalysisResult({
    this.productName,
    required this.cleanedIngredients,
    required this.traceWarnings,
    required this.flaggedIngredients,
    required this.aiSummary,
    this.riskLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'cleanedIngredients': cleanedIngredients,
      'traceWarnings': traceWarnings,
      'flaggedIngredients': flaggedIngredients,
      'aiSummary': aiSummary,
      'riskLevel': riskLevel?.name,
    };
  }

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    RiskLevel? parsedRisk;
    final r = json['risk_level'] as String? ?? json['riskLevel'] as String?;
    if (r != null) {
      if (r.toLowerCase().contains('tinggi')) {
        parsedRisk = RiskLevel.tinggi;
      } else if (r.toLowerCase().contains('sedang')) {
        parsedRisk = RiskLevel.sedang;
      } else {
        parsedRisk = RiskLevel.aman;
      }
    }

    return GeminiAnalysisResult(
      productName: json['product_name'] as String? ?? json['productName'] as String?,
      cleanedIngredients: (json['cleaned_ingredients'] as List<dynamic>? ??
              json['cleanedIngredients'] as List<dynamic>? ??
              [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      traceWarnings: (json['trace_warnings'] as List<dynamic>? ??
              json['traceWarnings'] as List<dynamic>? ??
              [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      flaggedIngredients: (json['flagged_ingredients'] as List<dynamic>? ??
              json['flaggedIngredients'] as List<dynamic>? ??
              [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      aiSummary: json['ai_summary'] as String? ?? json['aiSummary'] as String? ?? '',
      riskLevel: parsedRisk,
    );
  }
}

class GeminiService {
  static const String _envKey = String.fromEnvironment('GEMINI_API_KEY');
  static String? _overrideApiKey;

  /// Default API key yang telah dikonfigurasi
  static String get apiKey {
    if (_overrideApiKey != null && _overrideApiKey!.isNotEmpty) {
      return _overrideApiKey!;
    }
    if (_envKey.isNotEmpty) {
      return _envKey;
    }
    try {
      return utf8.decode(base64.decode(
        'QVEuQWI4Uk42S08xRWU2SksxZUZTYWV6bTBOVmxmdkFtNV8tb1VsbEVsX1BaMnR3dW5xMEE=',
      ));
    } catch (_) {
      return '';
    }
  }

  static set apiKey(String value) {
    _overrideApiKey = value;
  }

  /// Daftar model Gemini sesuai prioritas (terbaru & tercepat)
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-flash-latest',
    'gemini-2.5-flash',
  ];

  /// Analisis komposisi menggunakan Google Gemini AI
  static Future<GeminiAnalysisResult?> analyze({
    required String rawText,
    required List<String> activeAllergenLabels,
    String? productName,
    File? imageFile,
  }) async {
    final cleanKey = apiKey.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '').trim();
    if (cleanKey.isEmpty) {
      debugPrint('[GeminiService] API key kosong.');
      return null;
    }

    final prompt = _buildPrompt(
      rawText: rawText,
      activeAllergenLabels: activeAllergenLabels,
      productName: productName,
      hasImage: imageFile != null && rawText.trim().isEmpty,
    );

    // Coba model satu per satu sesuai prioritas
    for (final model in _models) {
      try {
        final result = await _callGeminiApi(
          model: model,
          apiKey: cleanKey,
          prompt: prompt,
          imageFile: (rawText.trim().isEmpty && imageFile != null) ? imageFile : null,
        );

        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('[GeminiService] Model $model gagal: $e. Mencoba fallback...');
      }
    }

    return null;
  }

  static String _buildPrompt({
    required String rawText,
    required List<String> activeAllergenLabels,
    String? productName,
    bool hasImage = false,
  }) {
    final allergenListStr = activeAllergenLabels.isNotEmpty
        ? activeAllergenLabels.join(', ')
        : 'Tidak ada (pantau alergen umum makanan)';

    return '''
Kamu adalah asisten medis & ahli gizi pendeteksi alergen pada produk makanan untuk aplikasi AllerScan.

Tugas kamu:
1. Bersihkan teks OCR kemasan dari kesalahan baca (typo), abaikan informasi non-bahan seperti BPOM, berat bersih, barcode, atau tabel angka nilai gizi.
2. Ekstrak nama produk yang sebenarnya jika disebutkan dalam teks (misal: "Oreo Vanilla", "Indomie Goreng").
3. Ekstrak daftar komposisi menjadi butir-butir bahan bersih (cleaned_ingredients).
4. Ekstrak peringatan jejak produksi / fasilitas / potensi kontaminasi silang (trace_warnings), misal "Diproduksi di fasilitas yang memproses kacang".
5. Bandingkan dengan Profil Alergen Pengguna saat ini: [$allergenListStr].
6. Tentukan flagged_ingredients (bahan dari komposisi utama yang memicu alergen pengguna).
7. Tentukan level risiko (tinggi: jika ada alergen di bahan utama; sedang: jika hanya ada di peringatan jejak/fasilitas atau ada bahan ambigu; aman: jika bersih).
8. Buat ai_summary (1-2 kalimat ramah, jelas, dan edukatif dalam bahasa Indonesia yang menerangkan status produk ini untuk pengguna alergi).

${hasImage ? 'Silakan baca teks komposisi dari gambar kemasan terlampir.' : 'Teks OCR dari kemasan:\n"""\n$rawText\n"""'}
${productName != null && productName.isNotEmpty && productName != 'Produk tanpa nama' ? 'Nama produk awal: "$productName"' : ''}

Balas HANYA dengan format JSON valid sesuai skema berikut tanpa tanda petik markdown:
{
  "product_name": "Nama produk",
  "cleaned_ingredients": ["Bahan 1", "Bahan 2", "Bahan 3"],
  "trace_warnings": ["Jejak alergen 1", "Jejak alergen 2"],
  "flagged_ingredients": ["Bahan yang memicu alergen pengguna"],
  "risk_level": "tinggi" | "sedang" | "aman",
  "ai_summary": "Penjelasan ramah tentang keamanan produk bagi pengguna."
}
''';
  }

  static Future<GeminiAnalysisResult?> _callGeminiApi({
    required String model,
    required String apiKey,
    required String prompt,
    File? imageFile,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    final List<Map<String, dynamic>> parts = [];

    // Jika gambar disertakan (multimodal)
    if (imageFile != null && await imageFile.exists()) {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Image,
        }
      });
    }

    parts.add({'text': prompt});

    final body = json.encode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      }
    });

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final partsList = content['parts'] as List<dynamic>?;
        if (partsList != null && partsList.isNotEmpty) {
          final text = partsList[0]['text'] as String?;
          if (text != null) {
            // Bersihkan jika ada format ```json
            String cleanJson = text.trim();
            if (cleanJson.startsWith('```json')) {
              cleanJson = cleanJson.substring(7);
            }
            if (cleanJson.startsWith('```')) {
              cleanJson = cleanJson.substring(3);
            }
            if (cleanJson.endsWith('```')) {
              cleanJson = cleanJson.substring(0, cleanJson.length - 3);
            }
            cleanJson = cleanJson.trim();

            final parsedMap = json.decode(cleanJson) as Map<String, dynamic>;
            return GeminiAnalysisResult.fromJson(parsedMap);
          }
        }
      }
    } else {
      debugPrint('[GeminiService] HTTP ${response.statusCode}: ${response.body}');
    }

    return null;
  }
}

