import 'package:material_ui/material_ui.dart';
import 'screens/home_screen.dart';
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
        home: const HomeScreen(),
      ),
    );
  }
}
