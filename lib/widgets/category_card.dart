import 'dart:async';

import 'package:material_ui/material_ui.dart';
import '../models/vault_models.dart';
import '../theme/app_theme.dart';
import 'pin_dialogs.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  /// password: true copia la contraseña de una suscripción.
  final void Function(AccountEntry entry, bool password) onCopy;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onAddEntry;
  final void Function(AccountEntry entry) onEditEntry;
  final void Function(AccountEntry entry) onDeleteEntry;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onCopy,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddEntry,
    required this.onEditEntry,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getCategoryColor(category.colorIndex);
    final icon = AppTheme.categoryIcons[category.iconIndex % AppTheme.categoryIcons.length];

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEditCategory();
                        break;
                      case 'add':
                        onAddEntry();
                        break;
                      case 'delete':
                        onDeleteCategory();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Agregar cuenta'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Editar categoría'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, size: 20, color: AppTheme.accentRed),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: AppTheme.accentRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entries
          if (category.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Sin cuentas aún',
                      style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: onAddEntry,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Agregar'),
                      style: TextButton.styleFrom(foregroundColor: color),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.entries.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppTheme.dividerColor,
              ),
              itemBuilder: (context, index) {
                final entry = category.entries[index];
                return _EntryTile(
                  entry: entry,
                  color: color,
                  onCopy: (password) => onCopy(entry, password),
                  onEdit: () => onEditEntry(entry),
                  onDelete: () => onDeleteEntry(entry),
                );
              },
            ),

          // Add entry button at bottom
          if (category.entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Center(
                child: TextButton.icon(
                  onPressed: onAddEntry,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Agregar cuenta', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatefulWidget {
  final AccountEntry entry;
  final Color color;
  final void Function(bool password) onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.color,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  static const _revealFor = Duration(seconds: 15);
  static const _mask = '••••••••';
  bool _revealed = false;
  Timer? _hideTimer;

  AccountEntry get entry => widget.entry;
  Color get color => widget.color;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleReveal() async {
    if (_revealed) {
      _hide();
      return;
    }
    if (!await ensureUnlocked(context, reason: 'Ver ${entry.label}')) return;
    if (!mounted) return;
    setState(() => _revealed = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(_revealFor, _hide);
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.onCopy(false),
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(),
            const SizedBox(height: 4),
            if (entry.isSubscription) ...[
              _valueRow(
                icon: Icons.alternate_email_rounded,
                text: entry.value,
                masked: false,
                onCopy: () => widget.onCopy(false),
                fontSize: 15,
              ),
              const SizedBox(height: 6),
              _valueRow(
                icon: Icons.key_rounded,
                text: entry.password,
                masked: !_revealed,
                showEye: true,
                onCopy: () => widget.onCopy(true),
                fontSize: 15,
              ),
            ] else
              _valueRow(
                text: entry.value,
                masked: entry.isSecret && !_revealed,
                showEye: entry.isSecret,
                onCopy: () => widget.onCopy(false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        if (entry.requiresAuth)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.lock_rounded,
                size: 13, color: color.withValues(alpha: 0.9)),
          ),
        Flexible(
          child: Text(
            entry.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _valueRow({
    IconData? icon,
    required String text,
    required bool masked,
    bool showEye = false,
    required VoidCallback onCopy,
    double fontSize = 18,
  }) {
    final empty = text.isEmpty;
    return Row(
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: 16, color: AppTheme.textSecondary),
          ),
        Expanded(
          child: Text(
            empty ? '(sin valor)' : (masked ? _mask : text),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: empty
                  ? AppTheme.textSecondary.withValues(alpha: 0.4)
                  : AppTheme.textPrimary,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (showEye && !empty)
          IconButton(
            tooltip: _revealed ? 'Ocultar' : 'Mostrar',
            onPressed: _toggleReveal,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              _revealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.copy_rounded, color: color, size: 19),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        void run(VoidCallback action) {
          Navigator.pop(sheetContext);
          action();
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    entry.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const Divider(color: AppTheme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: AppTheme.accentBlue),
                  title: Text(entry.isSubscription ? 'Copiar correo' : 'Copiar'),
                  onTap: () => run(() => widget.onCopy(false)),
                ),
                if (entry.isSubscription)
                  ListTile(
                    leading: const Icon(Icons.key_rounded, color: AppTheme.accentBlue),
                    title: const Text('Copiar contraseña'),
                    onTap: () => run(() => widget.onCopy(true)),
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: AppTheme.accentOrange),
                  title: const Text('Editar'),
                  onTap: () => run(widget.onEdit),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: AppTheme.accentRed),
                  title: const Text('Eliminar', style: TextStyle(color: AppTheme.accentRed)),
                  onTap: () => run(widget.onDelete),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
