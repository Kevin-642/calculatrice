import 'package:calculatrice_cosmique/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorEngine', () {
    final engine = CalculatorEngine();

    test('respects operator precedence', () {
      expect(engine.evaluate('2+3*4'), 14);
    });

    test('supports parenthesis and decimals', () {
      expect(engine.evaluate('(2.5+1.5)*2'), 8);
    });

    test('rejects division by zero', () {
      expect(() => engine.evaluate('9/0'), throwsFormatException);
    });
  });

  testWidgets('calculates a basic sum', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsWidgets);
    expect(find.text('2+3 = 5'), findsOneWidget);
    expect(find.byIcon(Icons.functions), findsOneWidget);

    await tester.tap(find.text('RAZ'));
    await tester.pumpAndSettle();

    expect(find.text('2+3 = 5'), findsNothing);
    expect(find.text('Aucun calcul'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
