import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boveda/main.dart';
import 'package:boveda/models/vault_models.dart';
import 'package:boveda/providers/vault_provider.dart';
import 'package:boveda/services/auth_service.dart';
import 'package:boveda/services/secure_store.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();

    expect(find.text('🔐 Bóveda de Cuentas'), findsOneWidget);
  });

  testWidgets('Protected values are masked', (WidgetTester tester) async {
    final data = VaultData(categories: [
      Category(name: 'Subs', entries: [
        AccountEntry(label: 'Netflix - correo', value: 'yo@mail.com'),
        AccountEntry(label: 'Netflix - clave', value: 'superSecreta', isSecret: true),
      ]),
    ]);
    FlutterSecureStorage.setMockInitialValues({StoreKeys.vault: data.toJsonString()});

    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();

    expect(find.text('yo@mail.com'), findsOneWidget);
    expect(find.text('superSecreta'), findsNothing);
    expect(find.text('••••••••'), findsOneWidget);
  });

  test('Legacy SharedPreferences data is migrated and removed', () async {
    final legacy = VaultData(categories: [
      Category(name: 'Servicios', entries: [AccountEntry(label: 'Luz', value: '123')]),
    ]).toJsonString();
    SharedPreferences.setMockInitialValues({'vault_data': legacy});

    final state = VaultState();
    await state.load();

    expect(state.loadError, isNull);
    expect(state.categories.single.entries.single.value, '123');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('vault_data'), isNull);
    expect(await secureStore.read(key: StoreKeys.vault), contains('123'));
  });

  test('PIN verification, wrong attempts and lockout', () async {
    final auth = AuthService.instance;
    auth.lock();
    await auth.setPin('4821');
    expect(await auth.hasPin(), isTrue);
    expect(await secureStore.read(key: StoreKeys.pinHash), isNot(contains('4821')));

    expect((await auth.verifyPin('0000')).ok, isFalse);
    expect((await auth.verifyPin('4821')).ok, isTrue);
    expect(auth.isUnlocked, isTrue);

    PinResult r = const PinResult(ok: false);
    for (var i = 0; i < AuthService.maxAttemptsBeforeLock; i++) {
      r = await auth.verifyPin('1111');
    }
    expect(r.lockedUntil, isNotNull);
    // Bloqueado: ni siquiera el PIN correcto funciona.
    expect((await auth.verifyPin('4821')).ok, isFalse);
  });
}
