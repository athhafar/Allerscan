import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allergen_profile.dart';
import '../models/scan_result.dart';

class StorageService {
  static const String _keySelectedAllergenIds = 'allerscan_selected_allergen_ids';
  static const String _keyCustomAllergens = 'allerscan_custom_allergens';
  static const String _keyScanHistory = 'allerscan_history_items';
  static const String _keyHasCompletedOnboarding = 'allerscan_has_completed_onboarding';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Load standard allergens from assets/allergens.json
  Future<Map<String, AllergenDef>> loadPresetAllergens() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/allergens.json');
      final Map<String, dynamic> data = json.decode(jsonStr);
      final Map<String, AllergenDef> map = {};
      data.forEach((key, val) {
        map[key] = AllergenDef.fromJson(key, val as Map<String, dynamic>);
      });
      return map;
    } catch (e) {
      // Fallback presets if asset loading fails
      return {};
    }
  }

  // Custom Allergens
  List<AllergenDef> loadCustomAllergens() {
    final raw = _prefs.getStringList(_keyCustomAllergens) ?? [];
    return raw.map((str) {
      final map = json.decode(str) as Map<String, dynamic>;
      return AllergenDef.fromJson(map['id'] as String, map, isCustom: true);
    }).toList();
  }

  Future<void> saveCustomAllergens(List<AllergenDef> list) async {
    final strings = list.map((item) => json.encode(item.toJson())).toList();
    await _prefs.setStringList(_keyCustomAllergens, strings);
  }

  // Selected Active Allergen IDs
  List<String> loadSelectedAllergenIds() {
    final list = _prefs.getStringList(_keySelectedAllergenIds);
    if (list == null) {
      // Default initial selection per screen design: Kacang, Susu, Gluten, Udang
      return ['kacang_tanah', 'susu', 'gluten', 'udang'];
    }
    return list;
  }

  Future<void> saveSelectedAllergenIds(List<String> ids) async {
    await _prefs.setStringList(_keySelectedAllergenIds, ids);
  }

  // Onboarding flag
  bool hasCompletedOnboarding() {
    return _prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  Future<void> setCompletedOnboarding(bool val) async {
    await _prefs.setBool(_keyHasCompletedOnboarding, val);
  }

  // Scan History
  List<ScanResult> loadHistory() {
    final list = _prefs.getStringList(_keyScanHistory) ?? [];
    return list.map((item) {
      final map = json.decode(item) as Map<String, dynamic>;
      return ScanResult.fromJson(map);
    }).toList();
  }

  Future<void> saveHistory(List<ScanResult> list) async {
    final strings = list.map((item) => json.encode(item.toJson())).toList();
    await _prefs.setStringList(_keyScanHistory, strings);
  }

  Future<void> addHistoryItem(ScanResult item) async {
    final current = loadHistory();
    current.insert(0, item);
    await saveHistory(current);
  }

  Future<void> removeHistoryItem(String id) async {
    final current = loadHistory();
    current.removeWhere((item) => item.id == id);
    await saveHistory(current);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_keyScanHistory);
  }
}
