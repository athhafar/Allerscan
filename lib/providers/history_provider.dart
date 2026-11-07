import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class HistoryProvider with ChangeNotifier {
  final StorageService _storageService;
  List<ScanResult> _history = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  HistoryProvider(this._storageService) {
    _history = _storageService.loadHistory();
    _isLoading = false;
    if (SupabaseService.isConfigured) {
      Future.microtask(() => syncWithSupabase());
    }
  }

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  List<ScanResult> get history => _history;

  int get totalCount => _history.length;
  int get highRiskCount => _history.where((s) => s.riskLevel == RiskLevel.tinggi).length;
  int get mediumRiskCount => _history.where((s) => s.riskLevel == RiskLevel.sedang).length;
  int get safeCount => _history.where((s) => s.riskLevel == RiskLevel.aman).length;

  void load() {
    _isLoading = true;
    _history = _storageService.loadHistory();
    _isLoading = false;
    notifyListeners();

    // Jalankan background sync dengan Supabase jika terhubung
    if (SupabaseService.isConfigured) {
      syncWithSupabase();
    }
  }

  Future<void> addScan(ScanResult result) async {
    await _storageService.addHistoryItem(result);
    _history.insert(0, result);
    notifyListeners();

    // Simpan ke Supabase jika terkonfigurasi
    if (SupabaseService.isConfigured) {
      SupabaseService.saveScanLog(result);
    }
  }

  Future<void> removeScan(String id) async {
    await _storageService.removeHistoryItem(id);
    _history.removeWhere((item) => item.id == id);
    notifyListeners();

    if (SupabaseService.isConfigured) {
      SupabaseService.deleteScanLog(id);
    }
  }

  Future<void> clearAll() async {
    await _storageService.clearHistory();
    _history.clear();
    notifyListeners();

    if (SupabaseService.isConfigured) {
      SupabaseService.clearAllScanLogs();
    }
  }

  /// Sinkronkan data riwayat dari tabel 'scan_logs' di Supabase
  Future<void> syncWithSupabase() async {
    if (!SupabaseService.isConfigured || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final remoteLogs = await SupabaseService.fetchScanLogs();
      if (remoteLogs.isNotEmpty) {
        // Gabungkan riwayat lokal dan remote berdasarkan ID unik
        final Map<String, ScanResult> combined = {};
        for (final item in _history) {
          combined[item.id] = item;
        }
        for (final item in remoteLogs) {
          if (!combined.containsKey(item.id)) {
            combined[item.id] = item;
          }
        }

        final sorted = combined.values.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _history = sorted;
        await _storageService.saveHistory(_history);
      }
    } catch (e) {
      debugPrint('[HistoryProvider] Error sync dengan Supabase: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
