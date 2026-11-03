class AllergenDef {
  final String id;
  final String label;
  final String subtitle;
  final String icon;
  final List<String> keywords;
  final List<String> ambiguous;
  final bool isCustom;

  AllergenDef({
    required this.id,
    required this.label,
    this.subtitle = '',
    this.icon = 'shield',
    required this.keywords,
    this.ambiguous = const [],
    this.isCustom = false,
  });

  factory AllergenDef.fromJson(String id, Map<String, dynamic> json, {bool isCustom = false}) {
    return AllergenDef(
      id: id,
      label: json['label'] as String? ?? id,
      subtitle: json['subtitle'] as String? ?? '',
      icon: json['icon'] as String? ?? 'shield',
      keywords: (json['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      ambiguous: (json['ambiguous'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isCustom: isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'subtitle': subtitle,
      'icon': icon,
      'keywords': keywords,
      'ambiguous': ambiguous,
      'isCustom': isCustom,
    };
  }
}
