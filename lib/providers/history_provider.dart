import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../services/storage_service.dart';

class HistoryProvider with ChangeNotifier {
  final StorageService _storageService;
  List<ScanResult> _history = [];
  bool _isLoading = true;

  HistoryProvider(this._storageService) {
    load();
  }

  bool get isLoading => _isLoading;
  List<ScanResult> get history => _history;

  int get totalCount => _history.length;
  int get highRiskCount => _history.where((s) => s.riskLevel == RiskLevel.tinggi).length;
  int get mediumRiskCount => _history.where((s) => s.riskLevel == RiskLevel.sedang).length;
  int get safeCount => _history.where((s) => s.riskLevel == RiskLevel.aman).length;

  void load() {
    _isLoading = true;
    notifyListeners();

    _history = _storageService.loadHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addScan(ScanResult result) async {
    await _storageService.addHistoryItem(result);
    _history.insert(0, result);
    notifyListeners();
  }

  Future<void> removeScan(String id) async {
    await _storageService.removeHistoryItem(id);
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _storageService.clearHistory();
    _history.clear();
    notifyListeners();
  }
}
