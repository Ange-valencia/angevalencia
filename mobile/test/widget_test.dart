import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:angevalencia/main.dart';

void main() {
  testWidgets('L\'app démarre sur l\'écran de connexion', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AngeValenciaApp());
    await tester.pump();
    expect(find.text('AngeValencia'), findsWidgets);
    expect(find.text('Connexion'), findsOneWidget);
  });
}