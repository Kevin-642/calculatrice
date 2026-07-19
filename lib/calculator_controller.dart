import 'dart:async';

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
  final Set<String> _pinnedHistory = <String>{};

  String _expression = '';
  String _display = '0';
  String _preview = '';
  String? _errorMessage;
  bool _scientificVisible = false;
  bool _highContrast = false;
  bool _resultCommitted = false;
  bool _launchSeen = false;
  AngleMode _angleMode = AngleMode.degrees;
  double _memory = 0;
  double _lastAnswer = 0;
  bool _hasAnswer = false;
  String? _repeatOperator;
  String? _repeatOperand;

  String get expression => _expression;
  String get display => _display;
  String get preview => _preview;
  String? get errorMessage => _errorMessage;
  bool get scientificVisible => _scientificVisible;
  bool get highContrast => _highContrast;
  AngleMode get angleMode => _angleMode;
  bool get hasMemory => _memory != 0;
  double get memoryValue => _memory;
  bool get hasAnswer => _hasAnswer;
  bool get launchSeen => _launchSeen;
  List<String> get history => List<String>.unmodifiable(_history);
  Set<String> get pinnedHistory => Set<String>.unmodifiable(_pinnedHistory);

  Future<void> initialize() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    final settings = await preferences.load();
    final currentHistory = List<String>.of(_history);
    _history
      ..clear()
      ..addAll(currentHistory)
      ..addAll(
        settings.history
            .where((item) => !currentHistory.contains(item))
            .take(50 - currentHistory.length),
      );
    _pinnedHistory.addAll(settings.pinnedHistory);
    _highContrast = settings.highContrast;
    _angleMode = settings.radians ? AngleMode.radians : AngleMode.degrees;
    _memory = settings.memory;
    _launchSeen = settings.launchSeen;
    notifyListeners();
  }

  void markLaunchSeen() {
    if (_launchSeen) {
      return;
    }
    _launchSeen = true;
    _persist();
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
        _appendToken('pi');
      case 'e':
        _appendToken('e');
      case 'ANS':
        if (_hasAnswer) {
          _appendToken('ans');
        }
      case 'x':
        _appendToken('x');
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

  void setExpression(String value) {
    _expression = value
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'\s+'), '');
    _errorMessage = null;
    _resultCommitted = false;
    _refreshPreview();
    notifyListeners();
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
    _refreshPreview();
    notifyListeners();
    _persist();
  }

  void clearHistory() {
    _history.clear();
    _pinnedHistory.clear();
    notifyListeners();
    _persist();
  }

  void deleteHistory(String item) {
    _history.remove(item);
    _pinnedHistory.remove(item);
    notifyListeners();
    _persist();
  }

  void toggleHistoryPinned(String item) {
    if (!_pinnedHistory.add(item)) {
      _pinnedHistory.remove(item);
    }
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

  double evaluateForGraph(String expression, double x) {
    return _engine.evaluate(
      expression,
      degrees: _angleMode == AngleMode.degrees,
      variables: <String, double>{'x': x, 'ans': _lastAnswer},
    );
  }

  void _clearExpression() {
    _expression = '';
    _display = '0';
    _preview = '';
    _errorMessage = null;
    _resultCommitted = false;
    _repeatOperator = null;
    _repeatOperand = null;
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
      if (RegExp(r'[0-9a-zA-Z)!%]').hasMatch(last)) {
        _expression += '*';
      }
    } else if (RegExp(r'^[0-9]$').hasMatch(normalizedKey) &&
        _expression.isNotEmpty &&
        RegExp(r'[)a-zA-Z!%]').hasMatch(_expression[_expression.length - 1])) {
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
      final parts = _expression.split(RegExp(r'[+\-*/^()%!]'));
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
      return openCount > closeCount && RegExp(r'[0-9a-zA-Z)!%]').hasMatch(last);
    }
    if ('+-*/^'.contains(key)) {
      if (_expression.isEmpty) {
        return key == '-';
      }
      final last = _expression[_expression.length - 1];
      if (key == '-') {
        return last != '.' && last != '-';
      }
      return RegExp(r'[0-9a-zA-Z)!%]').hasMatch(last);
    }
    return false;
  }

  void _refreshPreview({bool surfaceErrors = false}) {
    _preview = _expression;
    if (_expression.isEmpty) {
      _display = '0';
      return;
    }
    if (_expression.toLowerCase().contains('x')) {
      _display = 'f(x)';
      return;
    }
    try {
      _display =
          _engine.evaluateExactDecimal(_expression) ??
          formatNumber(_evaluate(_expression));
    } on FormatException catch (error) {
      if (surfaceErrors) {
        _setError(error.message.toString());
      } else {
        _display = '';
      }
    }
  }

  void _calculateFinalResult() {
    if (_expression.isEmpty) {
      return;
    }
    if (_expression.toLowerCase().contains('x')) {
      _setError('Utilisez le grapheur pour une expression contenant x');
      return;
    }
    if (_resultCommitted && _repeatOperator != null && _repeatOperand != null) {
      _expression = '$_display$_repeatOperator$_repeatOperand';
    } else {
      _captureRepeatOperation(_expression);
    }

    final closedExpression = _closeParentheses(_expression);
    try {
      final result = _evaluate(closedExpression);
      final formatted =
          _engine.evaluateExactDecimal(closedExpression) ??
          formatNumber(result);
      final historyItem = '$closedExpression = $formatted';
      _history
        ..remove(historyItem)
        ..insert(0, historyItem);
      if (_history.length > 50) {
        final removable = _history.lastWhere(
          (item) => !_pinnedHistory.contains(item),
          orElse: () => _history.last,
        );
        _history.remove(removable);
      }
      _preview = closedExpression;
      _display = formatted;
      _expression = formatted;
      _lastAnswer = result;
      _hasAnswer = true;
      _resultCommitted = true;
      _persist();
    } on FormatException catch (error) {
      _setError(error.message.toString());
    }
  }

  void _captureRepeatOperation(String expression) {
    var depth = 0;
    for (var position = expression.length - 1; position > 0; position--) {
      final char = expression[position];
      if (char == ')') {
        depth++;
      } else if (char == '(') {
        depth--;
      } else if (depth == 0 && '+-*/^'.contains(char)) {
        _repeatOperator = char;
        _repeatOperand = expression.substring(position + 1);
        return;
      }
    }
    _repeatOperator = null;
    _repeatOperand = null;
  }

  String _closeParentheses(String expression) {
    final missing =
        '('.allMatches(expression).length - ')'.allMatches(expression).length;
    return missing > 0
        ? '$expression${List<String>.filled(missing, ')').join()}'
        : expression;
  }

  void _applyScientificKey(String key) {
    switch (key) {
      case 'x2':
        _wrapOrAppendSuffix('^2');
      case 'percent':
        _wrapOrAppendSuffix('%');
      case 'factorial':
        _wrapOrAppendSuffix('!');
      case 'inverse':
        _wrapExpression('1/(', ')');
      case 'negate':
        _wrapExpression('-(', ')');
      default:
        _insertFunction(key);
    }
  }

  void _insertFunction(String function) {
    if (_display == 'Erreur') {
      _clearExpression();
    }
    final isWrapping =
        _expression.isNotEmpty &&
        !'+-*/^('.contains(_expression[_expression.length - 1]);
    if (!isWrapping) {
      _expression += '$function(';
      _resultCommitted = false;
    } else {
      _expression = '$function($_expression)';
      _resultCommitted = true;
    }
    _refreshPreview(surfaceErrors: isWrapping);
  }

  void _wrapExpression(String prefix, String suffix) {
    final value = _expression;
    if (value.isEmpty) {
      _expression = prefix;
      _resultCommitted = false;
    } else {
      _expression = '$prefix$value$suffix';
      _resultCommitted = true;
    }
    _refreshPreview(surfaceErrors: _resultCommitted);
  }

  void _wrapOrAppendSuffix(String suffix) {
    if (_expression.isEmpty ||
        '+-*/^('.contains(_expression[_expression.length - 1])) {
      _setError('Expression incomplète');
      return;
    }
    _expression += suffix;
    _resultCommitted = true;
    _refreshPreview(surfaceErrors: true);
  }

  void _appendToken(String token) {
    if (_display == 'Erreur' || _resultCommitted) {
      _expression = '';
    }
    _resultCommitted = false;
    if (_expression.endsWith('.')) {
      return;
    }
    if (_expression.isNotEmpty &&
        RegExp(
          r'[0-9a-zA-Z)!%]',
        ).hasMatch(_expression[_expression.length - 1])) {
      _expression += '*';
    }
    _expression += token;
    _refreshPreview();
  }

  void _appendConstant(double value) {
    _appendToken(formatNumber(value));
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
    if (_display.isNotEmpty && _display != 'Erreur' && _display != 'f(x)') {
      return double.tryParse(_display);
    }
    if (_expression.isEmpty) {
      return 0;
    }
    try {
      return _evaluate(_expression);
    } on FormatException {
      return null;
    }
  }

  double _evaluate(String expression) {
    return _engine.evaluate(
      expression,
      degrees: _angleMode == AngleMode.degrees,
      variables: <String, double>{'ans': _lastAnswer},
    );
  }

  void _setError(String message) {
    _display = 'Erreur';
    _preview = _expression;
    _errorMessage = message;
    _resultCommitted = false;
  }

  String formatNumber(double value) {
    if (value.abs() < 1e-14) {
      return '0';
    }
    if (value.abs() >= 1e15 || value.abs() < 1e-12) {
      return value
          .toStringAsExponential(12)
          .replaceFirst(RegExp(r'\.0+(?=e)'), '');
    }
    if (value == value.roundToDouble() && value.abs() <= 9007199254740991) {
      return value.toInt().toString();
    }
    return value.toStringAsPrecision(14).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _persist() {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    unawaited(
      preferences.save(
        history: _history,
        pinnedHistory: _pinnedHistory.toList(growable: false),
        highContrast: _highContrast,
        radians: _angleMode == AngleMode.radians,
        memory: _memory,
        launchSeen: _launchSeen,
      ),
    );
  }
}
