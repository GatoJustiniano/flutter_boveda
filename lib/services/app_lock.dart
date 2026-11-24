import 'package:flutter/widgets.dart';

import '../screens/intro_screen.dart';
import 'auth_service.dart';

enum AppLockState { loading, intro, setup, locked, unlocked }

/// Bloqueo de toda la app: al abrirla y cada vez que vuelve de segundo plano
/// se exige huella (o el PIN como respaldo).
class AppLockController extends ChangeNotifier with WidgetsBindingObserver {
  AppLockController._();
  static final AppLockController instance = AppLockController._();

  AppLockState _state = AppLockState.loading;
  AppLockState get state => _state;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    if (await AuthService.instance.hasPin()) {
      _set(AppLockState.locked);
    } else {
      _set(await IntroView.wasSeen() ? AppLockState.setup : AppLockState.intro);
    }
  }

  /// Fin de la introducción del primer uso: pasa a crear el PIN.
  Future<void> finishIntro() async {
    await IntroView.markSeen();
    _set(AppLockState.setup);
  }

  void unlock() {
    AuthService.instance.markUnlocked();
    _set(AppLockState.unlocked);
  }

  void lockNow() {
    AuthService.instance.lock();
    if (_state == AppLockState.unlocked) _set(AppLockState.locked);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El diálogo de huella puede pausar la app un instante: no bloquear por eso.
    if (AuthService.instance.authInProgress) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      lockNow();
    }
  }

  void _set(AppLockState s) {
    _state = s;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetState(AppLockState s) {
    _initialized = true;
    _set(s);
  }

  @visibleForTesting
  void debugReset() {
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
    _state = AppLockState.loading;
  }
}
