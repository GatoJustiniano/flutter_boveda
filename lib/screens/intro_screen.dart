import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Introducción corta que se muestra la primera vez (y desde el menú «Cómo usar»).
class IntroView extends StatefulWidget {
  /// Se llama al tocar «Comenzar» o «Saltar».
  final VoidCallback onDone;

  /// Texto del botón final.
  final String doneLabel;

  const IntroView({super.key, required this.onDone, this.doneLabel = 'Comenzar'});

  static const _seenKey = 'intro_seen';

  static Future<bool> wasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroPage {
  final Widget art;
  final String title;
  final String body;
  const _IntroPage(this.art, this.title, this.body);
}

Widget _circleIcon(IconData icon, Color color) => Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Icon(icon, size: 60, color: color),
    );

class _IntroViewState extends State<IntroView> {
  final _controller = PageController();
  int _page = 0;

  static final _pages = [
    const _IntroPage(
      AppLogo(size: 130, showLock: false),
      'Bienvenido a tu Bóveda',
      'Guarda los números de cuenta y datos que usas cada mes: '
          'luz, agua, gas, internet, suscripciones y más.',
    ),
    _IntroPage(
      _circleIcon(Icons.touch_app_rounded, AppTheme.accentBlue),
      'Copia con un toque',
      'Toca una cuenta para copiar su número y pégalo en la app de tu banco.\n\n'
          'Mantén presionada una cuenta para editarla o eliminarla. '
          'Para agregar una cuenta, toca «Agregar» dentro de cada categoría.',
    ),
    _IntroPage(
      _circleIcon(Icons.key_rounded, AppTheme.accentPurple),
      'Suscripciones seguras',
      'En «Suscripciones» guarda correo y contraseña. '
          'La contraseña queda oculta y solo se ve o copia con tu huella o PIN.\n\n'
          'Al copiarla, se borra sola del portapapeles a los 30 segundos.',
    ),
    _IntroPage(
      _circleIcon(Icons.shield_rounded, AppTheme.accentGreen),
      'Solo tú puedes entrar',
      'Ahora crearás un PIN y podrás activar tu huella.\n\n'
          'Tus datos se guardan cifrados solo en este teléfono, sin copias en la nube. '
          'Si desinstalas la app o borras sus datos, se pierden.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: _isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLast ? null : widget.onDone,
                  child: const Text('Saltar'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        p.art,
                        const SizedBox(height: 40),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.45,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppTheme.accentBlue
                        : AppTheme.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? widget.doneLabel : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
