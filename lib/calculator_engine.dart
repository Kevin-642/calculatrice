import 'dart:math' as math;

class CalculatorEngine {
  double evaluate(String expression) {
    final parser = _ExpressionParser(expression);
    final result = parser.parse();
    if (result.isNaN || result.isInfinite) {
      throw const FormatException('Résultat invalide');
    }
    return result;
  }
}

class _ExpressionParser {
  _ExpressionParser(this.source);

  final String source;
  int index = 0;

  double parse() {
    if (source.trim().isEmpty) {
      throw const FormatException('Expression vide');
    }
    final value = _parseExpression();
    _skipSpaces();
    if (index != source.length) {
      throw const FormatException('Expression invalide');
    }
    return value;
  }

  double _parseExpression() {
    var value = _parseTerm();
    while (true) {
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (true) {
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();
        if (divisor == 0) {
          throw const FormatException('Division par zéro');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    if (_match('+')) {
      return _parseFactor();
    }
    if (_match('-')) {
      return -_parseFactor();
    }

    final value = _parsePrimary();
    if (_match('^')) {
      final result = math.pow(value, _parseFactor());
      return result.toDouble();
    }
    return value;
  }

  double _parsePrimary() {
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Parenthèse manquante');
      }
      return value;
    }
    return _parseNumber();
  }

  double _parseNumber() {
    _skipSpaces();
    final start = index;
    var hasDot = false;

    while (index < source.length) {
      final char = source[index];
      if (char == '.') {
        if (hasDot) {
          break;
        }
        hasDot = true;
        index++;
      } else if (_isDigit(char)) {
        index++;
      } else {
        break;
      }
    }

    if (index < source.length &&
        (source[index] == 'e' || source[index] == 'E')) {
      final exponentStart = index;
      index++;
      if (index < source.length &&
          (source[index] == '+' || source[index] == '-')) {
        index++;
      }
      final digitStart = index;
      while (index < source.length && _isDigit(source[index])) {
        index++;
      }
      if (digitStart == index) {
        index = exponentStart;
      }
    }

    if (start == index) {
      throw const FormatException('Nombre attendu');
    }

    return double.parse(source.substring(start, index));
  }

  bool _match(String value) {
    _skipSpaces();
    if (source.startsWith(value, index)) {
      index += value.length;
      return true;
    }
    return false;
  }

  bool _isDigit(String value) {
    final code = value.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  void _skipSpaces() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
  }
}
