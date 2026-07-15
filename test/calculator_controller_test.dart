import 'package:calculatrice_cosmique/calculator_controller.dart';
import 'package:calculatrice_cosmique/calculator_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorController', () {
    test('supports implicit multiplication and a decimal comma', () {
      final controller = CalculatorController();

      for (final key in <String>['2', '(', '3', '+', '4', ')', '=']) {
        controller.handleKey(key);
      }
      expect(controller.display, '14');

      controller.handleKey('C');
      for (final key in <String>['1', ',', '5', '+', '2', '=']) {
        controller.handleKey(key);
      }
      expect(controller.display, '3.5');
    });

    test('applies scientific functions and reports domain errors', () {
      final controller = CalculatorController();

      controller.handleKey('9');
      controller.handleKey('0');
      controller.handleKey('sin');
      expect(double.parse(controller.display), closeTo(1, 1e-12));

      controller.handleKey('C');
      controller.handleKey('-');
      controller.handleKey('1');
      controller.handleKey('sqrt');
      expect(controller.display, 'Erreur');
      expect(controller.errorMessage, 'Racine carrée impossible');
    });

    test('supports factorial and calculator memory', () {
      final controller = CalculatorController();

      controller.handleKey('5');
      controller.handleKey('factorial');
      expect(controller.display, '120');

      controller.handleKey('M+');
      expect(controller.hasMemory, isTrue);
      controller.handleKey('C');
      controller.handleKey('MR');
      expect(controller.display, '120');
    });

    test('loads and saves user preferences', () async {
      final preferences = _FakePreferences(
        const CalculatorSettings(
          history: <String>['1+1 = 2'],
          highContrast: true,
          radians: true,
          memory: 42,
        ),
      );
      final controller = CalculatorController(preferences: preferences);

      await controller.initialize();
      expect(controller.history, <String>['1+1 = 2']);
      expect(controller.highContrast, isTrue);
      expect(controller.angleMode, AngleMode.radians);
      expect(controller.hasMemory, isTrue);

      controller.toggleHighContrast();
      await Future<void>.delayed(Duration.zero);
      expect(preferences.saved?.highContrast, isFalse);
    });

    test('restores an expression from history', () {
      final controller = CalculatorController();
      controller.restoreHistory('(2+3)*4 = 20');

      expect(controller.expression, '(2+3)*4');
      expect(controller.display, '20');
    });
  });
}

class _FakePreferences implements CalculatorPreferences {
  _FakePreferences(this.initial);

  final CalculatorSettings initial;
  CalculatorSettings? saved;

  @override
  Future<CalculatorSettings> load() async => initial;

  @override
  Future<void> save({
    required List<String> history,
    required bool highContrast,
    required bool radians,
    required double memory,
  }) async {
    saved = CalculatorSettings(
      history: List<String>.of(history),
      highContrast: highContrast,
      radians: radians,
      memory: memory,
    );
  }
}
