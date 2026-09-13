import 'package:flutter_test/flutter_test.dart';
import 'package:angevalencia_admin/theme.dart';

void main() {
  test('formatXof met bien les espaces', () {
    expect(formatXof(25000), '25 000 FCFA');
  });

  testWidgets('theme construit sans erreur', (tester) async {
    buildAngeValenciaTheme();
  });
}