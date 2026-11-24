import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../services/app_lock.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Cubre toda la app mientras está bloqueada. Se coloca en MaterialApp.builder,
/// por encima del Navigator, así nada de la bóveda queda visible ni accesible.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  final _lock = AppLockController.instance;

  @override
  void initState() {
    super.initState();
    _lock.addListener(_onChange);
    _lock.init();
  }

  @override
  void dispose() {
    _lock.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _lock.state == AppLockState.unlocked;
    return Stack(
      children: [
        // Offstage conserva el estado de la app pero no la dibuja.
        Offstage(offstage: !unlocked, child: widget.child),
        if (!unlocked)
          Positioned.fill(
            child: switch (_lock.state) {
              AppLockState.loading => const ColoredBox(color: AppTheme.primaryDark),
              AppLockState.setup => const _SetupView(),
              _ => const _UnlockView(),
            },
          ),
      ],
    );
  }
}

// ------------------------------------------------------------- Desbloqueo

class _UnlockView extends StatefulWidget {
  const _UnlockView();

  @override
  State<_UnlockView> createState() => _UnlockViewState();
}

class _UnlockViewState extends State<_UnlockView> with WidgetsBindingObserver {
  final _auth = AuthService.instance;
  String _pin = '';
  String? _error;
  bool _busy = false;
  bool _bioAvailable = false;
  DateTime? _lockedUntil;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepare();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app, pedir huella automáticamente.
    if (state == AppLifecycleState.resumed && !_auth.authInProgress) _tryBiometrics();
  }

  Future<void> _prepare() async {
    _bioAvailable = await _auth.biometricsEnabled() && await _auth.canUseBiometrics();
    _setLockedUntil(await _auth.lockedUntil());
    if (mounted) setState(() {});
    // Si se bloqueó al pasar a segundo plano, la huella se pide al volver (resumed).
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _tryBiometrics();
    }
  }

  Future<void> _tryBiometrics() async {
    if (!_bioAvailable || _busy || !mounted || _auth.authInProgress) return;
    if (await _auth.authenticateWithBiometrics('Desbloquear Bóveda')) {
      AppLockController.instance.unlock();
    }
  }

  void _setLockedUntil(DateTime? until) {
    _lockedUntil = until;
    _ticker?.cancel();
    if (until == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (DateTime.now().isAfter(until)) {
        t.cancel();
        _lockedUntil = null;
        _error = null;
      }
      setState(() {});
    });
  }

  Future<void> _submit() async {
    if (_pin.isEmpty || _busy || _lockedUntil != null) return;
    setState(() => _busy = true);
    final r = await _auth.verifyPin(_pin);
    if (!mounted) return;
    if (r.ok) {
      AppLockController.instance.unlock();
      return;
    }
    setState(() {
      _busy = false;
      _pin = '';
      _error = r.lockedUntil == null
          ? 'PIN incorrecto. Te quedan ${r.attemptsLeft} intentos.'
          : null;
      _setLockedUntil(r.lockedUntil);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = _lockedUntil != null;
    final message = locked
        ? 'Demasiados intentos. Espera '
            '${_lockedUntil!.difference(DateTime.now()).inSeconds + 1} s.'
        : _error;
    return _LockScaffold(
      title: 'Bóveda bloqueada',
      subtitle: _bioAvailable ? 'Usa tu huella o ingresa tu PIN' : 'Ingresa tu PIN',
      pin: _pin,
      message: message,
      messageColor: locked ? AppTheme.accentOrange : AppTheme.accentRed,
      busy: _busy,
      enabled: !locked,
      onDigit: (d) => setState(() {
        if (_pin.length < 8) _pin += d;
        _error = null;
      }),
      onBackspace: () => setState(() {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }),
      onSubmit: _submit,
      submitLabel: 'Desbloquear',
      onBiometrics: _bioAvailable ? _tryBiometrics : null,
    );
  }
}

// ---------------------------------------------------- Primera configuración

class _SetupView extends StatefulWidget {
  const _SetupView();

  @override
  State<_SetupView> createState() => _SetupViewState();
}

enum _SetupStep { create, confirm, biometrics }

class _SetupViewState extends State<_SetupView> {
  final _auth = AuthService.instance;
  _SetupStep _step = _SetupStep.create;
  String _first = '';
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    if (_step == _SetupStep.create) {
      if (_pin.length < 4) {
        setState(() => _error = 'Usa al menos 4 dígitos');
        return;
      }
      setState(() {
        _first = _pin;
        _pin = '';
        _error = null;
        _step = _SetupStep.confirm;
      });
      return;
    }
    if (_pin != _first) {
      setState(() {
        _pin = '';
        _first = '';
        _error = 'Los PIN no coinciden. Vuelve a empezar.';
        _step = _SetupStep.create;
      });
      return;
    }
    setState(() => _busy = true);
    await _auth.setPin(_pin);
    if (!mounted) return;
    if (await _auth.canUseBiometrics()) {
      setState(() {
        _busy = false;
        _step = _SetupStep.biometrics;
      });
    } else {
      AppLockController.instance.unlock();
    }
  }

  Future<void> _enableBiometrics() async {
    if (await _auth.authenticateWithBiometrics('Confirma tu huella')) {
      await _auth.setBiometricsEnabled(true);
      AppLockController.instance.unlock();
    } else if (mounted) {
      setState(() => _error = 'No se pudo verificar la huella. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _SetupStep.biometrics) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fingerprint_rounded, size: 96, color: AppTheme.accentBlue),
                const SizedBox(height: 24),
                const Text('¿Entrar con huella?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text(
                  'Se pedirá tu huella cada vez que abras la app. '
                  'El PIN queda como respaldo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.accentRed)),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _enableBiometrics,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Activar huella'),
                ),
                TextButton(
                  onPressed: () => AppLockController.instance.unlock(),
                  child: const Text('Ahora no, usar solo PIN'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final creating = _step == _SetupStep.create;
    return _LockScaffold(
      title: creating ? 'Crea tu PIN' : 'Confirma tu PIN',
      subtitle: creating
          ? 'De 4 a 8 dígitos. Protege la entrada a la app.\nSi lo olvidas no se puede recuperar.'
          : 'Ingrésalo otra vez',
      pin: _pin,
      message: _error,
      messageColor: AppTheme.accentRed,
      busy: _busy,
      enabled: true,
      onDigit: (d) => setState(() {
        if (_pin.length < 8) _pin += d;
        _error = null;
      }),
      onBackspace: () => setState(() {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }),
      onSubmit: _submit,
      submitLabel: creating ? 'Siguiente' : 'Guardar',
    );
  }
}

// ------------------------------------------------------- Teclado numérico

/// Teclado propio (sin TextField): no usa el teclado del sistema, así que
/// ningún teclado de terceros puede registrar el PIN.
class _LockScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String pin;
  final String? message;
  final Color messageColor;
  final bool busy;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final String submitLabel;
  final VoidCallback? onBiometrics;

  const _LockScaffold({
    required this.title,
    required this.subtitle,
    required this.pin,
    required this.message,
    required this.messageColor,
    required this.busy,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.submitLabel,
    this.onBiometrics,
  });

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback? onTap, {String? semantics}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Material(
              color: onTap == null ? Colors.transparent : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: enabled && !busy ? onTap : null,
                child: Semantics(label: semantics, child: Center(child: child)),
              ),
            ),
          ),
        ),
      );
    }

    Widget digit(String d) => key(
          Text(d, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
          () => onDigit(d),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.lock_rounded, size: 56, color: AppTheme.accentBlue),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pin.isEmpty ? 4 : pin.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < pin.length ? AppTheme.accentBlue : Colors.transparent,
                            border: Border.all(color: AppTheme.accentBlue, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: message == null
                          ? null
                          : Text(message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: messageColor)),
                    ),
                  ),
                  for (final row in const [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Row(children: [for (final d in row) digit(d)]),
                  Row(children: [
                    onBiometrics == null
                        ? key(const SizedBox(), null)
                        : key(const Icon(Icons.fingerprint_rounded, size: 30),
                            onBiometrics, semantics: 'Usar huella'),
                    digit('0'),
                    key(const Icon(Icons.backspace_outlined), onBackspace,
                        semantics: 'Borrar'),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: enabled && !busy && pin.isNotEmpty ? onSubmit : null,
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
