import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import 'secure_store.dart';

/// Resultado de verificar un PIN.
class PinResult {
  final bool ok;

  /// Si el PIN está bloqueado por demasiados intentos, hasta cuándo.
  final DateTime? lockedUntil;
  final int attemptsLeft;

  const PinResult({required this.ok, this.lockedUntil, this.attemptsLeft = 0});
}

/// Maneja el PIN (guardado como hash PBKDF2 con sal), la huella/rostro,
/// el bloqueo por intentos fallidos y la "sesión desbloqueada".
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const int maxAttemptsBeforeLock = 5;
  static const int _pbkdf2Iterations = 60000;

  /// Tras autenticarse, las cuentas protegidas quedan accesibles este tiempo
  /// (para copiar correo y contraseña seguidos sin pedir PIN dos veces).
  static const Duration unlockWindow = Duration(seconds: 60);

  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _unlockedUntil;

  bool get isUnlocked =>
      _unlockedUntil != null && DateTime.now().isBefore(_unlockedUntil!);

  void markUnlocked() => _unlockedUntil = DateTime.now().add(unlockWindow);

  /// Se llama al salir de la app o al tocar "Bloquear ahora".
  void lock() => _unlockedUntil = null;

  // ---------------------------------------------------------------- PIN

  Future<bool> hasPin() async =>
      (await secureStore.read(key: StoreKeys.pinHash)) != null;

  Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    final hash = await _derive(pin, salt);
    await secureStore.write(key: StoreKeys.pinSalt, value: base64Encode(salt));
    await secureStore.write(key: StoreKeys.pinHash, value: base64Encode(hash));
    await _resetAttempts();
  }

  Future<DateTime?> lockedUntil() async {
    final raw = await secureStore.read(key: StoreKeys.lockedUntil);
    if (raw == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
    return DateTime.now().isBefore(until) ? until : null;
  }

  Future<PinResult> verifyPin(String pin) async {
    final locked = await lockedUntil();
    if (locked != null) return PinResult(ok: false, lockedUntil: locked);

    final saltB64 = await secureStore.read(key: StoreKeys.pinSalt);
    final hashB64 = await secureStore.read(key: StoreKeys.pinHash);
    if (saltB64 == null || hashB64 == null) return const PinResult(ok: false);

    final computed = await _derive(pin, base64Decode(saltB64));
    if (_constantTimeEquals(computed, base64Decode(hashB64))) {
      await _resetAttempts();
      markUnlocked();
      return const PinResult(ok: true);
    }

    // Intento fallido: a partir del 5º, bloqueo exponencial (30 s, 60 s, 2 min… máx 1 h).
    final failed =
        int.parse(await secureStore.read(key: StoreKeys.failedAttempts) ?? '0') + 1;
    await secureStore.write(key: StoreKeys.failedAttempts, value: '$failed');
    if (failed >= maxAttemptsBeforeLock) {
      final exp = min(failed - maxAttemptsBeforeLock, 7);
      final until = DateTime.now().add(Duration(seconds: 30 * (1 << exp)));
      await secureStore.write(
          key: StoreKeys.lockedUntil, value: '${until.millisecondsSinceEpoch}');
      return PinResult(ok: false, lockedUntil: until);
    }
    return PinResult(ok: false, attemptsLeft: maxAttemptsBeforeLock - failed);
  }

  Future<void> _resetAttempts() async {
    await secureStore.delete(key: StoreKeys.failedAttempts);
    await secureStore.delete(key: StoreKeys.lockedUntil);
  }

  static Future<Uint8List> _derive(String pin, List<int> salt) {
    // Se calcula en otro isolate para no congelar la interfaz.
    return Isolate.run(() => _pbkdf2(utf8.encode(pin), salt, _pbkdf2Iterations));
  }

  /// PBKDF2-HMAC-SHA256, 32 bytes de salida.
  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  // ---------------------------------------------------------- Biometría

  Future<bool> canUseBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported() &&
          await _localAuth.canCheckBiometrics &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> biometricsEnabled() async =>
      (await secureStore.read(key: StoreKeys.biometricsEnabled)) == 'true';

  Future<void> setBiometricsEnabled(bool enabled) => secureStore.write(
      key: StoreKeys.biometricsEnabled, value: enabled ? 'true' : 'false');

  /// Pide huella/rostro. Solo biometría (no el patrón del teléfono),
  /// para que el PIN de la bóveda siga siendo el respaldo.
  Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      if (ok) markUnlocked();
      return ok;
    } catch (_) {
      return false;
    }
  }
}
