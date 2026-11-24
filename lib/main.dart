import 'package:material_ui/material_ui.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';
import 'providers/vault_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BovedaApp());
}

class BovedaApp extends StatelessWidget {
  const BovedaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultProvider(
      child: MaterialApp(
        title: 'Bóveda de Suscripciones',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // El bloqueo envuelve al Navigator completo: cubre también diálogos abiertos.
        builder: (context, child) => AppLockGate(child: child!),
        home: const HomeScreen(),
      ),
    );
  }
}
