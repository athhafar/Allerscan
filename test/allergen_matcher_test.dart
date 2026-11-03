import 'package:flutter_test/flutter_test.dart';
import '../lib/models/allergen_profile.dart';
import '../lib/models/scan_result.dart';
import '../lib/services/allergen_matcher.dart';

void main() {
  group('AllergenMatcher Core Tests', () {
    late AllergenDef peanut;
    late AllergenDef milk;
    late AllergenDef shrimp;

    setUp(() {
      peanut = AllergenDef(
        id: 'kacang_tanah',
        label: 'Kacang Tanah',
        keywords: [
          'kacang tanah',
          'peanut',
          'peanuts',
          'arachis',
          'groundnut',
          'pasta kacang tanah',
          'minyak kacang tanah',
        ],
        ambiguous: ['kacang'],
      );

      milk = AllergenDef(
        id: 'susu',
        label: 'Susu',
        keywords: [
          'susu',
          'milk',
          'whey',
          'kasein',
          'casein',
          'laktosa',
          'lactose',
          'krim',
          'cream',
          'mentega',
          'butter',
          'keju',
          'cheese',
          'yogurt',
          'yoghurt',
          'susu bubuk',
          'susu skim',
          'susu bubuk skim',
        ],
        ambiguous: [],
      );

      shrimp = AllergenDef(
        id: 'udang',
        label: 'Udang',
        keywords: [
          'udang',
          'shrimp',
          'prawn',
          'krustasea',
          'crustacean',
          'terasi',
          'kepiting',
          'crab',
          'lobster',
        ],
        ambiguous: ['seafood'],
      );
    });

    test('Case 1: "tepung terigu, gula, susu bubuk skim (2%), pasta kacang tanah" with [susu, kacang_tanah] -> TINGGI, 2 temuan', () {
      final text = 'tepung terigu, gula, susu bubuk skim (2%), pasta kacang tanah';
      final result = AllergenMatcher.analyze(text, [milk, peanut]);

      expect(result.riskLevel, equals(RiskLevel.tinggi));
      expect(result.findings.length, equals(2));
      expect(result.findings.any((f) => f.allergenId == 'susu'), isTrue);
      expect(result.findings.any((f) => f.allergenId == 'kacang_tanah'), isTrue);
    });

    test('Case 2: "air, kacang almond, garam" with [kacang_tanah] -> AMAN', () {
      final text = 'air, kacang almond, garam';
      final result = AllergenMatcher.analyze(text, [peanut]);

      expect(result.riskLevel, equals(RiskLevel.aman));
      expect(result.findings.isEmpty, isTrue);
    });

    test('Case 3: "air, gula. Diproduksi pada peralatan yang juga memproses kacang tanah dan udang" with [kacang_tanah, udang] -> SEDANG', () {
      final text = 'air, gula. Diproduksi pada peralatan yang juga memproses kacang tanah dan udang';
      final result = AllergenMatcher.analyze(text, [peanut, shrimp]);

      expect(result.riskLevel, equals(RiskLevel.sedang));
      expect(result.findings.length, equals(2));
      expect(result.findings.every((f) => f.location == 'trace'), isTrue);
    });

    test('Case 4: Empty text -> AMAN with isTextTooShort = true', () {
      final text = '';
      final result = AllergenMatcher.analyze(text, [milk]);

      expect(result.riskLevel, equals(RiskLevel.aman));
      expect(result.isTextTooShort, isTrue);
    });

    test('Case 5: OCR misread "kaseln" with [susu] -> TINGGI (Levenshtein distance 1 to kasein)', () {
      final text = 'gula, minyak nabati, kaseln, garam';
      final result = AllergenMatcher.analyze(text, [milk]);

      expect(result.riskLevel, equals(RiskLevel.tinggi));
      expect(result.findings.any((f) => f.allergenId == 'susu'), isTrue);
      expect(result.findings.first.matchedWord, equals('kaseln'));
    });

    test('Case 6: "kacang, garam" with [kacang_tanah] -> SEDANG (ambiguous keyword)', () {
      final text = 'kacang, garam';
      final result = AllergenMatcher.analyze(text, [peanut]);

      expect(result.riskLevel, equals(RiskLevel.sedang));
      expect(result.findings.length, equals(1));
      expect(result.findings.first.location, equals('ambiguous'));
    });
  });
}
