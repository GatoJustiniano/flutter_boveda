import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vault_models.dart';
import '../services/secure_store.dart';

class VaultState extends ChangeNotifier {
  VaultData _data = VaultData();
  bool _isLoaded = false;
  String? _loadError;

  VaultData get data => _data;
  bool get isLoaded => _isLoaded;

  /// Si no se pudo descifrar/leer la bóveda. En ese caso NO se guarda nada
  /// para no sobrescribir los datos existentes.
  String? get loadError => _loadError;
  List<Category> get categories => _data.categories;

  static const _legacyPrefsKey = 'vault_data';

  Future<void> load() async {
    try {
      final stored = await secureStore.read(key: StoreKeys.vault);
      if (stored != null && stored.isNotEmpty) {
        _data = VaultData.fromJsonString(stored);
      } else {
        // Migración: versiones anteriores guardaban todo en texto plano
        // en SharedPreferences. Se mueve al almacenamiento cifrado y se borra.
        final prefs = await SharedPreferences.getInstance();
        final legacy = prefs.getString(_legacyPrefsKey);
        if (legacy != null && legacy.isNotEmpty) {
          _data = VaultData.fromJsonString(legacy);
          await _save();
          await prefs.remove(_legacyPrefsKey);
        } else {
          _data = VaultData.withDefaults();
          await _save();
        }
      }
    } catch (e) {
      _loadError = e.toString();
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (_loadError != null) return;
    await secureStore.write(key: StoreKeys.vault, value: _data.toJsonString());
  }

  // Category operations
  Future<void> addCategory(Category category) async {
    _data.categories.add(category);
    await _save();
    notifyListeners();
  }

  Future<void> updateCategory(String id, {String? name, int? iconIndex, int? colorIndex}) async {
    final cat = _data.categories.firstWhere((c) => c.id == id);
    if (name != null) cat.name = name;
    if (iconIndex != null) cat.iconIndex = iconIndex;
    if (colorIndex != null) cat.colorIndex = colorIndex;
    await _save();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _data.categories.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _data.categories.removeAt(oldIndex);
    _data.categories.insert(newIndex, item);
    await _save();
    notifyListeners();
  }

  // Entry operations
  Future<void> addEntry(String categoryId, AccountEntry entry) async {
    final cat = _data.categories.firstWhere((c) => c.id == categoryId);
    cat.entries.add(entry);
    await _save();
    notifyListeners();
  }

  Future<void> updateEntry(String categoryId, String entryId,
      {String? label, String? value, bool? isSecret}) async {
    final cat = _data.categories.firstWhere((c) => c.id == categoryId);
    final entry = cat.entries.firstWhere((e) => e.id == entryId);
    if (label != null) entry.label = label;
    if (value != null) entry.value = value;
    if (isSecret != null) entry.isSecret = isSecret;
    await _save();
    notifyListeners();
  }

  Future<void> deleteEntry(String categoryId, String entryId) async {
    final cat = _data.categories.firstWhere((c) => c.id == categoryId);
    cat.entries.removeWhere((e) => e.id == entryId);
    await _save();
    notifyListeners();
  }

  Future<void> reorderEntries(String categoryId, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final cat = _data.categories.firstWhere((c) => c.id == categoryId);
    final item = cat.entries.removeAt(oldIndex);
    cat.entries.insert(newIndex, item);
    await _save();
    notifyListeners();
  }
}

class VaultProvider extends StatefulWidget {
  final Widget child;
  const VaultProvider({super.key, required this.child});

  @override
  State<VaultProvider> createState() => _VaultProviderState();

  static VaultState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_VaultInherited>()!.state;
  }
}

class _VaultProviderState extends State<VaultProvider> {
  final VaultState _state = VaultState();

  @override
  void initState() {
    super.initState();
    _state.load();
    _state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _VaultInherited(
      state: _state,
      child: widget.child,
    );
  }
}

class _VaultInherited extends InheritedWidget {
  final VaultState state;

  const _VaultInherited({required this.state, required super.child});

  @override
  bool updateShouldNotify(_VaultInherited old) => true;
}
