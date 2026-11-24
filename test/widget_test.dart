import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boveda/main.dart';
import 'package:boveda/models/vault_models.dart';
import 'package:boveda/providers/vault_provider.dart';
import 'package:boveda/services/app_lock.dart';
import 'package:boveda/services/auth_service.dart';
import 'package:boveda/services/secure_store.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('First launch: intro, then create PIN, then empty suggested categories',
      (WidgetTester tester) async {
    AppLockController.instance.debugReset();
    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a tu Bóveda'), findsOneWidget);
    // La app está oculta detrás de la introducción/bloqueo.
    expect(find.text('🔐 Bóveda de Cuentas'), findsNothing);

    // Recorre la introducción hasta el final.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Solo tú puedes entrar'), findsOneWidget);
    await tester.tap(find.text('Crear mi PIN'));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu PIN'), findsOneWidget);

    // La introducción no vuelve a aparecer en el siguiente arranque.
    AppLockController.instance.debugReset();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a tu Bóveda'), findsNothing);
    expect(find.text('Crea tu PIN'), findsOneWidget);

    AppLockController.instance.debugSetState(AppLockState.unlocked);
    await tester.pumpAndSettle();
    expect(find.text('🔐 Bóveda de Cuentas'), findsOneWidget);
    expect(find.text('Servicios Básicos'), findsOneWidget);
    expect(find.text('Suscripciones'), findsOneWidget);
    expect(find.text('Cuentas Bancarias'), findsOneWidget);
    // Sin datos personales: todas las categorías vacías.
    expect(find.text('Sin cuentas aún'), findsNWidgets(3));
  });

  testWidgets('With a PIN set, the app opens locked', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({StoreKeys.pinHash: 'x', StoreKeys.pinSalt: 'x'});
    AppLockController.instance.debugReset();
    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();

    expect(find.text('Bóveda bloqueada'), findsOneWidget);
    expect(find.text('🔐 Bóveda de Cuentas'), findsNothing);
  });

  testWidgets('Subscription passwords and protected values are masked',
      (WidgetTester tester) async {
    final data = VaultData(categories: [
      Category(name: 'Suscripciones', entries: [
        AccountEntry(
          label: 'Netflix',
          value: 'yo@mail.com',
          type: EntryType.subscription,
          password: 'superSecreta',
        ),
        AccountEntry(label: 'PIN tarjeta', value: '9876', isSecret: true),
      ]),
    ]);
    FlutterSecureStorage.setMockInitialValues({StoreKeys.vault: data.toJsonString()});
    AppLockController.instance.debugSetState(AppLockState.unlocked);

    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();

    expect(find.text('yo@mail.com'), findsOneWidget);
    expect(find.text('superSecreta'), findsNothing);
    expect(find.text('9876'), findsNothing);
    expect(find.text('••••••••'), findsNWidgets(2));
  });

  test('Subscription entries round-trip through JSON', () {
    final e = AccountEntry(
        label: 'Spotify', value: 'a@b.com', type: EntryType.subscription, password: 'p w');
    final back = AccountEntry.fromJson(e.toJson());
    expect(back.isSubscription, isTrue);
    expect(back.password, 'p w');
    expect(back.requiresAuth, isTrue);
    // Datos guardados por la versión anterior (sin "type") siguen funcionando.
    final old = AccountEntry.fromJson({'id': '1', 'label': 'CRE', 'value': '1'});
    expect(old.type, EntryType.account);
    expect(old.requiresAuth, isFalse);
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
