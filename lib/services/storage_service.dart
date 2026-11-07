import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allergen_profile.dart';
import '../models/scan_result.dart';
import '../utils/uuid_util.dart';

class StorageService {
  static const String _keySelectedAllergenIds = 'allerscan_selected_allergen_ids';
  static const String _keyCustomAllergens = 'allerscan_custom_allergens';
  static const String _keyScanHistory = 'allerscan_history_items';
  static const String _keyHasCompletedOnboarding = 'allerscan_has_completed_onboarding';
  static const String _keySupabaseAnonKey = 'allerscan_supabase_anon_key';
  static const String _keyUserId = 'allerscan_user_id';
  static const String _keyUserName = 'allerscan_user_name';
  static const String _keyUserEmail = 'allerscan_user_email';
  static const String _keyCachedAllergens = 'allerscan_supabase_allergens_cache';
  static const String _keyIsGuestMode = 'allerscan_is_guest_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Cache kamus alergen murni dari Supabase agar cepat & tetap bisa offline
  Map<String, AllergenDef> loadCachedDatabaseAllergens() {
    final raw = _prefs.getString(_keyCachedAllergens);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> data = json.decode(raw);
      final Map<String, AllergenDef> map = {};
      data.forEach((key, val) {
        map[key] = AllergenDef.fromJson(key, val as Map<String, dynamic>);
      });
      return map;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveCachedDatabaseAllergens(Map<String, AllergenDef> map) async {
    final Map<String, dynamic> data = {};
    map.forEach((key, def) {
      data[key] = def.toJson();
    });
    await _prefs.setString(_keyCachedAllergens, json.encode(data));
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

  // Selected Active Allergen IDs (Default: ALG-01 Gluten, ALG-05 Kacang Tanah, ALG-07 Susu, ALG-02 Krustasea)
  List<String> loadSelectedAllergenIds() {
    final list = _prefs.getStringList(_keySelectedAllergenIds);
    if (list == null) {
      return ['ALG-01', 'ALG-05', 'ALG-07', 'ALG-02'];
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

  // Supabase Credentials & User State
  String? getSupabaseAnonKey() {
    return _prefs.getString(_keySupabaseAnonKey);
  }

  Future<void> saveSupabaseAnonKey(String key) async {
    await _prefs.setString(_keySupabaseAnonKey, key.trim());
  }

  String getOrCreateUserId() {
    String? id = _prefs.getString(_keyUserId);
    if (id == null || !UuidUtil.isValidUuid(id)) {
      id = UuidUtil.generate();
      _prefs.setString(_keyUserId, id);
    }
    return id;
  }

  String getUserName() {
    return _prefs.getString(_keyUserName) ?? 'Pengguna AllerScan';
  }

  Future<void> saveUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  String getUserEmail() {
    return _prefs.getString(_keyUserEmail) ?? '';
  }

  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(_keyUserEmail, email);
  }

  bool isGuestMode() {
    return _prefs.getBool(_keyIsGuestMode) ?? false;
  }

  Future<void> setGuestMode(bool val) async {
    await _prefs.setBool(_keyIsGuestMode, val);
  }
}
