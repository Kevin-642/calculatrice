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

    test('supports nested functions, variables and contextual percentages', () {
      expect(engine.evaluate('sin(30)+sqrt(16)'), closeTo(4.5, 1e-12));
      expect(
        engine.evaluate(
          'x^2+ans',
          variables: <String, double>{'x': 3, 'ans': 4},
        ),
        13,
      );
      expect(engine.evaluate('200+10%'), 220);
      expect(engine.evaluate('200-10%'), 180);
      expect(engine.evaluate('200*10%'), 20);
    });

    test('supports postfix factorial and radians', () {
      expect(engine.evaluate('5!'), 120);
      expect(engine.evaluate('sin(pi/2)', degrees: false), closeTo(1, 1e-12));
      expect(() => engine.evaluate('171!'), throwsFormatException);
    });

    test('keeps exact decimal arithmetic for basic calculations', () {
      expect(engine.evaluateExactDecimal('0.1+0.2'), '0.3');
      expect(
        engine.evaluateExactDecimal('9007199254740993+2'),
        '9007199254740995',
      );
      expect(engine.evaluateExactDecimal('1/8'), '0.125');
      expect(engine.evaluateExactDecimal('1/3'), isNull);
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
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('5'), findsWidgets);
    expect(find.text('2+3 = 5'), findsOneWidget);
    expect(find.byIcon(Icons.functions), findsOneWidget);

    await tester.ensureVisible(find.text('RAZ'));
    await tester.pump();
    await tester.tap(find.text('RAZ'));
    await tester.pump(const Duration(milliseconds: 300));

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
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('INITIALISATION STELLAIRE'), findsNothing);
    expect(find.text('Calculatrice Cosmique'), findsOneWidget);

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
    await tester.pump(const Duration(milliseconds: 500));

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
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('7 = 7'), findsOneWidget);
    expect(find.text('9/07 = 7'), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('opens the graph and conversion tools in landscape', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpWidget(const CalculatorApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('Grapheur'));
    await tester.pump();
    await tester.tap(find.text('Grapheur'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Grapheur cosmique'), findsOneWidget);
    expect(find.text('f(x)'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Conversions'));
    await tester.pump();
    await tester.tap(find.text('Conversions'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Convertisseur'), findsOneWidget);
    expect(find.text('Catégorie'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows history without scrolling in compact portrait layout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const CalculatorApp());
    await tester.pump(const Duration(seconds: 1));

    final historyTitle = find.text('Historique');
    expect(historyTitle, findsOneWidget);
    expect(tester.getBottomLeft(historyTitle).dy, lessThan(820));

    final sevenButton = find.ancestor(
      of: find.text('7'),
      matching: find.byType(InkWell),
    );
    expect(sevenButton, findsOneWidget);
    expect(tester.getSize(sevenButton).height, greaterThanOrEqualTo(48));

    await tester.binding.setSurfaceSize(null);
  });
}
