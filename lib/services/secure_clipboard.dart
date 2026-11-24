import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Copia valores al portapapeles. Los valores protegidos se marcan como
/// "sensibles" (Android 13+ no los muestra en la vista previa ni en el teclado)
/// y se borran automáticamente pasado [secretClearAfter].
class SecureClipboard {
  static const Duration secretClearAfter = Duration(seconds: 30);
  static const MethodChannel _channel = MethodChannel('boveda/clipboard');
  static Timer? _fallbackTimer;

  static Future<void> copy(String text, {required bool sensitive}) async {
    if (!sensitive) {
      await Clipboard.setData(ClipboardData(text: text));
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _channel.invokeMethod('copySensitive', {
          'text': text,
          'clearAfterMs': secretClearAfter.inMilliseconds,
        });
        return;
      } on MissingPluginException {
        // Sin canal nativo (p. ej. pruebas): usar la ruta genérica.
      }
    }

    await Clipboard.setData(ClipboardData(text: text));
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(secretClearAfter, () async {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }
}
