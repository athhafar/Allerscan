import 'package:flutter/foundation.dart';
import '../models/allergen_profile.dart';
import '../services/storage_service.dart';

class ProfileProvider with ChangeNotifier {
  final StorageService _storageService;

  Map<String, AllergenDef> _allAllergens = {};
  List<AllergenDef> _customAllergens = [];
  List<String> _selectedAllergenIds = [];
  bool _isLoading = true;

  ProfileProvider(this._storageService) {
    init();
  }

  bool get isLoading => _isLoading;
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

    _allAllergens = await _storageService.loadPresetAllergens();
    _customAllergens = _storageService.loadCustomAllergens();
    for (final c in _customAllergens) {
      _allAllergens[c.id] = c;
    }

    _selectedAllergenIds = _storageService.loadSelectedAllergenIds();
    _isLoading = false;
    notifyListeners();
  }

  bool isSelected(String id) {
    return _selectedAllergenIds.contains(id);
  }

  void toggleAllergen(String id) {
    if (_selectedAllergenIds.contains(id)) {
      _selectedAllergenIds.remove(id);
    } else {
      _selectedAllergenIds.add(id);
    }
    _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
    notifyListeners();
  }

  void addCustomAllergen(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;

    final id = 'custom_${clean.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    if (_allAllergens.containsKey(id)) return;

    final custom = AllergenDef(
      id: id,
      label: clean,
      subtitle: 'Khusus',
      icon: 'shield',
      keywords: [clean.toLowerCase()],
      isCustom: true,
    );

    _customAllergens.add(custom);
    _allAllergens[id] = custom;
    _selectedAllergenIds.add(id);

    _storageService.saveCustomAllergens(_customAllergens);
    _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
    notifyListeners();
  }

  void removeCustomAllergen(String id) {
    _customAllergens.removeWhere((a) => a.id == id);
    _allAllergens.remove(id);
    _selectedAllergenIds.remove(id);

    _storageService.saveCustomAllergens(_customAllergens);
    _storageService.saveSelectedAllergenIds(_selectedAllergenIds);
    notifyListeners();
  }
}
