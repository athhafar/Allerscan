enum RiskLevel {
  tinggi,
  sedang,
  aman,
}

extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.tinggi:
        return 'RISIKO TINGGI';
      case RiskLevel.sedang:
        return 'RISIKO SEDANG';
      case RiskLevel.aman:
        return 'RISIKO RENDAH / AMAN';
    }
  }

  String get shortLabel {
    switch (this) {
      case RiskLevel.tinggi:
        return 'Tinggi';
      case RiskLevel.sedang:
        return 'Sedang';
      case RiskLevel.aman:
        return 'Aman';
    }
  }
}

class AllergenFinding {
  final String allergenId;
  final String allergenLabel;
  final String matchedWord;
  final String keywordMatched;
  final String location; // 'main', 'trace', 'ambiguous'
  final String? reason;

  AllergenFinding({
    required this.allergenId,
    required this.allergenLabel,
    required this.matchedWord,
    required this.keywordMatched,
    required this.location,
    this.reason,
  });

  factory AllergenFinding.fromJson(Map<String, dynamic> json) {
    return AllergenFinding(
      allergenId: json['allergenId'] as String? ?? '',
      allergenLabel: json['allergenLabel'] as String? ?? '',
      matchedWord: json['matchedWord'] as String? ?? '',
      keywordMatched: json['keywordMatched'] as String? ?? '',
      location: json['location'] as String? ?? 'main',
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergenId': allergenId,
      'allergenLabel': allergenLabel,
      'matchedWord': matchedWord,
      'keywordMatched': keywordMatched,
      'location': location,
      'reason': reason,
    };
  }
}

class ScanResult {
  final String id;
  final String productName;
  final String? brandOrCategory;
  final String rawText;
  final String normalizedText;
  final String mainText;
  final String traceText;
  final RiskLevel riskLevel;
  final List<AllergenFinding> findings;
  final DateTime timestamp;
  final int charCount;
  final bool isTextTooShort;
  final String? imagePath;
  final List<String> cleanedIngredients;
  final List<String> traceWarnings;
  final String? aiSummary;
  final List<String> flaggedIngredients;

  ScanResult({
    required this.id,
    this.productName = 'Produk tanpa nama',
    this.brandOrCategory,
    required this.rawText,
    required this.normalizedText,
    required this.mainText,
    required this.traceText,
    required this.riskLevel,
    required this.findings,
    required this.timestamp,
    required this.charCount,
    this.isTextTooShort = false,
    this.imagePath,
    this.cleanedIngredients = const [],
    this.traceWarnings = const [],
    this.aiSummary,
    this.flaggedIngredients = const [],
  });

  ScanResult copyWith({
    String? id,
    String? productName,
    String? brandOrCategory,
    String? rawText,
    String? normalizedText,
    String? mainText,
    String? traceText,
    RiskLevel? riskLevel,
    List<AllergenFinding>? findings,
    DateTime? timestamp,
    int? charCount,
    bool? isTextTooShort,
    String? imagePath,
    List<String>? cleanedIngredients,
    List<String>? traceWarnings,
    String? aiSummary,
    List<String>? flaggedIngredients,
  }) {
    return ScanResult(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      brandOrCategory: brandOrCategory ?? this.brandOrCategory,
      rawText: rawText ?? this.rawText,
      normalizedText: normalizedText ?? this.normalizedText,
      mainText: mainText ?? this.mainText,
      traceText: traceText ?? this.traceText,
      riskLevel: riskLevel ?? this.riskLevel,
      findings: findings ?? this.findings,
      timestamp: timestamp ?? this.timestamp,
      charCount: charCount ?? this.charCount,
      isTextTooShort: isTextTooShort ?? this.isTextTooShort,
      imagePath: imagePath ?? this.imagePath,
      cleanedIngredients: cleanedIngredients ?? this.cleanedIngredients,
      traceWarnings: traceWarnings ?? this.traceWarnings,
      aiSummary: aiSummary ?? this.aiSummary,
      flaggedIngredients: flaggedIngredients ?? this.flaggedIngredients,
    );
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String,
      productName: json['productName'] as String? ?? 'Produk tanpa nama',
      brandOrCategory: json['brandOrCategory'] as String?,
      rawText: json['rawText'] as String? ?? '',
      normalizedText: json['normalizedText'] as String? ?? '',
      mainText: json['mainText'] as String? ?? '',
      traceText: json['traceText'] as String? ?? '',
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['riskLevel'],
        orElse: () => RiskLevel.aman,
      ),
      findings: (json['findings'] as List<dynamic>?)
              ?.map((e) => AllergenFinding.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      charCount: json['charCount'] as int? ?? 0,
      isTextTooShort: json['isTextTooShort'] as bool? ?? false,
      imagePath: json['imagePath'] as String?,
      cleanedIngredients: (json['cleanedIngredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      traceWarnings: (json['traceWarnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aiSummary: json['aiSummary'] as String?,
      flaggedIngredients: (json['flaggedIngredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'brandOrCategory': brandOrCategory,
      'rawText': rawText,
      'normalizedText': normalizedText,
      'mainText': mainText,
      'traceText': traceText,
      'riskLevel': riskLevel.name,
      'findings': findings.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'charCount': charCount,
      'isTextTooShort': isTextTooShort,
      'imagePath': imagePath,
      'cleanedIngredients': cleanedIngredients,
      'traceWarnings': traceWarnings,
      'aiSummary': aiSummary,
      'flaggedIngredients': flaggedIngredients,
    };
  }
}
