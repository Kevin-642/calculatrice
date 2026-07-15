import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'calculator_engine.dart';
import 'calculator_preferences.dart';

enum AngleMode { degrees, radians }

class CalculatorController extends ChangeNotifier {
  CalculatorController({
    CalculatorEngine? engine,
    CalculatorPreferences? preferences,
  }) : _engine = engine ?? CalculatorEngine(),
       _preferences = preferences;

  final CalculatorEngine _engine;
  final CalculatorPreferences? _preferences;
  final List<String> _history = <String>[];

  String _expression = '';
  String _display = '0';
  String _preview = '';
  String? _errorMessage;
  bool _scientificVisible = false;
  bool _highContrast = false;
  bool _resultCommitted = false;
  AngleMode _angleMode = AngleMode.degrees;
  double _memory = 0;

  String get expression => _expression;
  String get display => _display;
  String get preview => _preview;
  String? get errorMessage => _errorMessage;
  bool get scientificVisible => _scientificVisible;
  bool get highContrast => _highContrast;
  AngleMode get angleMode => _angleMode;
  bool get hasMemory => _memory != 0;
  List<String> get history => List<String>.unmodifiable(_history);

  Future<void> initialize() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    final settings = await preferences.load();
    _history
      ..clear()
      ..addAll(settings.history.take(12));
    _highContrast = settings.highContrast;
    _angleMode = settings.radians ? AngleMode.radians : AngleMode.degrees;
    _memory = settings.memory;
    notifyListeners();
  }

  void handleKey(String key) {
    _errorMessage = null;
    switch (key) {
      case 'C':
        _clearExpression();
      case 'DEL':
        _deleteLast();
      case '=':
        _calculateFinalResult();
      case 'sin' ||
          'cos' ||
          'tan' ||
          'log' ||
          'ln' ||
          'sqrt' ||
          'x2' ||
          'percent' ||
          'inverse' ||
          'abs' ||
          'negate' ||
          'factorial' ||
          'exp':
        _applyScientificKey(key);
      case 'pi':
        _appendConstant(math.pi);
      case 'e':
        _appendConstant(math.e);
      case 'MC':
        _clearMemory();
      case 'MR':
        _appendConstant(_memory);
      case 'M+':
        _updateMemory(add: true);
      case 'M-':
        _updateMemory(add: false);
      default:
        _appendKey(key);
    }
    notifyListeners();
  }

  void handleLongPress(String key) {
    if (key == 'DEL') {
      _clearExpression();
      notifyListeners();
    }
  }

  void toggleScientific() {
    _scientificVisible = !_scientificVisible;
    notifyListeners();
  }

  void toggleHighContrast() {
    _highContrast = !_highContrast;
    notifyListeners();
    _persist();
  }

  void toggleAngleMode() {
    _angleMode = _angleMode == AngleMode.degrees
        ? AngleMode.radians
        : AngleMode.degrees;
    notifyListeners();
    _persist();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
    _persist();
  }

  void restoreHistory(String item) {
    final separator = item.lastIndexOf(' = ');
    if (separator <= 0) {
      return;
    }
    _expression = item.substring(0, separator);
    _errorMessage = null;
    _resultCommitted = false;
    _refreshPreview();
    notifyListeners();
  }

  void _clearExpression() {
    _expression = '';
    _display = '0';
    _preview = '';
    _errorMessage = null;
    _resultCommitted = false;
  }

  void _deleteLast() {
    _resultCommitted = false;
    if (_expression.isNotEmpty) {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _refreshPreview();
  }

  void _appendKey(String key) {
    if (_display == 'Erreur') {
      _clearExpression();
    }

    final normalizedKey = key == ',' ? '.' : key;
    if (_resultCommitted &&
        (RegExp(r'^[0-9.]$').hasMatch(normalizedKey) || normalizedKey == '(')) {
      _expression = '';
    }

    if (!_canAppend(normalizedKey)) {
      return;
    }
    _resultCommitted = false;

    if (normalizedKey == '(' && _expression.isNotEmpty) {
      final last = _expression[_expression.length - 1];
      if (RegExp(r'[0-9)]').hasMatch(last)) {
        _expression += '*';
      }
    } else if (RegExp(r'^[0-9]$').hasMatch(normalizedKey) &&
        _expression.endsWith(')')) {
      _expression += '*';
    }

    _expression += normalizedKey;
    _refreshPreview();
  }

  bool _canAppend(String key) {
    if (RegExp(r'^[0-9]$').hasMatch(key)) {
      return true;
    }
    if (key == '.') {
      if (_expression.endsWith(')')) {
        return false;
      }
      final parts = _expression.split(RegExp(r'[+\-*/^()]'));
      return parts.isEmpty || !parts.last.contains('.');
    }
    if (key == '(') {
      return _expression.isEmpty || !_expression.endsWith('.');
    }
    if (key == ')') {
      if (_expression.isEmpty) {
        return false;
      }
      final openCount = '('.allMatches(_expression).length;
      final closeCount = ')'.allMatches(_expression).length;
      final last = _expression[_expression.length - 1];
      return openCount > closeCount && RegExp(r'[0-9)]').hasMatch(last);
    }
    if ('+-*/^'.contains(key)) {
      if (_expression.isEmpty) {
        return key == '-';
      }
      final last = _expression[_expression.length - 1];
      if (key == '-') {
        return last != '.' && last != '-';
      }
      return RegExp(r'[0-9)]').hasMatch(last);
    }
    return false;
  }

  void _refreshPreview() {
    _preview = _expression;
    if (_expression.isEmpty) {
      _display = '0';
      return;
    }
    try {
      _display = formatNumber(_engine.evaluate(_expression));
    } on FormatException {
      _display = '';
    }
  }

  void _calculateFinalResult() {
    if (_expression.isEmpty) {
      return;
    }
    try {
      final formatted = formatNumber(_engine.evaluate(_expression));
      _history.insert(0, '$_expression = $formatted');
      if (_history.length > 12) {
        _history.removeLast();
      }
      _preview = _expression;
      _display = formatted;
      _expression = formatted;
      _resultCommitted = true;
      _persist();
    } on FormatException catch (error) {
      _setError(error.message.toString());
    }
  }

  void _applyScientificKey(String key) {
    final value = _currentValue();
    if (value == null) {
      _setError('Expression incomplète');
      return;
    }

    final double result;
    switch (key) {
      case 'sin':
        result = math.sin(_toRadians(value));
      case 'cos':
        result = math.cos(_toRadians(value));
      case 'tan':
        final angle = _toRadians(value);
        if (math.cos(angle).abs() < 1e-12) {
          _setError('Tangente indéfinie');
          return;
        }
        result = math.tan(angle);
      case 'log':
        if (value <= 0) {
          _setError('Logarithme réservé aux nombres positifs');
          return;
        }
        result = math.log(value) / math.ln10;
      case 'ln':
        if (value <= 0) {
          _setError('Logarithme réservé aux nombres positifs');
          return;
        }
        result = math.log(value);
      case 'sqrt':
        if (value < 0) {
          _setError('Racine carrée impossible');
          return;
        }
        result = math.sqrt(value);
      case 'inverse':
        if (value == 0) {
          _setError('Division par zéro');
          return;
        }
        result = 1 / value;
      case 'factorial':
        if (value < 0 || value != value.truncateToDouble() || value > 170) {
          _setError('Factorielle limitée aux entiers de 0 à 170');
          return;
        }
        result = _factorial(value.toInt());
      case 'x2':
        result = value * value;
      case 'percent':
        result = value / 100;
      case 'abs':
        result = value.abs();
      case 'negate':
        result = -value;
      case 'exp':
        result = math.exp(value);
      default:
        result = value;
    }

    if (!result.isFinite) {
      _setError('Résultat hors limites');
      return;
    }
    final formatted = formatNumber(result);
    _preview = '${_scientificLabel(key)}(${formatNumber(value)})';
    _display = formatted;
    _expression = formatted;
    _resultCommitted = true;
  }

  void _appendConstant(double value) {
    if (_display == 'Erreur' || _resultCommitted) {
      _expression = '';
    }
    _resultCommitted = false;
    if (_expression.endsWith('.')) {
      return;
    }
    if (_expression.isNotEmpty &&
        RegExp(r'[0-9)]').hasMatch(_expression[_expression.length - 1])) {
      _expression += '*';
    }
    _expression += formatNumber(value);
    _refreshPreview();
  }

  void _updateMemory({required bool add}) {
    final value = _currentValue();
    if (value == null) {
      _setError('Aucune valeur à mémoriser');
      return;
    }
    _memory += add ? value : -value;
    _persist();
  }

  void _clearMemory() {
    _memory = 0;
    _persist();
  }

  double? _currentValue() {
    if (_display.isNotEmpty && _display != 'Erreur') {
      return double.tryParse(_display);
    }
    if (_expression.isEmpty) {
      return 0;
    }
    try {
      return _engine.evaluate(_expression);
    } on FormatException {
      return null;
    }
  }

  double _toRadians(double value) {
    return _angleMode == AngleMode.degrees ? value * math.pi / 180 : value;
  }

  double _factorial(int value) {
    var result = 1.0;
    for (var factor = 2; factor <= value; factor++) {
      result *= factor;
    }
    return result;
  }

  String _scientificLabel(String key) {
    return switch (key) {
      'x2' => 'carré',
      'percent' => '%',
      'inverse' => '1/x',
      'negate' => '±',
      'factorial' => 'n!',
      _ => key,
    };
  }

  void _setError(String message) {
    _display = 'Erreur';
    _preview = _expression;
    _errorMessage = message;
    _resultCommitted = false;
  }

  String formatNumber(double value) {
    if (value == 0) {
      return '0';
    }
    if (value.abs() >= 1e15 || value.abs() < 1e-10) {
      return value
          .toStringAsExponential(10)
          .replaceFirst(RegExp(r'\.0+(?=e)'), '');
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsPrecision(12).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _persist() {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    unawaited(
      preferences.save(
        history: _history,
        highContrast: _highContrast,
        radians: _angleMode == AngleMode.radians,
        memory: _memory,
      ),
    );
  }
}
