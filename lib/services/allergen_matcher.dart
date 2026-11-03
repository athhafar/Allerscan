import 'dart:math';
import '../models/allergen_profile.dart';
import '../models/scan_result.dart';

/// Pure Dart Allergen Matcher Engine
/// Handles OCR text normalization, trace clause splitting, word-boundary keyword search,
/// and Levenshtein fuzzy distance tolerance for long words (length >= 6).
class AllergenMatcher {
  static const List<String> tracePhrases = [
    'mungkin mengandung',
    'may contain',
    'contains traces',
    'contain traces',
    'mengandung jejak',
    'jejak alergen',
    'traces of',
    'diproduksi di fasilitas',
    'diproduksi pada fasilitas',
    'diproduksi di peralatan',
    'diproduksi pada peralatan',
    'diproses di fasilitas',
    'diproses pada fasilitas',
    'diproses di peralatan',
    'diproses pada peralatan',
    'produced in a facility',
    'produced on equipment',
    'processed in a facility',
    'processed on equipment',
    'peralatan yang juga memproses',
    'fasilitas yang juga memproses',
    'fasilitas yang sama dengan',
    'peralatan yang sama dengan',
  ];

  static const List<String> nonPeanutFollowers = [
    'almond',
    'hijau',
    'kedelai',
    'mede',
    'mete',
    'macadamia',
    'pecan',
    'walnut',
    'pistachio',
    'arab',
    'polong',
    'merah',
    'kapri',
    'hazelnut',
    'brazil',
  ];

  /// Calculates Levenshtein edit distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i <= s2.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// 1. Normalizes raw OCR text
  static String normalizeOcrText(String rawText) {
    if (rawText.isEmpty) return '';

    String text = rawText.toLowerCase();

    // OCR character error corrections:
    text = text.replaceAll('|', 'l');

    // 0 inside words -> o
    text = text.replaceAllMapped(RegExp(r'([a-z])0([a-z])'), (m) => '${m[1]}o${m[2]}');
    text = text.replaceAllMapped(RegExp(r'([a-z])0'), (m) => '${m[1]}o');
    text = text.replaceAllMapped(RegExp(r'0([a-z])'), (m) => 'o${m[1]}');

    // 1 inside words -> i
    text = text.replaceAllMapped(RegExp(r'([a-z])1([a-z])'), (m) => '${m[1]}i${m[2]}');

    // Replace newlines and redundant punctuation
    text = text.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    text = text.replaceAll(';', ',');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    return text.trim();
  }

  /// 2. Splits text into main ingredients and trace warning clause
  static Map<String, String> splitTraceClause(String normalizedText) {
    int earliestIndex = -1;

    for (final phrase in tracePhrases) {
      final idx = normalizedText.indexOf(phrase);
      if (idx != -1) {
        if (earliestIndex == -1 || idx < earliestIndex) {
          earliestIndex = idx;
        }
      }
    }

    if (earliestIndex != -1) {
      return {
        'main': normalizedText.substring(0, earliestIndex).trim(),
        'trace': normalizedText.substring(earliestIndex).trim(),
      };
    }

    return {
      'main': normalizedText,
      'trace': '',
    };
  }

  /// Finds keyword in text with word boundaries and fuzzy matching
  static Map<String, dynamic> findMatch(
    String text,
    String keyword, {
    bool isAmbiguous = false,
    String allergenId = '',
  }) {
    if (text.isEmpty || keyword.isEmpty) {
      return {'matched': false, 'word': ''};
    }

    final normText = text.toLowerCase();
    final normKw = keyword.toLowerCase().trim();

    // Special rule for ambiguous "kacang"
    if (allergenId == 'kacang_tanah' && normKw == 'kacang') {
      final kacangRegex = RegExp(r'\bkacang\b', caseSensitive: false);
      final matches = kacangRegex.allMatches(normText);
      for (final match in matches) {
        final matchPos = match.start;
        final endPos = min(matchPos + 30, normText.length);
        final followingSlice = normText.substring(matchPos + 6, endPos).trim();
        final isDisqualified = nonPeanutFollowers.any((np) => followingSlice.startsWith(np));
        if (!isDisqualified) {
          return {'matched': true, 'word': 'kacang'};
        }
      }
      return {'matched': false, 'word': ''};
    }

    // Multi-word phrase matching
    if (normKw.contains(' ')) {
      final escaped = RegExp.escape(normKw);
      final regex = RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)', caseSensitive: false);
      if (regex.hasMatch(normText)) {
        return {'matched': true, 'word': normKw};
      }
      return {'matched': false, 'word': ''};
    }

    // Single-word token matching + fuzzy for len >= 6
    final tokenMatches = RegExp(r'[a-z0-9]+').allMatches(normText);
    for (final tm in tokenMatches) {
      final token = tm.group(0)!;
      if (token == normKw) {
        return {'matched': true, 'word': token};
      }

      // Fuzzy matching: allow Levenshtein distance 1 if keyword >= 6 letters
      if (normKw.length >= 6 && token.length >= 5 && (token.length - normKw.length).abs() <= 1) {
        final dist = levenshteinDistance(token, normKw);
        if (dist == 1) {
          return {'matched': true, 'word': token};
        }
      }
    }

    return {'matched': false, 'word': ''};
  }

  /// Core analyze function:
  /// MatchResult analyze(String ocrText, List<AllergenDef> activeAllergens)
  static ScanResult analyze(
    String ocrText,
    List<AllergenDef> activeAllergens, {
    String productName = 'Produk tanpa nama',
    String? brandOrCategory,
    String? imagePath,
  }) {
    final normalized = normalizeOcrText(ocrText);
    final charCount = normalized.length;
    final isTextTooShort = charCount < 15;

    final clauseMap = splitTraceClause(normalized);
    final mainText = clauseMap['main'] ?? '';
    final traceText = clauseMap['trace'] ?? '';

    final List<AllergenFinding> findings = [];

    for (final allergen in activeAllergens) {
      AllergenFinding? foundInMain;
      AllergenFinding? foundInTrace;
      AllergenFinding? foundAmbiguous;

      // 1. Search keywords in mainText
      for (final kw in allergen.keywords) {
        final res = findMatch(mainText, kw, allergenId: allergen.id);
        if (res['matched'] == true) {
          foundInMain = AllergenFinding(
            allergenId: allergen.id,
            allergenLabel: allergen.label,
            matchedWord: res['word'] as String,
            keywordMatched: kw,
            location: 'main',
            reason: 'Terdeteksi dalam komposisi utama: "${res['word']}"',
          );
          break;
        }
      }

      // 2. Search keywords in traceText (if not found in main)
      if (foundInMain == null && traceText.isNotEmpty) {
        for (final kw in allergen.keywords) {
          final res = findMatch(traceText, kw, allergenId: allergen.id);
          if (res['matched'] == true) {
            foundInTrace = AllergenFinding(
              allergenId: allergen.id,
              allergenLabel: allergen.label,
              matchedWord: res['word'] as String,
              keywordMatched: kw,
              location: 'trace',
              reason: 'Terdeteksi pada peringatan jejak fasilitas: "${res['word']}"',
            );
            break;
          }
        }
      }

      // 3. Search ambiguous terms
      if (foundInMain == null && foundInTrace == null && allergen.ambiguous.isNotEmpty) {
        for (final amb in allergen.ambiguous) {
          var res = findMatch(mainText, amb, isAmbiguous: true, allergenId: allergen.id);
          var loc = 'main';
          if (res['matched'] != true && traceText.isNotEmpty) {
            res = findMatch(traceText, amb, isAmbiguous: true, allergenId: allergen.id);
            loc = 'trace';
          }

          if (res['matched'] == true) {
            foundAmbiguous = AllergenFinding(
              allergenId: allergen.id,
              allergenLabel: allergen.label,
              matchedWord: res['word'] as String,
              keywordMatched: amb,
              location: 'ambiguous',
              reason: allergen.id == 'kacang_tanah'
                  ? 'Terdeteksi kata "kacang" tanpa nama varietas, berpotensi kacang tanah'
                  : 'Terdeteksi istilah umum "${res['word']}" yang berpotensi memicu ${allergen.label}',
            );
            break;
          }
        }
      }

      if (foundInMain != null) {
        findings.add(foundInMain);
      } else if (foundInTrace != null) {
        findings.add(foundInTrace);
      } else if (foundAmbiguous != null) {
        findings.add(foundAmbiguous);
      }
    }

    // Determine final risk level
    RiskLevel riskLevel = RiskLevel.aman;
    if (findings.any((f) => f.location == 'main')) {
      riskLevel = RiskLevel.tinggi;
    } else if (findings.any((f) => f.location == 'trace' || f.location == 'ambiguous')) {
      riskLevel = RiskLevel.sedang;
    } else {
      riskLevel = RiskLevel.aman;
    }

    return ScanResult(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      productName: productName,
      brandOrCategory: brandOrCategory,
      rawText: ocrText,
      normalizedText: normalized,
      mainText: mainText,
      traceText: traceText,
      riskLevel: riskLevel,
      findings: findings,
      timestamp: DateTime.now(),
      charCount: charCount,
      isTextTooShort: isTextTooShort,
      imagePath: imagePath,
    );
  }
}
