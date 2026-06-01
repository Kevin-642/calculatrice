import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculatrice Cosmique',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFE2B3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorEngine _engine = CalculatorEngine();
  final List<String> _history = <String>[];
  String _expression = '';
  String _display = '0';
  String _preview = '';
  bool _scientificVisible = false;
  bool _highContrast = false;

  void _handleKey(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
        _display = '0';
        _preview = '';
        return;
      }

      if (key == 'DEL') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        _refreshPreview();
        return;
      }

      if (key == '=') {
        _calculateFinalResult();
        return;
      }

      if (_isScientificKey(key)) {
        _applyScientificKey(key);
        return;
      }

      _appendKey(key);
    });
  }

  void _appendKey(String key) {
    if (!_canAppend(key)) {
      return;
    }

    if (_display == 'Erreur') {
      _expression = '';
    }

    _expression += key;
    _refreshPreview();
  }

  bool _canAppend(String key) {
    if (RegExp(r'^[0-9]$').hasMatch(key)) {
      return true;
    }

    if (key == '.') {
      final parts = _expression.split(RegExp(r'[+\-*/()]'));
      return parts.isEmpty || !parts.last.contains('.');
    }

    if ('+-*/()'.contains(key)) {
      if (_expression.isEmpty) {
        return key == '-' || key == '(';
      }
      final last = _expression[_expression.length - 1];
      if ('+*/.'.contains(last) && '+*/.'.contains(key)) {
        return false;
      }
      if (last == '-' && '+*/'.contains(key)) {
        return false;
      }
      return true;
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
      final value = _engine.evaluate(_expression);
      _display = _formatNumber(value);
    } on FormatException {
      _display = '';
    }
  }

  void _calculateFinalResult() {
    if (_expression.isEmpty) {
      return;
    }

    try {
      final result = _engine.evaluate(_expression);
      final formatted = _formatNumber(result);
      _history.insert(0, '$_expression = $formatted');
      if (_history.length > 12) {
        _history.removeLast();
      }
      _preview = _expression;
      _display = formatted;
      _expression = formatted;
    } on FormatException {
      _display = 'Erreur';
      _preview = _expression;
    }
  }

  bool _isScientificKey(String key) {
    return const <String>{
      'sin',
      'cos',
      'tan',
      'log',
      'ln',
      'sqrt',
      'x2',
      'pi',
      'e',
      'exp',
    }.contains(key);
  }

  void _applyScientificKey(String key) {
    if (key == 'pi') {
      _expression += _formatNumber(math.pi);
      _refreshPreview();
      return;
    }

    if (key == 'e') {
      _expression += _formatNumber(math.e);
      _refreshPreview();
      return;
    }

    final double? value = _display.isNotEmpty && _display != 'Erreur'
        ? double.tryParse(_display)
        : _expression.isNotEmpty
        ? _safeEvaluateCurrent()
        : 0.0;

    if (value == null) {
      _display = 'Erreur';
      return;
    }

    final double result = switch (key) {
      'sin' => math.sin(_degreesToRadians(value)),
      'cos' => math.cos(_degreesToRadians(value)),
      'tan' => math.tan(_degreesToRadians(value)),
      'log' => value > 0 ? math.log(value) / math.ln10 : double.nan,
      'ln' => value > 0 ? math.log(value) : double.nan,
      'sqrt' => value >= 0 ? math.sqrt(value) : double.nan,
      'x2' => value * value,
      'exp' => math.exp(value),
      _ => value,
    };

    if (result.isNaN || result.isInfinite) {
      _display = 'Erreur';
      return;
    }

    final formatted = _formatNumber(result);
    _preview = '$key(${_formatNumber(value)})';
    _display = formatted;
    _expression = formatted;
  }

  double? _safeEvaluateCurrent() {
    try {
      return _engine.evaluate(_expression);
    } on FormatException {
      return null;
    }
  }

  double _degreesToRadians(double value) {
    return value * math.pi / 180;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsPrecision(12).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = _highContrast
        ? _ContrastPalette.high
        : _ContrastPalette.space;

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.35, -0.35),
            radius: 1.25,
            colors: <Color>[
              colors.nebula,
              colors.backgroundAlt,
              colors.background,
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: _GalaxyPainter(colors)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          children: <Widget>[
                            _Header(
                              highContrast: _highContrast,
                              colors: colors,
                              onContrastChanged: () {
                                setState(() => _highContrast = !_highContrast);
                              },
                            ),
                            const SizedBox(height: 14),
                            _DisplayPanel(
                              preview: _preview,
                              display: _display,
                              colors: colors,
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: <Widget>[
                                    _KeyGrid(
                                      keys: const <CalculatorKey>[
                                        CalculatorKey(
                                          'C',
                                          style: KeyStyle.warning,
                                        ),
                                        CalculatorKey(
                                          'DEL',
                                          icon: Icons.backspace_outlined,
                                        ),
                                        CalculatorKey(
                                          '(',
                                          style: KeyStyle.secondary,
                                        ),
                                        CalculatorKey(
                                          ')',
                                          style: KeyStyle.secondary,
                                        ),
                                        CalculatorKey('7'),
                                        CalculatorKey('8'),
                                        CalculatorKey('9'),
                                        CalculatorKey(
                                          '/',
                                          style: KeyStyle.operator,
                                        ),
                                        CalculatorKey('4'),
                                        CalculatorKey('5'),
                                        CalculatorKey('6'),
                                        CalculatorKey(
                                          '*',
                                          label: 'x',
                                          style: KeyStyle.operator,
                                        ),
                                        CalculatorKey('1'),
                                        CalculatorKey('2'),
                                        CalculatorKey('3'),
                                        CalculatorKey(
                                          '-',
                                          style: KeyStyle.operator,
                                        ),
                                        CalculatorKey('0'),
                                        CalculatorKey('.'),
                                        CalculatorKey(
                                          '=',
                                          style: KeyStyle.equals,
                                        ),
                                        CalculatorKey(
                                          '+',
                                          style: KeyStyle.operator,
                                        ),
                                      ],
                                      colors: colors,
                                      onTap: _handleKey,
                                    ),
                                    const SizedBox(height: 12),
                                    _ScientificToggle(
                                      visible: _scientificVisible,
                                      onTap: () {
                                        setState(() {
                                          _scientificVisible =
                                              !_scientificVisible;
                                        });
                                      },
                                      colors: colors,
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: _scientificVisible
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: _KeyGrid(
                                                keys: const <CalculatorKey>[
                                                  CalculatorKey(
                                                    'sin',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'cos',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'tan',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'log',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'ln',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'sqrt',
                                                    label: 'sqrt',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'x2',
                                                    label: 'x2',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'pi',
                                                    label: 'pi',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'e',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                  CalculatorKey(
                                                    'exp',
                                                    style: KeyStyle.secondary,
                                                  ),
                                                ],
                                                columns: 5,
                                                colors: colors,
                                                onTap: _handleKey,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 12),
                                    _HistoryPanel(
                                      history: _history,
                                      colors: colors,
                                      onClear: _history.isEmpty
                                          ? null
                                          : () {
                                              setState(_history.clear);
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorEngine {
  double evaluate(String expression) {
    final parser = _ExpressionParser(expression);
    final result = parser.parse();
    if (result.isNaN || result.isInfinite) {
      throw const FormatException('Resultat invalide');
    }
    return result;
  }
}

class _ExpressionParser {
  _ExpressionParser(this.source);

  final String source;
  int index = 0;

  double parse() {
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
      _skipSpaces();
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
      _skipSpaces();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final divisor = _parseFactor();
        if (divisor == 0) {
          throw const FormatException('Division par zero');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    _skipSpaces();

    if (_match('+')) {
      return _parseFactor();
    }
    if (_match('-')) {
      return -_parseFactor();
    }
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Parenthese manquante');
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
      } else if (RegExp(r'[0-9]').hasMatch(char)) {
        index++;
      } else {
        break;
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

  void _skipSpaces() {
    while (index < source.length && source[index].trim().isEmpty) {
      index++;
    }
  }
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter(this.colors);

  final _ContrastPalette colors;

  static const List<_Star> _stars = <_Star>[
    _Star(0.08, 0.10, 1.5),
    _Star(0.16, 0.26, 0.8),
    _Star(0.28, 0.13, 1.0),
    _Star(0.42, 0.20, 1.3),
    _Star(0.62, 0.12, 0.9),
    _Star(0.82, 0.18, 1.7),
    _Star(0.91, 0.33, 1.0),
    _Star(0.74, 0.47, 0.8),
    _Star(0.12, 0.58, 1.1),
    _Star(0.30, 0.72, 0.7),
    _Star(0.51, 0.82, 1.4),
    _Star(0.86, 0.78, 1.1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final nebulaPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              colors.warmGlow.withValues(alpha: 0.55),
              colors.glow.withValues(alpha: 0.36),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.62, size.height * 0.20),
              radius: size.width * 0.62,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.20),
      size.width * 0.60,
      nebulaPaint,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = colors.goldBorder.withValues(alpha: 0.18);
    for (var i = 0; i < 3; i++) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * 0.60, size.height * 0.22),
        width: size.width * (0.70 + i * 0.14),
        height: size.width * (0.24 + i * 0.09),
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-0.42 + i * 0.18);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawOval(rect, ringPaint);
      canvas.restore();
    }

    final starPaint = Paint()..color = Colors.white;
    for (final star in _stars) {
      final offset = Offset(size.width * star.x, size.height * star.y);
      canvas.drawCircle(offset, star.radius, starPaint);
      canvas.drawLine(
        offset.translate(-star.radius * 2.2, 0),
        offset.translate(star.radius * 2.2, 0),
        starPaint..strokeWidth = 0.55,
      );
      canvas.drawLine(
        offset.translate(0, -star.radius * 2.2),
        offset.translate(0, star.radius * 2.2),
        starPaint,
      );
    }

    final symbolStyle = TextStyle(
      color: colors.accent.withValues(alpha: 0.18),
      fontSize: 34,
      fontWeight: FontWeight.w700,
    );
    const symbols = <String>['π', '√', 'e', 'sin', 'cos', 'tan', '÷'];
    for (var i = 0; i < symbols.length; i++) {
      final painter = TextPainter(
        text: TextSpan(text: symbols[i], style: symbolStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          size.width * (0.12 + (i % 4) * 0.22),
          size.height * (0.30 + (i ~/ 4) * 0.43),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class _Star {
  const _Star(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.highContrast,
    required this.colors,
    required this.onContrastChanged,
  });

  final bool highContrast;
  final _ContrastPalette colors;
  final VoidCallback onContrastChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.panel.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: colors.glow, blurRadius: 24, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(color: colors.warmGlow, blurRadius: 18),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/brand/logo.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Calculatrice\nCosmique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 0.98,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    shadows: <Shadow>[
                      Shadow(color: colors.glow, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Simple, scientifique, hors ligne',
                  style: TextStyle(color: colors.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: highContrast ? 'Mode cosmique' : 'Contraste eleve',
            onPressed: onContrastChanged,
            style: IconButton.styleFrom(
              backgroundColor: colors.secondary,
              foregroundColor: colors.accent,
            ),
            icon: Icon(highContrast ? Icons.dark_mode : Icons.contrast),
          ),
        ],
      ),
    );
  }
}

class _DisplayPanel extends StatelessWidget {
  const _DisplayPanel({
    required this.preview,
    required this.display,
    required this.colors,
  });

  final String preview;
  final String display;
  final _ContrastPalette colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ecran de la calculatrice',
      value: display.isEmpty ? 'Expression incomplete' : display,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              colors.panel.withValues(alpha: 0.92),
              colors.panelAlt.withValues(alpha: 0.78),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(color: colors.glow, blurRadius: 26, spreadRadius: 1),
            BoxShadow(color: colors.warmGlow, blurRadius: 14),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              preview.isEmpty ? ' ' : preview,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(color: colors.muted, fontSize: 16),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                display.isEmpty ? ' ' : display,
                maxLines: 1,
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  shadows: <Shadow>[Shadow(color: colors.glow, blurRadius: 12)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyGrid extends StatelessWidget {
  const _KeyGrid({
    required this.keys,
    required this.colors,
    required this.onTap,
    this.columns = 4,
  });

  final List<CalculatorKey> keys;
  final _ContrastPalette colors;
  final ValueChanged<String> onTap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: keys.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: columns == 5 ? 1.15 : 1.25,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        return _CalculatorButton(
          keyData: key,
          colors: colors,
          onTap: () => onTap(key.value),
        );
      },
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({
    required this.keyData,
    required this.colors,
    required this.onTap,
  });

  final CalculatorKey keyData;
  final _ContrastPalette colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = switch (keyData.style) {
      KeyStyle.operator => colors.operator,
      KeyStyle.equals => colors.equals,
      KeyStyle.warning => colors.warning,
      KeyStyle.secondary => colors.secondary,
      KeyStyle.normal => colors.button,
    };
    final borderColor = switch (keyData.style) {
      KeyStyle.operator || KeyStyle.secondary => colors.goldBorder,
      KeyStyle.equals => colors.equals,
      KeyStyle.warning => colors.warningBorder,
      KeyStyle.normal => colors.border,
    };
    final textColor = switch (keyData.style) {
      KeyStyle.equals => colors.background,
      KeyStyle.operator || KeyStyle.secondary => colors.accent,
      KeyStyle.warning => Colors.white,
      KeyStyle.normal => Colors.white,
    };

    return Semantics(
      button: true,
      label: keyData.semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              background.withValues(alpha: 0.96),
              background.withValues(alpha: 0.58),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withValues(alpha: 0.82)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: borderColor.withValues(alpha: 0.26),
              blurRadius: 14,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: keyData.icon == null
                  ? Text(
                      keyData.label ?? keyData.value,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        shadows: <Shadow>[
                          Shadow(
                            color: borderColor.withValues(alpha: 0.65),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    )
                  : Icon(keyData.icon, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScientificToggle extends StatelessWidget {
  const _ScientificToggle({
    required this.visible,
    required this.onTap,
    required this.colors,
  });

  final bool visible;
  final VoidCallback onTap;
  final _ContrastPalette colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(visible ? Icons.science : Icons.functions),
        label: Text(
          visible ? 'Masquer les fonctions' : 'Fonctions scientifiques',
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.accent,
          backgroundColor: colors.panel.withValues(alpha: 0.48),
          side: BorderSide(color: colors.goldBorder.withValues(alpha: 0.72)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({
    required this.history,
    required this.colors,
    required this.onClear,
  });

  final List<String> history;
  final _ContrastPalette colors;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: colors.glow.withValues(alpha: 0.7), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Historique',
                  style: TextStyle(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('RAZ'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accent,
                  disabledForegroundColor: colors.muted.withValues(alpha: 0.45),
                  backgroundColor: colors.secondary.withValues(alpha: 0.3),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (history.isEmpty)
            Text(
              'Aucun calcul',
              style: TextStyle(color: colors.muted.withValues(alpha: 0.75)),
            )
          else
            ...history.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CalculatorKey {
  const CalculatorKey(
    this.value, {
    this.label,
    this.icon,
    this.style = KeyStyle.normal,
  });

  final String value;
  final String? label;
  final IconData? icon;
  final KeyStyle style;

  String get semanticLabel {
    return switch (value) {
      'C' => 'Effacer',
      'DEL' => 'Supprimer',
      '=' => 'Calculer',
      '+' => 'Addition',
      '-' => 'Soustraction',
      '*' => 'Multiplication',
      '/' => 'Division',
      _ => label ?? value,
    };
  }
}

enum KeyStyle { normal, operator, equals, warning, secondary }

class _ContrastPalette {
  const _ContrastPalette({
    required this.background,
    required this.backgroundAlt,
    required this.nebula,
    required this.panel,
    required this.panelAlt,
    required this.button,
    required this.secondary,
    required this.operator,
    required this.equals,
    required this.warning,
    required this.accent,
    required this.muted,
    required this.border,
    required this.goldBorder,
    required this.warningBorder,
    required this.glow,
    required this.warmGlow,
  });

  final Color background;
  final Color backgroundAlt;
  final Color nebula;
  final Color panel;
  final Color panelAlt;
  final Color button;
  final Color secondary;
  final Color operator;
  final Color equals;
  final Color warning;
  final Color accent;
  final Color muted;
  final Color border;
  final Color goldBorder;
  final Color warningBorder;
  final Color glow;
  final Color warmGlow;

  static const _ContrastPalette space = _ContrastPalette(
    background: Color(0xFF050818),
    backgroundAlt: Color(0xFF10162D),
    nebula: Color(0xFF342044),
    panel: Color(0xD9091124),
    panelAlt: Color(0xC91A233E),
    button: Color(0xFF151D36),
    secondary: Color(0xFF27213B),
    operator: Color(0xFF382941),
    equals: Color(0xFFFFE8BD),
    warning: Color(0xFF8E3650),
    accent: Color(0xFFFFE6BC),
    muted: Color(0xFFE8D3B0),
    border: Color(0x777EA8FF),
    goldBorder: Color(0xCCFFDDA8),
    warningBorder: Color(0xFFE68AA0),
    glow: Color(0x553C8CFF),
    warmGlow: Color(0x66FFB879),
  );

  static const _ContrastPalette high = _ContrastPalette(
    background: Color(0xFF050505),
    backgroundAlt: Color(0xFF141414),
    nebula: Color(0xFF222222),
    panel: Color(0xFF111111),
    panelAlt: Color(0xFF1D1D1D),
    button: Color(0xFF232323),
    secondary: Color(0xFF333333),
    operator: Color(0xFF005F73),
    equals: Color(0xFFFFD166),
    warning: Color(0xFFB00020),
    accent: Color(0xFFFFFFFF),
    muted: Color(0xFFE6E6E6),
    border: Color(0xFFE6E6E6),
    goldBorder: Color(0xFFFFFFFF),
    warningBorder: Color(0xFFFFB3C1),
    glow: Color(0x1AFFFFFF),
    warmGlow: Color(0x22FFFFFF),
  );
}
