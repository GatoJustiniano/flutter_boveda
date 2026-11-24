import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Logo de la app (patita) en círculo, con un pequeño candado opcional.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showLock;

  const AppLogo({super.key, this.size = 110, this.showLock = true});

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.32;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFADE5).withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Image.asset(
              'assets/icon/app_logo.png',
              width: size,
              height: size,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'Logo de Bóveda',
            ),
          ),
          if (showLock)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryDark, width: 3),
                ),
                child: Icon(Icons.lock_rounded,
                    size: badge * 0.55, color: AppTheme.primaryDark),
              ),
            ),
        ],
      ),
    );
  }
}
