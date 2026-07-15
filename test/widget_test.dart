import 'package:calculatrice_cosmique/calculator_engine.dart';
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

    test('supports scientific notation', () {
      expect(engine.evaluate('1e3+2.5E-1'), 1000.25);
    });

    test('supports right-associative powers and unary signs', () {
      expect(engine.evaluate('2^3^2'), 512);
      expect(engine.evaluate('-2^2'), -4);
      expect(engine.evaluate('2^-2'), 0.25);
    });

    test('rejects malformed expressions', () {
      expect(() => engine.evaluate('(2+3'), throwsFormatException);
      expect(() => engine.evaluate('2+'), throwsFormatException);
      expect(() => engine.evaluate('1e+'), throwsFormatException);
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

  testWidgets('reveals the calculator through a cosmic launch', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());

    expect(find.text('INITIALISATION STELLAIRE'), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('INITIALISATION STELLAIRE'), findsNothing);
    expect(find.text('Calculatrice\nCosmique'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('starts a new number after a committed result', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.tap(find.text('4'));
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('4 = 4'), findsOneWidget);
    expect(find.text('54 = 54'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('recovers cleanly after an error', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());

    await tester.tap(find.text('9'));
    await tester.tap(find.text('/'));
    await tester.tap(find.text('0').last);
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('Erreur'), findsOneWidget);

    await tester.tap(find.text('7'));
    await tester.tap(find.text('='));
    await tester.pumpAndSettle();

    expect(find.text('7 = 7'), findsOneWidget);
    expect(find.text('9/07 = 7'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });
}
