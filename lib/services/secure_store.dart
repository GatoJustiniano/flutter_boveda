import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento cifrado con claves del Android Keystore (Keychain en iOS).
///
/// `resetOnError: false` evita que la librería borre silenciosamente
/// los datos si algo falla al descifrar: preferimos ver el error.
const FlutterSecureStorage secureStore = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: false),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

class StoreKeys {
  static const vault = 'vault_data_v2';
  static const pinHash = 'pin_hash';
  static const pinSalt = 'pin_salt';
  static const failedAttempts = 'pin_failed_attempts';
  static const lockedUntil = 'pin_locked_until';
  static const biometricsEnabled = 'biometrics_enabled';
}
