import 'dart:convert';
import 'package:uuid/uuid.dart';

/// account: un solo valor (número de cuenta, código de cliente…).
/// subscription: correo + contraseña (la contraseña siempre está protegida).
enum EntryType { account, subscription }

class AccountEntry {
  final String id;
  String label;
  String value;

  /// Si es true, el valor se oculta y se requiere PIN/huella para verlo,
  /// copiarlo o editarlo.
  bool isSecret;

  EntryType type;

  /// Solo para suscripciones. Siempre se trata como protegida.
  String password;

  AccountEntry({
    String? id,
    required this.label,
    required this.value,
    this.isSecret = false,
    this.type = EntryType.account,
    this.password = '',
  }) : id = id ?? const Uuid().v4();

  bool get isSubscription => type == EntryType.subscription;

  /// Ver, editar o borrar esta cuenta requiere PIN/huella.
  bool get requiresAuth => isSecret || isSubscription;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
        'secret': isSecret,
        'type': type.name,
        if (password.isNotEmpty) 'password': password,
      };

  factory AccountEntry.fromJson(Map<String, dynamic> json) => AccountEntry(
        id: json['id'] as String,
        label: json['label'] as String,
        value: json['value'] as String,
        isSecret: json['secret'] as bool? ?? false,
        type: EntryType.values.asNameMap()[json['type']] ?? EntryType.account,
        password: json['password'] as String? ?? '',
      );
}

class Category {
  final String id;
  String name;
  int iconIndex;
  int colorIndex;
  List<AccountEntry> entries;

  Category({
    String? id,
    required this.name,
    this.iconIndex = 0,
    this.colorIndex = 0,
    List<AccountEntry>? entries,
  })  : id = id ?? const Uuid().v4(),
        entries = entries ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconIndex': iconIndex,
        'colorIndex': colorIndex,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        iconIndex: json['iconIndex'] as int? ?? 0,
        colorIndex: json['colorIndex'] as int? ?? 0,
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) => AccountEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class VaultData {
  List<Category> categories;

  VaultData({List<Category>? categories}) : categories = categories ?? [];

  String toJsonString() => jsonEncode(categories.map((c) => c.toJson()).toList());

  factory VaultData.fromJsonString(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return VaultData(
      categories: list
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Primera ejecución: la app arranca sin datos personales.
  ///
  /// Se crean categorías sugeridas SIN cuentas, como guía para empezar.
  /// No colocar datos reales aquí: este archivo forma parte del repositorio.
  factory VaultData.withDefaults() => VaultData(categories: [
        Category(name: 'Servicios Básicos', iconIndex: 0, colorIndex: 0),
        Category(name: 'Suscripciones', iconIndex: 6, colorIndex: 4),
        Category(name: 'Cuentas Bancarias', iconIndex: 5, colorIndex: 2),
      ]);
}
