import 'dart:convert';
import 'package:uuid/uuid.dart';

class AccountEntry {
  final String id;
  String label;
  String value;

  AccountEntry({
    String? id,
    required this.label,
    required this.value,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
      };

  factory AccountEntry.fromJson(Map<String, dynamic> json) => AccountEntry(
        id: json['id'] as String,
        label: json['label'] as String,
        value: json['value'] as String,
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

  factory VaultData.withDefaults() {
    return VaultData(
      categories: [
        Category(
          name: 'Servicios Básicos',
          iconIndex: 0,
          colorIndex: 0,
          entries: [
            AccountEntry(label: 'CRE', value: '670942'),
            AccountEntry(label: 'SAGUAPAC', value: '270709600'),
            AccountEntry(label: 'ENTEL', value: ''),
          ],
        ),
        Category(
          name: 'Suscripciones',
          iconIndex: 6,
          colorIndex: 4,
          entries: [
            AccountEntry(label: 'Netflix', value: 'correo@ejemplo.com'),
            AccountEntry(label: 'Spotify', value: 'correo@ejemplo.com'),
          ],
        ),
        Category(
          name: 'Cuentas Bancarias',
          iconIndex: 5,
          colorIndex: 1,
          entries: [
            AccountEntry(label: 'Banco Ejemplo', value: '1234567890'),
          ],
        ),
      ],
    );
  }
}
