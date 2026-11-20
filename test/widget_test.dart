import 'package:flutter_test/flutter_test.dart';
import 'package:boveda_de_suscripciones/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const BovedaApp());
    await tester.pumpAndSettle();

    expect(find.text('🔐 Bóveda de Cuentas'), findsOneWidget);
  });
}
