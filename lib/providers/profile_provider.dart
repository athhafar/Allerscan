import 'package:flutter/foundation.dart';
import '../models/allergen_profile.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class ProfileProvider with ChangeNotifier {
  final StorageService _storageService;

  Map<String, AllergenDef> _allAllergens = {};
  List<AllergenDef> _customAllergens = [];
  List<String> _selectedAllergenIds = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  ProfileProvider(this._storageService) {
    init();
  }

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  Map<String, AllergenDef> get allAllergens => _allAllergens;
  List<AllergenDef> get customAllergens => _customAllergens;
  List<String> get selectedAllergenIds => _selectedAllergenIds;

  List<AllergenDef> get activeAllergens {
    final List<AllergenDef> list = [];
    for (final id in _selectedAllergenIds) {
      if (_allAllergens.containsKey(id)) {
        list.add(_allAllergens[id]!);
      }
    }
    return list;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Muat dari cache lokal (jika sebelumnya sudah pernah mengambil dari Supabase)
    _allAllergens = _storageService.loadCachedDatabaseAllergens();
    _customAllergens = _storageService.loadCustomAllergens();
    for (final c in _customAllergens) {
      _allAllergens[c.id] = c;
    }

    _selectedAllergenIds = _storageService.loadSelectedAllergenIds();

    if (_allAllergens.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
    }

    // 2. Ambil data kamus murni dari tabel Supabase
    if (SupabaseService.isConfigured) {
      await syncWithSupabase();
    }

    _isLoading = false;
    notifyListeners();
  }

  bool isSelected(String id) {
    return _selectedAllergenIds.contains(id);
  }

  Future<void> toggleAllergen(String id) async {
    if (_selectedAllergenIds.contains(id)) {
      _selectedAllergenIds.remove(id);
    } else {
      _selectedAllergenIds.add(id);
    }
    await _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
    notifyListeners();

    // Sinkronkan pilihan ke tabel 'user_allergies' di Supabase
    if (SupabaseService.isConfigured) {
      final userId = _storageService.getOrCreateUserId();
      SupabaseService.syncUserAllergies(userId, _selectedAllergenIds);
    }
  }

  /// Mencari saran bahan alergen langsung dari kamus database Supabase
  List<Map<String, String>> searchDatabaseSuggestions(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) return [];

    final List<Map<String, String>> suggestions = [];
    final Set<String> addedKeys = {};

    for (final def in _allAllergens.values) {
      if (def.isCustom) continue;

      // Cek label grup
      if (def.label.toLowerCase().contains(clean)) {
        final key = '${def.label}__${def.id}';
        if (!addedKeys.contains(key)) {
          addedKeys.add(key);
          suggestions.add({
            'term': def.label,
            'groupId': def.id,
            'groupLabel': def.label,
          });
        }
      }

      // Cek kata kunci bahan
      for (final kw in def.keywords) {
        if (kw.toLowerCase().contains(clean)) {
          final key = '${kw}__${def.id}';
          if (!addedKeys.contains(key) && suggestions.length < 8) {
            addedKeys.add(key);
            suggestions.add({
              'term': kw,
              'groupId': def.id,
              'groupLabel': def.label,
            });
          }
        }
      }

      // Cek kata ambigu
      for (final amb in def.ambiguous) {
        if (amb.toLowerCase().contains(clean)) {
          final key = '${amb}__${def.id}';
          if (!addedKeys.contains(key) && suggestions.length < 8) {
            addedKeys.add(key);
            suggestions.add({
              'term': amb,
              'groupId': def.id,
              'groupLabel': def.label,
            });
          }
        }
      }
    }

    return suggestions;
  }

  /// Memvalidasi input pengguna terhadap database Supabase:
  /// - Jika ADA di database -> DITERIMA & kelompok alergen terkait diaktifkan di profil
  /// - Jika TIDAK ADA di database -> DITOLAK (tidak disimpan ke database / profil)
  Future<Map<String, dynamic>> validateAndAddAllergen(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return {
        'success': false,
        'message': 'Nama bahan alergen tidak boleh kosong.',
      };
    }

    final query = clean.toLowerCase();

    // 1. Cari kecocokan di kamus database Supabase
    AllergenDef? matchedGroup;
    String matchedTerm = clean;

    for (final def in _allAllergens.values) {
      if (def.isCustom) continue;

      // Cek apakah sama dengan label grup atau ID grup
      if (def.label.toLowerCase() == query || def.id.toLowerCase() == query) {
        matchedGroup = def;
        matchedTerm = def.label;
        break;
      }

      // Cek kecocokan kata kunci persis
      for (final kw in def.keywords) {
        if (kw.toLowerCase() == query) {
          matchedGroup = def;
          matchedTerm = kw;
          break;
        }
      }
      if (matchedGroup != null) break;

      // Cek kecocokan kata ambigu persis
      for (final amb in def.ambiguous) {
        if (amb.toLowerCase() == query) {
          matchedGroup = def;
          matchedTerm = amb;
          break;
        }
      }
      if (matchedGroup != null) break;
    }

    // 2. Jika tidak cocok persis, cek substring
    if (matchedGroup == null) {
      for (final def in _allAllergens.values) {
        if (def.isCustom) continue;

        if (def.label.toLowerCase().contains(query)) {
          matchedGroup = def;
          matchedTerm = def.label;
          break;
        }

        for (final kw in def.keywords) {
          if (kw.toLowerCase().contains(query)) {
            matchedGroup = def;
            matchedTerm = kw;
            break;
          }
        }
        if (matchedGroup != null) break;
      }
    }

    // 3. JIKA TIDAK DITEMUKAN DI DATABASE -> TOLAK!
    if (matchedGroup == null) {
      debugPrint('[ProfileProvider] Penambahan "$clean" DITOLAK: tidak ada di database Supabase.');
      return {
        'success': false,
        'message': 'Bahan "$clean" TIDAK TERDAFTAR dalam database alergen pangan resmi BPOM/Codex. Permintaan ditolak.',
      };
    }

    // 4. JIKA DITEMUKAN DI DATABASE -> AKTIFKAN KELOMPOK TERSEBUT
    final groupId = matchedGroup.id;
    if (_selectedAllergenIds.contains(groupId)) {
      return {
        'success': false,
        'message': 'Bahan "$matchedTerm" sudah aktif di profil Anda dalam kelompok "${matchedGroup.label}".',
      };
    }

    _selectedAllergenIds.add(groupId);
    await _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
    notifyListeners();

    // Sinkronkan ke Supabase table 'user_allergies'
    if (SupabaseService.isConfigured) {
      final userId = _storageService.getOrCreateUserId();
      SupabaseService.syncUserAllergies(userId, _selectedAllergenIds);
    }

    return {
      'success': true,
      'message': 'Valid! Bahan "$matchedTerm" terverifikasi dan kelompok "${matchedGroup.label}" berhasil diaktifkan.',
      'groupId': groupId,
      'groupLabel': matchedGroup.label,
    };
  }

  Future<void> removeCustomAllergen(String id) async {
    _customAllergens.removeWhere((a) => a.id == id);
    _allAllergens.remove(id);
    _selectedAllergenIds.remove(id);

    await _storageService.saveCustomAllergens(_customAllergens);
    await _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
    notifyListeners();

    if (SupabaseService.isConfigured) {
      final userId = _storageService.getOrCreateUserId();
      SupabaseService.syncUserAllergies(userId, _selectedAllergenIds);
    }
  }

  /// Sinkronkan kamus alergen murni dari tabel 'allergen_groups' & 'allergen_keywords' di Supabase
  Future<void> syncWithSupabase() async {
    if (!SupabaseService.isConfigured || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // 1. Ambil seluruh data grup & kata kunci murni dari Supabase DB
      final dbAllergens = await SupabaseService.fetchDatabaseAllergens();
      if (dbAllergens.isNotEmpty) {
        _allAllergens = Map<String, AllergenDef>.from(dbAllergens);

        // Sisipkan custom allergen milik pengguna jika ada
        for (final c in _customAllergens) {
          _allAllergens[c.id] = c;
        }

        // Simpan ke cache lokal agar aplikasi tetap responsif & bisa dipakai offline
        await _storageService.saveCachedDatabaseAllergens(dbAllergens);
      }

      // 2. Ambil preferensi alergi pengguna dari tabel 'user_allergies'
      final userId = _storageService.getOrCreateUserId();
      final remoteUserAllergies = await SupabaseService.fetchUserAllergies(userId);
      if (remoteUserAllergies.isNotEmpty) {
        _selectedAllergenIds = remoteUserAllergies;
        await _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
      } else if (_selectedAllergenIds.isNotEmpty) {
        // Jika belum ada di Supabase, unggah pilihan saat ini
        await SupabaseService.syncUserAllergies(userId, _selectedAllergenIds);
      }
    } catch (e) {
      debugPrint('[ProfileProvider] Gagal sinkronisasi alergen murni dari Supabase: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
