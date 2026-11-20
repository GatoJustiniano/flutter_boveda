import 'package:material_ui/material_ui.dart';
import '../models/vault_models.dart';
import '../theme/app_theme.dart';

Future<Category?> showCategoryDialog(BuildContext context, {Category? category}) async {
  final isEditing = category != null;
  final nameController = TextEditingController(text: category?.name ?? '');
  int selectedIconIndex = category?.iconIndex ?? 0;
  int selectedColorIndex = category?.colorIndex ?? 0;

  return showDialog<Category>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej: Servicios Básicos',
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Color',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(AppTheme.categoryColors.length, (index) {
                      final color = AppTheme.categoryColors[index];
                      final isSelected = selectedColorIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColorIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Icono',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(AppTheme.categoryIcons.length, (index) {
                      final icon = AppTheme.categoryIcons[index];
                      final isSelected = selectedIconIndex == index;
                      final color = AppTheme.categoryColors[selectedColorIndex];
                      return GestureDetector(
                        onTap: () => setState(() => selectedIconIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : AppTheme.secondaryDark,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: color, width: 2)
                                : Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected ? color : AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    context,
                    Category(
                      id: category?.id,
                      name: name,
                      iconIndex: selectedIconIndex,
                      colorIndex: selectedColorIndex,
                      entries: category?.entries,
                    ),
                  );
                },
                child: Text(isEditing ? 'Guardar' : 'Crear'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<AccountEntry?> showEntryDialog(BuildContext context, {AccountEntry? entry}) async {
  final isEditing = entry != null;
  final labelController = TextEditingController(text: entry?.label ?? '');
  final valueController = TextEditingController(text: entry?.value ?? '');

  return showDialog<AccountEntry>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(isEditing ? 'Editar Cuenta' : 'Nueva Cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre / Etiqueta',
                hintText: 'Ej: CRE, Netflix, Correo...',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Valor / Número / Correo',
                hintText: 'Ej: 670942, correo@mail.com',
                prefixIcon: Icon(Icons.content_copy_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final label = labelController.text.trim();
              if (label.isEmpty) return;
              Navigator.pop(
                context,
                AccountEntry(
                  id: entry?.id,
                  label: label,
                  value: valueController.text.trim(),
                ),
              );
            },
            child: Text(isEditing ? 'Guardar' : 'Agregar'),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentRed),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
