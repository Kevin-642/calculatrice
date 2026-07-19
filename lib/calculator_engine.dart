import 'dart:math' as math;

class CalculatorEngine {
  double evaluate(
    String expression, {
    bool degrees = true,
    Map<String, double> variables = const <String, double>{},
  }) {
    final parser = _ExpressionParser(
      expression,
      degrees: degrees,
      variables: variables,
    );
    final result = parser.parse();
    if (result.isNaN || result.isInfinite) {
      throw const FormatException('Résultat invalide');
    }
    return result;
  }

  /// Returns an exact decimal for basic arithmetic whenever the result has a
  /// finite decimal representation. Scientific functions still use doubles.
  String? evaluateExactDecimal(String expression) {
    if (!RegExp(r'^[0-9eE.,+\-*/() ]+$').hasMatch(expression)) {
      return null;
    }
    try {
      return _ExactParser(expression).parse().toFiniteDecimal();
    } on FormatException {
      return null;
    }
  }
}

class _ExpressionParser {
  _ExpressionParser(
    this.source, {
    required this.degrees,
    required Map<String, double> variables,
  }) : variables = <String, double>{
         for (final entry in variables.entries)
           entry.key.toLowerCase(): entry.value,
       };

  final String source;
  final bool degrees;
  final Map<String, double> variables;
  int index = 0;

  double parse() {
    if (source.trim().isEmpty) {
      throw const FormatException('Expression vide');
    }
    final value = _parseExpression().number;
    _skipSpaces();
    if (index != source.length) {
      throw const FormatException('Expression invalide');
    }
    return value;
  }

  _ParsedValue _parseExpression() {
    var value = _parseTerm();
    while (true) {
      if (_match('+')) {
        final right = _parseTerm();
        value = _ParsedValue(
          value.number +
              (right.isPercent ? value.number * right.number : right.number),
        );
      } else if (_match('-')) {
        final right = _parseTerm();
        value = _ParsedValue(
          value.number -
              (right.isPercent ? value.number * right.number : right.number),
        );
      } else {
        return value;
      }
    }
  }

  _ParsedValue _parseTerm() {
    var value = _parseFactor();
    while (true) {
      if (_match('*')) {
        value = _ParsedValue(value.number * _parseFactor().number);
      } else if (_match('/')) {
        final divisor = _parseFactor().number;
        if (divisor == 0) {
          throw const FormatException('Division par zéro');
        }
        value = _ParsedValue(value.number / divisor);
      } else {
        return value;
      }
    }
  }

  _ParsedValue _parseFactor() {
    if (_match('+')) {
      return _parseFactor();
    }
    if (_match('-')) {
      return _ParsedValue(-_parseFactor().number);
    }

    final value = _parsePostfix();
    if (_match('^')) {
      final exponent = _parseFactor().number;
      final result = math.pow(value.number, exponent);
      return _ParsedValue(result.toDouble());
    }
    return value;
  }

  _ParsedValue _parsePostfix() {
    var value = _parsePrimary();
    while (true) {
      if (_match('!')) {
        if (value.number < 0 ||
            value.number != value.number.truncateToDouble() ||
            value.number > 170) {
          throw const FormatException(
            'Factorielle limitée aux entiers de 0 à 170',
          );
        }
        var result = 1.0;
        for (var factor = 2; factor <= value.number.toInt(); factor++) {
          result *= factor;
        }
        value = _ParsedValue(result);
      } else if (_match('%')) {
        value = _ParsedValue(value.number / 100, isPercent: true);
      } else {
        return value;
      }
    }
  }

  _ParsedValue _parsePrimary() {
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Parenthèse manquante');
      }
      return value;
    }

    _skipSpaces();
    if (index < source.length && _isLetter(source[index])) {
      final identifier = _parseIdentifier();
      if (identifier == 'pi') {
        return const _ParsedValue(math.pi);
      }
      if (identifier == 'e') {
        return const _ParsedValue(math.e);
      }
      final variable = variables[identifier];
      if (variable != null) {
        return _ParsedValue(variable);
      }
      if (!_match('(')) {
        throw FormatException('Fonction inconnue : $identifier');
      }
      final argument = _parseExpression().number;
      if (!_match(')')) {
        throw const FormatException('Parenthèse manquante');
      }
      return _ParsedValue(_applyFunction(identifier, argument));
    }
    return _ParsedValue(_parseNumber());
  }

  double _applyFunction(String function, double value) {
    final angle = degrees ? value * math.pi / 180 : value;
    return switch (function) {
      'sin' => math.sin(angle),
      'cos' => math.cos(angle),
      'tan' when math.cos(angle).abs() < 1e-12 => throw const FormatException(
        'Tangente indéfinie',
      ),
      'tan' => math.tan(angle),
      'log' when value <= 0 => throw const FormatException(
        'Logarithme réservé aux nombres positifs',
      ),
      'log' => math.log(value) / math.ln10,
      'ln' when value <= 0 => throw const FormatException(
        'Logarithme réservé aux nombres positifs',
      ),
      'ln' => math.log(value),
      'sqrt' when value < 0 => throw const FormatException(
        'Racine carrée impossible',
      ),
      'sqrt' => math.sqrt(value),
      'abs' => value.abs(),
      'exp' => math.exp(value),
      _ => throw FormatException('Fonction inconnue : $function'),
    };
  }

  String _parseIdentifier() {
    final start = index;
    while (index < source.length &&
        (_isLetter(source[index]) || _isDigit(source[index]))) {
      index++;
    }
    return source.substring(start, index).toLowerCase();
  }

  double _parseNumber() {
    _skipSpaces();
    final start = index;
    var hasDot = false;

    while (index < source.length) {
      final char = source[index];
      if (char == '.' || char == ',') {
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

    return double.parse(source.substring(start, index).replaceAll(',', '.'));
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

  bool _isLetter(String value) {
    final code = value.toLowerCase().codeUnitAt(0);
    return code >= 97 && code <= 122;
  }

  void _skipSpaces() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
  }
}

class _ParsedValue {
  const _ParsedValue(this.number, {this.isPercent = false});

  final double number;
  final bool isPercent;
}

class _ExactParser {
  _ExactParser(this.source);

  final String source;
  int index = 0;

  _Fraction parse() {
    final result = _parseExpression();
    _skipSpaces();
    if (index != source.length) {
      throw const FormatException('Expression exacte invalide');
    }
    return result;
  }

  _Fraction _parseExpression() {
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

  _Fraction _parseTerm() {
    var value = _parseFactor();
    while (true) {
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        value /= _parseFactor();
      } else {
        return value;
      }
    }
  }

  _Fraction _parseFactor() {
    if (_match('+')) {
      return _parseFactor();
    }
    if (_match('-')) {
      return -_parseFactor();
    }
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Parenthèse manquante');
      }
      return value;
    }
    return _parseNumber();
  }

  _Fraction _parseNumber() {
    _skipSpaces();
    final start = index;
    while (index < source.length &&
        (RegExp(r'[0-9.,eE+\-]').hasMatch(source[index]))) {
      if ((source[index] == '+' || source[index] == '-') &&
          index > start &&
          source[index - 1].toLowerCase() != 'e') {
        break;
      }
      index++;
    }
    if (start == index) {
      throw const FormatException('Nombre attendu');
    }
    return _Fraction.parse(source.substring(start, index));
  }

  bool _match(String value) {
    _skipSpaces();
    if (source.startsWith(value, index)) {
      index += value.length;
      return true;
    }
    return false;
  }

  void _skipSpaces() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
  }
}

class _Fraction {
  _Fraction(BigInt numerator, BigInt denominator)
    : numerator = denominator.isNegative ? -numerator : numerator,
      denominator = denominator.abs() {
    if (denominator == BigInt.zero) {
      throw const FormatException('Division par zéro');
    }
  }

  factory _Fraction.parse(String source) {
    final normalized = source.replaceAll(',', '.').toLowerCase();
    final exponentIndex = normalized.indexOf('e');
    final mantissa = exponentIndex < 0
        ? normalized
        : normalized.substring(0, exponentIndex);
    final exponent = exponentIndex < 0
        ? 0
        : int.parse(normalized.substring(exponentIndex + 1));
    final dot = mantissa.indexOf('.');
    final decimals = dot < 0 ? 0 : mantissa.length - dot - 1;
    final digits = mantissa.replaceAll('.', '');
    var numerator = BigInt.parse(digits);
    var denominator = _pow10(decimals);
    if (exponent > 0) {
      numerator *= _pow10(exponent);
    } else if (exponent < 0) {
      denominator *= _pow10(-exponent);
    }
    return _Fraction(numerator, denominator)._reduced();
  }

  final BigInt numerator;
  final BigInt denominator;

  _Fraction operator +(_Fraction other) => _Fraction(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  )._reduced();

  _Fraction operator -(_Fraction other) => _Fraction(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  )._reduced();

  _Fraction operator *(_Fraction other) => _Fraction(
    numerator * other.numerator,
    denominator * other.denominator,
  )._reduced();

  _Fraction operator /(_Fraction other) => _Fraction(
    numerator * other.denominator,
    denominator * other.numerator,
  )._reduced();

  _Fraction operator -() => _Fraction(-numerator, denominator);

  _Fraction _reduced() {
    final divisor = numerator.abs().gcd(denominator);
    return _Fraction(numerator ~/ divisor, denominator ~/ divisor);
  }

  String? toFiniteDecimal() {
    var remaining = denominator;
    var twos = 0;
    var fives = 0;
    while (remaining % BigInt.two == BigInt.zero) {
      remaining ~/= BigInt.two;
      twos++;
    }
    final five = BigInt.from(5);
    while (remaining % five == BigInt.zero) {
      remaining ~/= five;
      fives++;
    }
    if (remaining != BigInt.one) {
      return null;
    }
    final scale = math.max(twos, fives);
    if (scale > 40) {
      return null;
    }
    final scaled =
        numerator * BigInt.two.pow(scale - twos) * five.pow(scale - fives);
    final negative = scaled.isNegative;
    var digits = scaled.abs().toString().padLeft(scale + 1, '0');
    if (scale > 0) {
      digits =
          '${digits.substring(0, digits.length - scale)}.'
          '${digits.substring(digits.length - scale)}';
      digits = digits.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return negative && digits != '0' ? '-$digits' : digits;
  }

  static BigInt _pow10(int exponent) => BigInt.from(10).pow(exponent);
}
