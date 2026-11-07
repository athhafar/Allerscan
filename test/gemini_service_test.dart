import 'package:flutter_test/flutter_test.dart';
import 'package:allerscan/models/scan_result.dart';
import 'package:allerscan/services/gemini_service.dart';

void main() {
  group('GeminiAnalysisResult Tests', () {
    test('Correctly parses JSON response from Gemini', () {
      final jsonMap = {
        'product_name': 'Oreo Krim Cokelat',
        'cleaned_ingredients': [
          'Tepung terigu',
          'Gula',
          'Minyak nabati',
          'Kakao bubuk',
          'Lesitin kedelai'
        ],
        'trace_warnings': ['Susu', 'Kacang tanah'],
        'flagged_ingredients': ['Lesitin kedelai'],
        'risk_level': 'sedang',
        'ai_summary':
            'Produk ini mengandung lesitin kedelai dan diproduksi di pabrik dengan jejak kacang.',
      };

      final result = GeminiAnalysisResult.fromJson(jsonMap);

      expect(result.productName, equals('Oreo Krim Cokelat'));
      expect(result.cleanedIngredients.length, equals(5));
      expect(result.traceWarnings, contains('Susu'));
      expect(result.traceWarnings, contains('Kacang tanah'));
      expect(result.flaggedIngredients, contains('Lesitin kedelai'));
      expect(result.riskLevel, equals(RiskLevel.sedang));
      expect(result.aiSummary, contains('kedelai'));
    });

    test('Handles fallback and missing values safely', () {
      final emptyMap = <String, dynamic>{};
      final result = GeminiAnalysisResult.fromJson(emptyMap);

      expect(result.productName, isNull);
      expect(result.cleanedIngredients, isEmpty);
      expect(result.traceWarnings, isEmpty);
      expect(result.flaggedIngredients, isEmpty);
      expect(result.riskLevel, isNull);
      expect(result.aiSummary, equals(''));
    });
  });
}

