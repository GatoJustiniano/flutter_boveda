import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../providers/vault_provider.dart';
import '../models/vault_models.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final filteredCategories = _searchQuery.isEmpty
        ? vault.categories
        : vault.categories.where((cat) {
            final nameMatch = cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final entryMatch = cat.entries.any((e) =>
                e.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                e.value.toLowerCase().contains(_searchQuery.toLowerCase()));
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
                  onCopy: (value, label) => _copyToClipboard(value, label),
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

  void _copyToClipboard(String value, String label) {
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $label no tiene valor para copiar'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $label copiado al portapapeles'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppTheme.accentBlue,
          onPressed: () {},
        ),
      ),
    );
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
    final result = await showEntryDialog(context, entry: entry);
    if (result != null && mounted) {
      VaultProvider.of(context).updateEntry(
        category.id,
        entry.id,
        label: result.label,
        value: result.value,
      );
    }
  }

  void _confirmDeleteEntry(Category category, AccountEntry entry) async {
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
