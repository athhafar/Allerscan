import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/allergen_profile.dart';
import '../models/scan_result.dart';
import '../utils/uuid_util.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class SupabaseService {
  /// URL Project Supabase dari project 'foodalert-db':
  static const String supabaseUrl = 'https://igrhtylidqpqllixchng.supabase.co';

  /// Masukkan Supabase Anon (Public) Key Anda di sini:
  static const String supabaseAnonKey = 'sb_publishable_b4KMQ7EDDIpF0RU-Li5ZoQ_QPyH42_b';

  static bool _isInitialized = false;
  static String? _activeAnonKey;
  static StorageService? _storageService;

  static bool get isInitialized => _isInitialized;
  static String? get activeAnonKey => _activeAnonKey;

  static bool get isConfigured {
    if (_activeAnonKey != null && _activeAnonKey!.isNotEmpty) return true;
    if (supabaseAnonKey.isNotEmpty && supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY') return true;
    return false;
  }

  /// Inisialisasi Supabase saat aplikasi Flutter pertama kali dimulai
  static Future<void> init({StorageService? storageService}) async {
    if (storageService != null) {
      _storageService = storageService;
    }

    // Cek key dari konstanta kode atau dari SharedPreferences
    String? keyToUse = supabaseAnonKey.trim();
    if (keyToUse.isEmpty || keyToUse == 'YOUR_SUPABASE_ANON_KEY') {
      keyToUse = _storageService?.getSupabaseAnonKey();
    }

    if (keyToUse == null || keyToUse.isEmpty) {
      debugPrint('[SupabaseService] Anon Key belum diisi. Aplikasi berjalan dalam mode lokal offline.');
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: keyToUse,
      );
      _activeAnonKey = keyToUse;
      _isInitialized = true;
      debugPrint('[SupabaseService] Berhasil terhubung ke Supabase ($supabaseUrl)');

      // Daftarkan atau pastikan user lokal tersinkron ke tabel 'users'
      if (_storageService != null) {
        await ensureUserRegistered(_storageService!);
      }
    } catch (e) {
      debugPrint('[SupabaseService] Gagal inisialisasi Supabase: $e');
    }
  }

  /// Update key dan hubungkan ulang secara langsung dari aplikasi
  static Future<Map<String, dynamic>> updateAndConnect(
    String newKey,
    StorageService storageService,
  ) async {
    final cleanKey = newKey.trim();
    if (cleanKey.isEmpty) {
      return {'success': false, 'message': 'Kunci anon key tidak boleh kosong.'};
    }

    // Uji koneksi terlebih dahulu
    final testResult = await testConnection(cleanKey);
    if (!testResult['success']) {
      return testResult;
    }

    // Simpan ke storage lokal
    await storageService.saveSupabaseAnonKey(cleanKey);
    _storageService = storageService;
    _activeAnonKey = cleanKey;

    try {
      if (!_isInitialized) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: cleanKey,
        );
        _isInitialized = true;
      }
      await ensureUserRegistered(storageService);
      return {'success': true, 'message': 'Berhasil terhubung ke Supabase foodalert-db!'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal inisialisasi client: $e'};
    }
  }

  /// Menguji koneksi dengan anonKey yang dimasukkan
  static Future<Map<String, dynamic>> testConnection(String testKey) async {
    try {
      final tempClient = SupabaseClient(supabaseUrl, testKey.trim());
      // Lakukan query sederhana untuk memverifikasi autentikasi & URL
      await tempClient.from('allergen_groups').select('group_id').limit(1);
      return {
        'success': true,
        'message': 'Koneksi ke database foodalert-db terverifikasi!',
      };
    } catch (e) {
      final err = e.toString();
      if (err.contains('JWT') || err.contains('invalid') || err.contains('apikey')) {
        return {
          'success': false,
          'message': 'Anon key tidak valid atau kedaluwarsa. Periksa kembali kunci Anda.',
        };
      }
      return {
        'success': false,
        'message': 'Gagal terhubung ke Supabase: $e',
      };
    }
  }

  /// Client Supabase untuk query langsung
  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  // ===========================================================================
  // 1. AUTENTIKASI, OAUTH, & TOKEN SESI (Supabase Auth)
  // ===========================================================================

  static User? get currentUser => client?.auth.currentUser;
  static Session? get currentSession => client?.auth.currentSession;
  static bool get isAuthenticated =>
      client?.auth.currentUser != null && client?.auth.currentSession != null;

  static String get effectiveUserId {
    return client?.auth.currentUser?.id ?? _storageService?.getOrCreateUserId() ?? '';
  }

  static String get effectiveUserEmail {
    return client?.auth.currentUser?.email ?? _storageService?.getUserEmail() ?? '';
  }

  static String get effectiveUserName {
    final meta = client?.auth.currentUser?.userMetadata;
    final name = meta?['full_name'] as String? ?? meta?['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return _storageService?.getUserName() ?? 'Pengguna AllerScan';
  }

  /// Masuk dengan Email & Password
  static Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final sb = client;
    if (sb == null) return {'success': false, 'message': 'Supabase belum siap.'};

    try {
      final res = await sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user != null && _storageService != null) {
        await _storageService!.setGuestMode(false);
        await ensureUserRegistered(_storageService!, user: res.user);
      }
      return {'success': true, 'user': res.user};
    } on AuthException catch (e) {
      return {'success': false, 'message': _translateAuthError(e.message)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal masuk: $e'};
    }
  }

  /// Daftar akun baru dengan Email & Password
  static Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final sb = client;
    if (sb == null) return {'success': false, 'message': 'Supabase belum siap.'};

    try {
      final res = await sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: name != null && name.isNotEmpty ? {'full_name': name.trim()} : null,
      );
      if (res.user != null && _storageService != null) {
        await _storageService!.setGuestMode(false);
        if (name != null && name.isNotEmpty) {
          await _storageService!.saveUserName(name.trim());
        }
        await ensureUserRegistered(_storageService!, user: res.user);
      }
      return {
        'success': true,
        'user': res.user,
        'requiresEmailConfirmation': res.session == null,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': _translateAuthError(e.message)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mendaftar: $e'};
    }
  }

  /// Masuk dengan OAuth (Google, Apple, dll.)
  static Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final sb = client;
    if (sb == null) return false;

    try {
      final res = await sb.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.allerscan://login-callback',
      );
      return res;
    } catch (e) {
      debugPrint('[SupabaseService] OAuth error: $e');
      return false;
    }
  }

  /// Masuk dengan Google (Native ID Token)
  static Future<AuthResponse> signInWithGoogle() async {
    return AuthService.signInWithGoogle();
  }

  /// Keluar / Logout
  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('[SupabaseService] Error Google signOut: $e');
    }
    final sb = client;
    if (sb == null) return;
    try {
      await sb.auth.signOut();
      if (_storageService != null) {
        await _storageService!.setGuestMode(false);
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error signOut: $e');
    }
  }

  static String _translateAuthError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
    } else if (lower.contains('user already registered')) {
      return 'Email ini sudah terdaftar. Silakan langsung masuk.';
    } else if (lower.contains('password should be at least')) {
      return 'Kata sandi minimal harus 6 karakter.';
    } else if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Periksa kotak masuk/spam Anda.';
    }
    return msg;
  }

  // ===========================================================================
  // 2. MANAJEMEN PENGGUNA ('users' table)
  // Schema: id (uuid), name (varchar), email (varchar), created_at (timestamp)
  // ===========================================================================

  static Future<void> ensureUserRegistered(StorageService storage, {User? user}) async {
    final sb = client;
    if (sb == null) return;

    try {
      final effectiveUser = user ?? sb.auth.currentUser;
      final userId = effectiveUser?.id ?? storage.getOrCreateUserId();

      final meta = effectiveUser?.userMetadata;
      final rawName = meta?['full_name'] as String? ??
          meta?['name'] as String? ??
          storage.getUserName();
      final userName = rawName.isNotEmpty ? rawName : 'Pengguna AllerScan';

      final userEmail = effectiveUser?.email ??
          (storage.getUserEmail().isNotEmpty
              ? storage.getUserEmail()
              : 'user_${userId.substring(0, 8)}@allerscan.local');

      await sb.from('users').upsert({
        'id': userId,
        'name': userName,
        'email': userEmail,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      debugPrint('[SupabaseService] User ($userId) tersinkronisasi ke tabel users.');
    } catch (e) {
      debugPrint('[SupabaseService] Sinkronisasi user ke tabel users dilewati/gagal: $e');
    }
  }

  // ===========================================================================
  // 2. RIWAYAT PEMINDAIAN ('scan_logs' table)
  // Schema: id (uuid), user_id (uuid), product_name, raw_text, risk_level, detected_items, scanned_at
  // ===========================================================================

  static Future<bool> saveScanLog(ScanResult result, {String? userId}) async {
    final sb = client;
    if (sb == null) return false;

    try {
      final effectiveUserId =
          userId ?? client?.auth.currentUser?.id ?? _storageService?.getOrCreateUserId();
      // Simpan findings & data analisis AI dalam format JSON
      final Map<String, dynamic> metaPayload = {
        'findings': result.findings.map((f) => f.toJson()).toList(),
        'aiSummary': result.aiSummary,
        'cleanedIngredients': result.cleanedIngredients,
        'traceWarnings': result.traceWarnings,
        'flaggedIngredients': result.flaggedIngredients,
      };
      final detectedSummary = json.encode(metaPayload);

      // Pastikan id bertipe UUID v4 yang valid
      final recordId = UuidUtil.isValidUuid(result.id) ? result.id : UuidUtil.generate();

      await sb.from('scan_logs').upsert({
        'id': recordId,
        'user_id': effectiveUserId,
        'product_name': result.productName,
        'raw_text': result.rawText,
        'risk_level': result.riskLevel.name,
        'detected_items': detectedSummary,
        'scanned_at': result.timestamp.toIso8601String(),
      }, onConflict: 'id');

      debugPrint('[SupabaseService] Scan log berhasil disimpan ke Supabase.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal menyimpan scan log ke Supabase: $e');
      return false;
    }
  }

  static Future<List<ScanResult>> fetchScanLogs({String? userId, int limit = 50}) async {
    final sb = client;
    if (sb == null) return [];

    try {
      final effectiveUserId =
          userId ?? client?.auth.currentUser?.id ?? _storageService?.getOrCreateUserId();
      var query = sb.from('scan_logs').select();
      
      if (effectiveUserId != null) {
        query = query.eq('user_id', effectiveUserId);
      }

      final response = await query.order('scanned_at', ascending: false).limit(limit);

      final List<ScanResult> results = [];
      for (final row in response) {
        final riskStr = row['risk_level'] as String? ?? 'aman';
        final riskLevel = RiskLevel.values.firstWhere(
          (r) => r.name == riskStr,
          orElse: () => RiskLevel.aman,
        );

        final scannedAt = DateTime.tryParse(row['scanned_at'] as String? ?? '') ?? DateTime.now();
        final raw = row['raw_text'] as String? ?? '';
        final detectedRaw = row['detected_items'] as String? ?? '';

        List<AllergenFinding> parsedFindings = [];
        String? aiSummary;
        List<String> cleanedIngredients = [];
        List<String> traceWarnings = [];
        List<String> flaggedIngredients = [];

        if (detectedRaw.startsWith('{') && detectedRaw.endsWith('}')) {
          try {
            final Map<String, dynamic> meta = json.decode(detectedRaw);
            if (meta['findings'] is List) {
              parsedFindings = (meta['findings'] as List)
                  .map((e) => AllergenFinding.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            aiSummary = meta['aiSummary'] as String?;
            cleanedIngredients = (meta['cleanedIngredients'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            traceWarnings = (meta['traceWarnings'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            flaggedIngredients = (meta['flaggedIngredients'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
          } catch (_) {}
        } else if (detectedRaw.startsWith('[') && detectedRaw.endsWith(']')) {
          try {
            final List<dynamic> list = json.decode(detectedRaw);
            parsedFindings = list
                .map((e) => AllergenFinding.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {}
        } else if (detectedRaw.isNotEmpty && !detectedRaw.startsWith('Aman')) {
          // Kompatibilitas mundur jika berupa ringkasan teks biasa
          final items = detectedRaw.split(', ');
          parsedFindings = items.map((it) {
            return AllergenFinding(
              allergenId: 'detected',
              allergenLabel: it,
              matchedWord: it,
              keywordMatched: it,
              location: 'main',
            );
          }).toList();
        }

        results.add(ScanResult(
          id: row['id'] as String? ?? UuidUtil.generate(),
          productName: row['product_name'] as String? ?? 'Produk tanpa nama',
          rawText: raw,
          normalizedText: raw.toLowerCase(),
          mainText: raw,
          traceText: '',
          riskLevel: riskLevel,
          findings: parsedFindings,
          timestamp: scannedAt,
          charCount: raw.length,
          aiSummary: aiSummary,
          cleanedIngredients: cleanedIngredients,
          traceWarnings: traceWarnings,
          flaggedIngredients: flaggedIngredients,
        ));
      }
      return results;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal mengambil scan_logs: $e');
      return [];
    }
  }

  static Future<bool> deleteScanLog(String id) async {
    final sb = client;
    if (sb == null) return false;

    try {
      await sb.from('scan_logs').delete().eq('id', id);
      debugPrint('[SupabaseService] Log scan ($id) terhapus dari Supabase.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal menghapus scan log di Supabase: $e');
      return false;
    }
  }

  static Future<bool> clearAllScanLogs({String? userId}) async {
    final sb = client;
    if (sb == null) return false;

    try {
      final effectiveUserId =
          userId ?? client?.auth.currentUser?.id ?? _storageService?.getOrCreateUserId();
      if (effectiveUserId != null) {
        await sb.from('scan_logs').delete().eq('user_id', effectiveUserId);
      } else {
        await sb.from('scan_logs').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      }
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal membersihkan scan logs di Supabase: $e');
      return false;
    }
  }

  // ===========================================================================
  // 3. PROFIL ALERGI PENGGUNA ('user_allergies' table)
  // Schema: id (uuid), user_id (uuid), group_id (varchar), created_at (timestamp)
  // ===========================================================================

  static Future<bool> syncUserAllergies(String userId, List<String> groupIds) async {
    final sb = client;
    if (sb == null) return false;

    try {
      // Hapus pilihan lama user di cloud
      await sb.from('user_allergies').delete().eq('user_id', userId);

      // Masukkan pilihan baru
      if (groupIds.isNotEmpty) {
        final rows = groupIds.map((gid) => {
          'id': UuidUtil.generate(),
          'user_id': userId,
          'group_id': gid,
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await sb.from('user_allergies').insert(rows);
      }
      debugPrint('[SupabaseService] Pilihan alergen user ($userId) tersinkron ke Supabase.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal sinkronisasi user_allergies ke Supabase: $e');
      return false;
    }
  }

  static Future<List<String>> fetchUserAllergies(String userId) async {
    final sb = client;
    if (sb == null) return [];

    try {
      final response = await sb.from('user_allergies').select('group_id').eq('user_id', userId);
      return (response as List<dynamic>).map((row) => row['group_id'] as String).toList();
    } catch (e) {
      debugPrint('[SupabaseService] Gagal mengambil user_allergies: $e');
      return [];
    }
  }

  // ===========================================================================
  // 4. KAMUS ALERGEN DINAMIS MURNI DARI DATABASE ('allergen_groups' & 'allergen_keywords')
  // ===========================================================================

  static Future<Map<String, AllergenDef>> fetchDatabaseAllergens() async {
    final sb = client;
    if (sb == null) return {};

    try {
      final groups = await sb.from('allergen_groups').select().order('group_id');
      if (groups.isEmpty) return {};

      // Ambil seluruh kata kunci (hingga 1000 entri)
      final keywordsResponse = await sb
          .from('allergen_keywords')
          .select()
          .limit(1000);

      final Map<String, Set<String>> keywordMap = {};
      final Map<String, Set<String>> ambiguousMap = {};

      for (final kw in keywordsResponse) {
        final gid = kw['group_id'] as String? ?? '';
        final norm = (kw['keyword_normalized'] ?? '').toString().trim().toLowerCase();
        final orig = (kw['original_term'] ?? '').toString().trim().toLowerCase();
        final risk = (kw['risk_if_in_composition'] ?? '').toString().toUpperCase();
        final relation = (kw['relation_type'] ?? '').toString().toLowerCase();

        if (gid.isEmpty) continue;

        final isAmbiguous = risk == 'MODERATE_AMBIGUOUS' || relation == 'ambiguous';

        final targetSet = isAmbiguous
            ? ambiguousMap.putIfAbsent(gid, () => {})
            : keywordMap.putIfAbsent(gid, () => {});

        if (norm.isNotEmpty) targetSet.add(norm);
        if (orig.isNotEmpty) targetSet.add(orig);
      }

      final Map<String, AllergenDef> result = {};
      for (final g in groups) {
        final gid = g['group_id'] as String? ?? '';
        if (gid.isEmpty) continue;

        final label = g['group_name_id'] as String? ?? g['standard_label'] as String? ?? gid;
        final subtitle = g['standard_label'] != null && g['standard_label'] != label
            ? '${g['standard_label']} • ${g['summary_sources'] ?? ''}'
            : (g['summary_sources'] as String? ?? '');

        result[gid] = AllergenDef(
          id: gid,
          label: label,
          subtitle: subtitle,
          icon: getIconForGroupId(gid),
          keywords: (keywordMap[gid] ?? {label.toLowerCase()}).toList(),
          ambiguous: (ambiguousMap[gid] ?? {}).toList(),
          isCustom: false,
        );
      }

      debugPrint('[SupabaseService] Berhasil memuat ${result.length} grup alergen & ${keywordsResponse.length} kata kunci murni dari Supabase.');
      return result;
    } catch (e) {
      debugPrint('[SupabaseService] Gagal memuat kamus alergen dari Supabase: $e');
      return {};
    }
  }

  static String getIconForGroupId(String gid) {
    switch (gid) {
      case 'ALG-01': // Serealia gluten
        return 'grain';
      case 'ALG-02': // Krustasea
        return 'set_meal';
      case 'ALG-03': // Telur
        return 'egg';
      case 'ALG-04': // Ikan
        return 'phishing';
      case 'ALG-05': // Kacang tanah
        return 'nutrition';
      case 'ALG-06': // Kedelai
        return 'eco';
      case 'ALG-07': // Susu
        return 'local_cafe';
      case 'ALG-08': // Kacang pohon
        return 'bubble_chart';
      case 'ALG-09': // Moluska
        return 'set_meal';
      case 'ALG-10': // Sulfit
        return 'bubble_chart';
      case 'ALG-11': // Wijen
        return 'grain';
      default:
        return 'shield';
    }
  }

  /// Fitur Bantuan: Menyemai data awal (Seed) preset ke tabel Supabase jika masih kosong
  static Future<Map<String, dynamic>> seedAllergensToDatabase(
    Map<String, AllergenDef> presets,
  ) async {
    final sb = client;
    if (sb == null) {
      return {'success': false, 'message': 'Supabase belum terhubung.'};
    }

    try {
      int insertedGroups = 0;
      int insertedKeywords = 0;

      for (final entry in presets.entries) {
        final def = entry.value;

        // 1. Masukkan ke allergen_groups
        await sb.from('allergen_groups').upsert({
          'group_id': def.id,
          'group_name_id': def.label,
          'standard_label': def.label,
          'summary_sources': def.subtitle,
          'implementation_notes': 'Otomatis diisi dari kamus AllerScan',
          'initial_reference': 'BPOM / Codex Alimentarius',
        }, onConflict: 'group_id');
        insertedGroups++;

        // 2. Masukkan kata kunci ke allergen_keywords
        for (final kw in def.keywords) {
          final kwId = '${def.id}_${kw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
          await sb.from('allergen_keywords').upsert({
            'keyword_id': kwId,
            'group_id': def.id,
            'keyword_normalized': kw.toLowerCase(),
            'original_term': kw,
            'relation_type': 'exact',
            'risk_if_in_composition': 'tinggi',
          }, onConflict: 'keyword_id');
          insertedKeywords++;
        }

        // 3. Masukkan kata ambigu
        for (final amb in def.ambiguous) {
          final ambId = '${def.id}_amb_${amb.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
          await sb.from('allergen_keywords').upsert({
            'keyword_id': ambId,
            'group_id': def.id,
            'keyword_normalized': amb.toLowerCase(),
            'original_term': amb,
            'relation_type': 'ambiguous',
            'risk_if_in_composition': 'sedang',
          }, onConflict: 'keyword_id');
          insertedKeywords++;
        }
      }

      return {
        'success': true,
        'message': 'Berhasil menyemai $insertedGroups grup alergen dan $insertedKeywords kata kunci ke Supabase!',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyemai data: $e'};
    }
  }
}
