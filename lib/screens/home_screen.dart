import 'package:material_ui/material_ui.dart';
import '../providers/vault_provider.dart';
import '../models/vault_models.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/pin_dialogs.dart';
import '../services/auth_service.dart';
import '../services/secure_clipboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al salir de la app, las cuentas protegidas vuelven a bloquearse.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      AuthService.instance.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = VaultProvider.of(context);

    if (!vault.isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (vault.loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo abrir la bóveda cifrada.\n\n${vault.loadError}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ),
      );
    }

    final filteredCategories = _searchQuery.isEmpty
        ? vault.categories
        : vault.categories.where((cat) {
            final nameMatch = cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final entryMatch = cat.entries.any((e) =>
                e.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (!e.isSecret &&
                    e.value.toLowerCase().contains(_searchQuery.toLowerCase())));
            return nameMatch || entryMatch;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Buscar cuenta o servicio...',
                  border: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('🔐 Bóveda de Cuentas'),
        actions: [
          if (!_isSearching) _buildSecurityMenu(),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: filteredCategories.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 100),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                return CategoryCard(
                  category: category,
                  onCopy: (entry) => _copyEntry(entry),
                  onEditCategory: () => _showEditCategoryDialog(category),
                  onDeleteCategory: () => _confirmDeleteCategory(category),
                  onAddEntry: () => _showAddEntryDialog(category),
                  onEditEntry: (entry) => _showEditEntryDialog(category, entry),
                  onDeleteEntry: (entry) => _confirmDeleteEntry(category, entry),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Categoría'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron resultados'
                : 'Tu bóveda está vacía',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Intenta con otra búsqueda'
                : 'Agrega una categoría para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.shield_outlined),
      tooltip: 'Seguridad',
      onSelected: (value) async {
        switch (value) {
          case 'lock':
            AuthService.instance.lock();
            setState(() {});
            _showSnack('🔒 Cuentas protegidas bloqueadas');
          case 'pin':
            await _changePin();
          case 'bio':
            await _toggleBiometrics();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'lock',
          child: ListTile(
            leading: Icon(Icons.lock_rounded),
            title: Text('Bloquear ahora'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          child: ListTile(
            leading: Icon(Icons.pin_rounded),
            title: Text('Crear / cambiar PIN'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'bio',
          child: ListTile(
            leading: Icon(Icons.fingerprint_rounded),
            title: Text('Huella / rostro'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _changePin() async {
    final auth = AuthService.instance;
    if (await auth.hasPin()) {
      if (!mounted) return;
      // Para cambiar el PIN siempre se pide el PIN actual (no basta la huella).
      if (!await showVerifyPinDialog(context, title: 'PIN actual')) return;
    }
    if (!mounted) return;
    if (await showCreatePinDialog(context, isChange: true)) {
      _showSnack('✅ PIN guardado');
    }
  }

  Future<void> _toggleBiometrics() async {
    final auth = AuthService.instance;
    if (!await auth.canUseBiometrics()) {
      _showSnack('Este teléfono no tiene huella/rostro configurado');
      return;
    }
    if (!await auth.hasPin()) {
      _showSnack('Primero crea un PIN');
      return;
    }
    final enabled = await auth.biometricsEnabled();
    if (enabled) {
      await auth.setBiometricsEnabled(false);
      _showSnack('Huella desactivada: se pedirá el PIN');
      return;
    }
    if (!mounted) return;
    if (!await showVerifyPinDialog(context)) return;
    if (await auth.authenticateWithBiometrics('Confirma tu huella')) {
      await auth.setBiometricsEnabled(true);
      _showSnack('✅ Huella activada');
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _copyEntry(AccountEntry entry) async {
    if (entry.value.isEmpty) {
      _showSnack('⚠️ ${entry.label} no tiene valor para copiar');
      return;
    }
    if (entry.isSecret &&
        !await ensureUnlocked(context, reason: 'Copiar ${entry.label}')) {
      return;
    }
    await SecureClipboard.copy(entry.value, sensitive: entry.isSecret);
    _showSnack(entry.isSecret
        ? '✅ ${entry.label} copiado · se borrará en '
            '${SecureClipboard.secretClearAfter.inSeconds} s'
        : '✅ ${entry.label} copiado al portapapeles');
  }

  void _showAddCategoryDialog() async {
    final result = await showCategoryDialog(context);
    if (result != null && mounted) {
      VaultProvider.of(context).addCategory(result);
    }
  }

  void _showEditCategoryDialog(Category category) async {
    final result = await showCategoryDialog(context, category: category);
    if (result != null && mounted) {
      VaultProvider.of(context).updateCategory(
        category.id,
        name: result.name,
        iconIndex: result.iconIndex,
        colorIndex: result.colorIndex,
      );
    }
  }

  void _confirmDeleteCategory(Category category) async {
    if (category.entries.any((e) => e.isSecret) &&
        !await ensureUnlocked(context, reason: 'Eliminar ${category.name}')) {
      return;
    }
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar Categoría',
      message: '¿Estás seguro de eliminar "${category.name}" y todas sus cuentas?',
    );
    if (confirmed && mounted) {
      VaultProvider.of(context).deleteCategory(category.id);
    }
  }

  void _showAddEntryDialog(Category category) async {
    final result = await showEntryDialog(context);
    if (result != null && mounted) {
      VaultProvider.of(context).addEntry(category.id, result);
    }
  }

  void _showEditEntryDialog(Category category, AccountEntry entry) async {
    if (entry.isSecret &&
        !await ensureUnlocked(context, reason: 'Editar ${entry.label}')) {
      return;
    }
    if (!mounted) return;
    final result = await showEntryDialog(context, entry: entry);
    if (result != null && mounted) {
      VaultProvider.of(context).updateEntry(
        category.id,
        entry.id,
        label: result.label,
        value: result.value,
        isSecret: result.isSecret,
      );
    }
  }

  void _confirmDeleteEntry(Category category, AccountEntry entry) async {
    if (entry.isSecret &&
        !await ensureUnlocked(context, reason: 'Eliminar ${entry.label}')) {
      return;
    }
    if (!mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar Cuenta',
      message: '¿Estás seguro de eliminar "${entry.label}"?',
    );
    if (confirmed && mounted) {
      VaultProvider.of(context).deleteEntry(category.id, entry.id);
    }
  }
}
