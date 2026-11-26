package com.gatojustiniano.boveda

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity es requerida por local_auth (huella/rostro).
 */
class MainActivity : FlutterFragmentActivity() {

    private val clipLabel = "boveda-secreto"
    private val handler = Handler(Looper.getMainLooper())
    private var pendingClear: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bloquea capturas de pantalla, grabación de pantalla y oculta la
        // vista previa de la app en "recientes".
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "boveda/clipboard")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copySensitive" -> {
                        val text = call.argument<String>("text") ?: ""
                        val clearAfterMs = (call.argument<Int>("clearAfterMs") ?: 30000).toLong()
                        copySensitive(text, clearAfterMs)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun copySensitive(text: String, clearAfterMs: Long) {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText(clipLabel, text)
        // Android 13+: el teclado y la vista previa del sistema no muestran el contenido.
        clip.description.extras = PersistableBundle().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
            } else {
                putBoolean("android.content.extra.IS_SENSITIVE", true)
            }
        }
        cm.setPrimaryClip(clip)

        pendingClear?.let { handler.removeCallbacks(it) }
        val task = Runnable { clearIfOurs(cm) }
        pendingClear = task
        handler.postDelayed(task, clearAfterMs)
    }

    private fun clearIfOurs(cm: ClipboardManager) {
        pendingClear = null
        // Si podemos leer la descripción y el usuario copió otra cosa, no la borramos.
        val desc = try { cm.primaryClipDescription } catch (_: Exception) { null }
        if (desc != null && desc.label != clipLabel) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            cm.clearPrimaryClip()
        } else {
            cm.setPrimaryClip(ClipData.newPlainText("", ""))
        }
    }
}
