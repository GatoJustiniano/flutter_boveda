import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

const int _minPinLength = 4;
const int _maxPinLength = 8;

/// Asegura que el usuario está autenticado antes de acceder a una cuenta
/// protegida. Si aún no hay PIN, pide crearlo. Devuelve true si se permite.
Future<bool> ensureUnlocked(BuildContext context, {String? reason}) async {
  final auth = AuthService.instance;
  if (auth.isUnlocked) return true;

  if (!await auth.hasPin()) {
    if (!context.mounted) return false;
    final created = await showCreatePinDialog(context);
    if (created && context.mounted) await _offerBiometrics(context);
    return created;
  }

  if (await auth.biometricsEnabled() && await auth.canUseBiometrics()) {
    if (await auth.authenticateWithBiometrics(
        reason ?? 'Desbloquear cuentas protegidas')) {
      return true;
    }
  }

  if (!context.mounted) return false;
  return showVerifyPinDialog(context);
}

Future<void> _offerBiometrics(BuildContext context) async {
  final auth = AuthService.instance;
  if (!await auth.canUseBiometrics() || !context.mounted) return;
  final use = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Usar huella?'),
      content: const Text(
          'Puedes desbloquear las cuentas protegidas con tu huella o rostro. '
          'El PIN seguirá funcionando como respaldo.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, usar huella')),
      ],
    ),
  );
  await auth.setBiometricsEnabled(use ?? false);
}

/// Crear (o cambiar) el PIN. Devuelve true si se guardó.
Future<bool> showCreatePinDialog(BuildContext context,
    {bool isChange = false}) async {
  final pin = TextEditingController();
  final confirm = TextEditingController();
  String? error;
  bool saving = false;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> submit() async {
          if (pin.text.length < _minPinLength) {
            setState(() => error = 'Usa al menos $_minPinLength dígitos');
            return;
          }
          if (pin.text != confirm.text) {
            setState(() => error = 'Los PIN no coinciden');
            return;
          }
          setState(() => saving = true);
          await AuthService.instance.setPin(pin.text);
          AuthService.instance.markUnlocked();
          if (context.mounted) Navigator.pop(context, true);
        }

        return AlertDialog(
          title: Text(isChange ? 'Nuevo PIN' : 'Crea un PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isChange)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Este PIN protege tus cuentas marcadas como protegidas. '
                    'Si lo olvidas no se puede recuperar.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              _pinField(pin, 'PIN', autofocus: true),
              const SizedBox(height: 12),
              _pinField(confirm, 'Confirmar PIN', onSubmitted: (_) => submit()),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!,
                      style: const TextStyle(color: AppTheme.accentRed)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving ? null : submit,
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
  return result ?? false;
}

/// Pide el PIN actual. Devuelve true si es correcto.
Future<bool> showVerifyPinDialog(BuildContext context,
    {String title = 'Ingresa tu PIN'}) async {
  final pin = TextEditingController();
  String? error;
  bool checking = false;
  DateTime? lockedUntil = await AuthService.instance.lockedUntil();
  Timer? ticker;

  if (!context.mounted) return false;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void startTicker() {
          ticker?.cancel();
          ticker = Timer.periodic(const Duration(seconds: 1), (t) {
            if (!context.mounted) return t.cancel();
            if (lockedUntil == null || DateTime.now().isAfter(lockedUntil!)) {
              t.cancel();
              setState(() {
                lockedUntil = null;
                error = null;
              });
            } else {
              setState(() {});
            }
          });
        }

        if (lockedUntil != null && ticker == null) startTicker();

        Future<void> submit() async {
          if (pin.text.isEmpty || checking || lockedUntil != null) return;
          setState(() => checking = true);
          final r = await AuthService.instance.verifyPin(pin.text);
          if (!context.mounted) return;
          if (r.ok) {
            Navigator.pop(context, true);
            return;
          }
          pin.clear();
          setState(() {
            checking = false;
            lockedUntil = r.lockedUntil;
            error = r.lockedUntil == null
                ? 'PIN incorrecto. Te quedan ${r.attemptsLeft} intentos.'
                : null;
          });
          if (r.lockedUntil != null) startTicker();
        }

        final locked = lockedUntil != null;
        final secondsLeft =
            locked ? lockedUntil!.difference(DateTime.now()).inSeconds + 1 : 0;

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinField(pin, 'PIN',
                  autofocus: true, enabled: !locked, onSubmitted: (_) => submit()),
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Demasiados intentos. Espera $secondsLeft s.',
                    style: const TextStyle(color: AppTheme.accentOrange),
                  ),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!,
                      style: const TextStyle(color: AppTheme.accentRed)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: locked || checking ? null : submit,
              child: checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Desbloquear'),
            ),
          ],
        );
      },
    ),
  );
  ticker?.cancel();
  return result ?? false;
}

Widget _pinField(
  TextEditingController controller,
  String label, {
  bool autofocus = false,
  bool enabled = true,
  ValueChanged<String>? onSubmitted,
}) {
  return TextField(
    controller: controller,
    autofocus: autofocus,
    enabled: enabled,
    obscureText: true,
    keyboardType: TextInputType.number,
    maxLength: _maxPinLength,
    enableSuggestions: false,
    autocorrect: false,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      prefixIcon: const Icon(Icons.pin_rounded),
    ),
  );
}
