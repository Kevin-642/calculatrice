import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_controller.dart';
import 'calculator_preferences.dart';

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

class _CalculatorScreenState extends State<CalculatorScreen>
    with TickerProviderStateMixin {
  late final CalculatorController _controller;
  late final AnimationController _cosmicEntrance;
  late final AnimationController _spaceMotion;
  late final AnimationController _resultPulse;
  late final Animation<double> _contentReveal;

  @override
  void initState() {
    super.initState();
    _controller = CalculatorController(
      preferences: NativeCalculatorPreferences(),
    )..addListener(_onControllerChanged);
    _cosmicEntrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _spaceMotion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _resultPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _contentReveal = CurvedAnimation(
      parent: _cosmicEntrance,
      curve: const Interval(0.22, 0.78, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeExperience();
    });
  }

  Future<void> _initializeExperience() async {
    await _controller.initialize();
    if (!mounted) {
      return;
    }
    if (_controller.launchSeen) {
      _cosmicEntrance.duration = const Duration(milliseconds: 650);
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _cosmicEntrance.value = 1;
    } else {
      _cosmicEntrance.forward();
      _spaceMotion.repeat();
    }
    _controller.markLaunchSeen();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _cosmicEntrance.dispose();
    _spaceMotion.dispose();
    _resultPulse.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) &&
        !_cosmicEntrance.isCompleted) {
      _cosmicEntrance.value = 1;
      _spaceMotion.stop();
    }
  }

  void _handleKey(String key) {
    if (key == '=') {
      HapticFeedback.mediumImpact();
      _resultPulse.forward(from: 0);
    } else {
      HapticFeedback.selectionClick();
    }
    _controller.handleKey(key);
  }

  Future<void> _editExpression() async {
    final textController = TextEditingController(text: _controller.expression);
    textController.selection = TextSelection.collapsed(
      offset: textController.text.length,
    );
    final expression = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l’expression'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: 'Ex. sin(30)+sqrt(16)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (expression != null) {
      _controller.setExpression(expression);
    }
  }

  Future<void> _copyText(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Copié dans le presse-papiers'),
            duration: Duration(seconds: 1),
          ),
        );
    }
  }

  void _showGraph() {
    final expression = _controller.expression.toLowerCase().contains('x')
        ? _controller.expression
        : 'sin(x)';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _GraphSheet(initialExpression: expression, controller: _controller),
    );
  }

  void _showConversions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ConversionSheet(),
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _controller.highContrast
        ? _ContrastPalette.high
        : _ContrastPalette.space;

    return Scaffold(
      backgroundColor: colors.background,
      body: AnimatedBuilder(
        animation: _cosmicEntrance,
        builder: (context, child) {
          final progress = _cosmicEntrance.value;
          return Container(
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
                  child: AnimatedBuilder(
                    animation: _spaceMotion,
                    builder: (context, child) => CustomPaint(
                      painter: _GalaxyPainter(
                        colors,
                        reveal: progress,
                        drift: _spaceMotion.value,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: _contentReveal.value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - _contentReveal.value)),
                    child: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth > 700
                                    ? 820
                                    : 460,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  children: <Widget>[
                                    _Header(
                                      highContrast: _controller.highContrast,
                                      colors: colors,
                                      onContrastChanged: () {
                                        _controller.toggleHighContrast();
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    AnimatedBuilder(
                                      animation: _resultPulse,
                                      builder: (context, child) {
                                        final pulse =
                                            math.sin(
                                              _resultPulse.value * math.pi,
                                            ) *
                                            0.025;
                                        return Transform.scale(
                                          scale: 1 + pulse,
                                          child: child,
                                        );
                                      },
                                      child: _DisplayPanel(
                                        preview: _controller.preview,
                                        display: _controller.display,
                                        errorMessage: _controller.errorMessage,
                                        colors: colors,
                                        onTap: _editExpression,
                                        onLongPress: () =>
                                            _copyText(_controller.display),
                                      ),
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
                                                  icon:
                                                      Icons.backspace_outlined,
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
                                                CalculatorKey(',', label: ','),
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
                                              onLongPress:
                                                  _controller.handleLongPress,
                                            ),
                                            const SizedBox(height: 12),
                                            _ScientificToggle(
                                              visible:
                                                  _controller.scientificVisible,
                                              onTap:
                                                  _controller.toggleScientific,
                                              colors: colors,
                                            ),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child:
                                                  _controller.scientificVisible
                                                  ? Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 12,
                                                          ),
                                                      child: Column(
                                                        children: <Widget>[
                                                          _KeyGrid(
                                                            keys: const <CalculatorKey>[
                                                              CalculatorKey(
                                                                'sin',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'cos',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'tan',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'log',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'ln',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'sqrt',
                                                                label: 'sqrt',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'x2',
                                                                label: 'x²',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                '^',
                                                                label: 'xʸ',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'percent',
                                                                label: '%',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'inverse',
                                                                label: '1/x',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'abs',
                                                                label: '|x|',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'negate',
                                                                label: '±',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'factorial',
                                                                label: 'n!',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'pi',
                                                                label: 'pi',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'e',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'exp',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'MC',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'MR',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'M+',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'M-',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'ANS',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                              CalculatorKey(
                                                                'x',
                                                                style: KeyStyle
                                                                    .secondary,
                                                              ),
                                                            ],
                                                            columns: 5,
                                                            colors: colors,
                                                            onTap: _handleKey,
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          _AngleModeToggle(
                                                            mode: _controller
                                                                .angleMode,
                                                            hasMemory:
                                                                _controller
                                                                    .hasMemory,
                                                            colors: colors,
                                                            onTap: _controller
                                                                .toggleAngleMode,
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: _showGraph,
                                                    icon: const Icon(
                                                      Icons.show_chart,
                                                    ),
                                                    label: const Text(
                                                      'Grapheur',
                                                    ),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              colors.accent,
                                                          side: BorderSide(
                                                            color: colors
                                                                .goldBorder,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: _showConversions,
                                                    icon: const Icon(
                                                      Icons.swap_horiz,
                                                    ),
                                                    label: const Text(
                                                      'Conversions',
                                                    ),
                                                    style:
                                                        OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              colors.accent,
                                                          side: BorderSide(
                                                            color: colors
                                                                .goldBorder,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _HistoryPanel(
                                              history: _controller.history,
                                              pinned: _controller.pinnedHistory,
                                              colors: colors,
                                              onClear:
                                                  _controller.history.isEmpty
                                                  ? null
                                                  : _controller.clearHistory,
                                              onSelected:
                                                  _controller.restoreHistory,
                                              onDelete:
                                                  _controller.deleteHistory,
                                              onPin: _controller
                                                  .toggleHistoryPinned,
                                              onCopy: _copyText,
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
                  ),
                ),
                if (progress < 1)
                  Positioned.fill(
                    child: _CosmicLaunchOverlay(
                      progress: progress,
                      colors: colors,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CosmicLaunchOverlay extends StatelessWidget {
  const _CosmicLaunchOverlay({required this.progress, required this.colors});

  final double progress;
  final _ContrastPalette colors;

  @override
  Widget build(BuildContext context) {
    final exit = const Interval(
      0.62,
      1,
      curve: Curves.easeInCubic,
    ).transform(progress);
    final logoReveal = Curves.elasticOut.transform(
      (progress / 0.62).clamp(0.0, 1.0),
    );

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: 1 - exit,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.15,
                colors: <Color>[
                  Color(0xFF241739),
                  Color(0xFF080D22),
                  Color(0xFF02040D),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  painter: _CosmicPortalPainter(
                    progress: progress,
                    colors: colors,
                  ),
                ),
                Center(
                  child: Transform.scale(
                    scale: 0.45 + logoReveal * 0.55,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 116,
                          height: 116,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: colors.glow.withValues(alpha: 0.9),
                                blurRadius: 42,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: colors.warmGlow,
                                blurRadius: 26,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/brand/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'CALCULATRICE COSMIQUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.4,
                            shadows: <Shadow>[
                              Shadow(color: colors.glow, blurRadius: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'INITIALISATION STELLAIRE',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CosmicPortalPainter extends CustomPainter {
  const _CosmicPortalPainter({required this.progress, required this.colors});

  final double progress;
  final _ContrastPalette colors;

  static const _points = <Offset>[
    Offset(0.08, 0.14),
    Offset(0.18, 0.34),
    Offset(0.29, 0.08),
    Offset(0.39, 0.24),
    Offset(0.52, 0.12),
    Offset(0.68, 0.26),
    Offset(0.84, 0.09),
    Offset(0.93, 0.38),
    Offset(0.12, 0.66),
    Offset(0.25, 0.86),
    Offset(0.45, 0.73),
    Offset(0.61, 0.91),
    Offset(0.78, 0.69),
    Offset(0.91, 0.88),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 24);
    final eased = Curves.easeOutCubic.transform(progress);
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              colors.accent.withValues(alpha: 0.35 * (1 - progress)),
              colors.glow.withValues(alpha: 0.28),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: size.shortestSide * 0.48),
          );
    canvas.drawCircle(center, size.shortestSide * 0.48, glow);

    for (var index = 0; index < _points.length; index++) {
      final pointProgress = (progress * 3 - index * 0.06).clamp(0.0, 1.0);
      if (pointProgress == 0) {
        continue;
      }
      final point = _points[index];
      final offset = Offset(point.dx * size.width, point.dy * size.height);
      final radius = index.isEven ? 1.5 : 0.8;
      final star = Paint()
        ..color = Colors.white.withValues(alpha: pointProgress);
      canvas.drawCircle(offset, radius, star);
      if (index % 3 == 0) {
        canvas.drawLine(
          offset.translate(-radius * 3, 0),
          offset.translate(radius * 3, 0),
          star..strokeWidth = 0.6,
        );
      }
    }

    for (var ring = 0; ring < 4; ring++) {
      final radius = 34 + eased * (105 + ring * 34);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring == 0 ? 2.2 : 1
        ..color = (ring.isEven ? colors.accent : colors.border).withValues(
          alpha: (0.58 - ring * 0.09) * (1 - progress * 0.45),
        );
      final rect = Rect.fromCenter(
        center: center,
        width: radius * 2.25,
        height: radius * (0.72 + ring * 0.08),
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-0.42 + ring * 0.24 + progress * 0.12);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawOval(rect, ringPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPortalPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter(this.colors, {required this.reveal, required this.drift});

  final _ContrastPalette colors;
  final double reveal;
  final double drift;

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
    _Star(0.05, 0.40, 0.6),
    _Star(0.20, 0.48, 1.5),
    _Star(0.38, 0.38, 0.7),
    _Star(0.55, 0.53, 1.0),
    _Star(0.68, 0.68, 1.6),
    _Star(0.94, 0.61, 0.7),
    _Star(0.08, 0.88, 1.2),
    _Star(0.22, 0.92, 0.5),
    _Star(0.41, 0.63, 0.8),
    _Star(0.59, 0.91, 0.7),
    _Star(0.77, 0.87, 1.4),
    _Star(0.96, 0.94, 0.9),
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

    final blueNebula = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              colors.border.withValues(alpha: 0.20 * reveal),
              colors.glow.withValues(alpha: 0.12 * reveal),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.08, size.height * 0.70),
              radius: size.width * 0.55,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.70),
      size.width * 0.55,
      blueNebula,
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

    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 + reveal * 0.65);
    for (var index = 0; index < _stars.length; index++) {
      final star = _stars[index];
      final phase = drift * math.pi * 2 + index * 0.73;
      final offset = Offset(
        size.width * star.x + math.sin(phase) * 2.4,
        size.height * star.y + math.cos(phase * 0.7) * 1.8,
      );
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

    final cometPaint = Paint()
      ..shader =
          LinearGradient(
            colors: <Color>[
              Colors.transparent,
              colors.accent.withValues(alpha: 0.75 * reveal),
            ],
          ).createShader(
            Rect.fromPoints(
              Offset(size.width * 0.03, size.height * 0.18),
              Offset(size.width * 0.30, size.height * 0.09),
            ),
          )
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.03, size.height * 0.18),
      Offset(size.width * 0.30, size.height * 0.09),
      cometPaint,
    );

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
    return oldDelegate.colors != colors ||
        oldDelegate.reveal != reveal ||
        oldDelegate.drift != drift;
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
    required this.errorMessage,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  final String preview;
  final String display;
  final String? errorMessage;
  final _ContrastPalette colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Ecran de la calculatrice',
      value: display.isEmpty ? 'Expression incomplete' : display,
      hint: 'Touchez pour modifier, appui long pour copier',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
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
                    shadows: <Shadow>[
                      Shadow(color: colors.glow, blurRadius: 12),
                    ],
                  ),
                ),
              ),
              if (errorMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colors.warningBorder,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
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
    this.onLongPress,
    this.columns = 4,
  });

  final List<CalculatorKey> keys;
  final _ContrastPalette colors;
  final ValueChanged<String> onTap;
  final ValueChanged<String>? onLongPress;
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
          onLongPress: onLongPress == null
              ? null
              : () => onLongPress!(key.value),
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
    this.onLongPress,
  });

  final CalculatorKey keyData;
  final _ContrastPalette colors;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
            onLongPress: onLongPress,
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

class _AngleModeToggle extends StatelessWidget {
  const _AngleModeToggle({
    required this.mode,
    required this.hasMemory,
    required this.colors,
    required this.onTap,
  });

  final AngleMode mode;
  final bool hasMemory;
  final _ContrastPalette colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDegrees = mode == AngleMode.degrees;
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.straighten, size: 18),
            label: Text(isDegrees ? 'Degrés' : 'Radians'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accent,
              side: BorderSide(color: colors.goldBorder),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          label: hasMemory ? 'Mémoire active' : 'Mémoire vide',
          child: Chip(
            avatar: Icon(
              Icons.memory,
              size: 17,
              color: hasMemory ? colors.accent : colors.muted,
            ),
            label: Text(hasMemory ? 'M active' : 'M vide'),
            backgroundColor: colors.panel,
            side: BorderSide(color: colors.border),
            labelStyle: TextStyle(color: colors.muted),
          ),
        ),
      ],
    );
  }
}

class _HistoryPanel extends StatefulWidget {
  const _HistoryPanel({
    required this.history,
    required this.pinned,
    required this.colors,
    required this.onClear,
    required this.onSelected,
    required this.onDelete,
    required this.onPin,
    required this.onCopy,
  });

  final List<String> history;
  final Set<String> pinned;
  final _ContrastPalette colors;
  final VoidCallback? onClear;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onPin;
  final ValueChanged<String> onCopy;

  @override
  State<_HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<_HistoryPanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final visibleHistory =
        widget.history
            .where((item) => item.toLowerCase().contains(_query.toLowerCase()))
            .toList(growable: false)
          ..sort((left, right) {
            final leftPinned = widget.pinned.contains(left);
            final rightPinned = widget.pinned.contains(right);
            return leftPinned == rightPinned ? 0 : (leftPinned ? -1 : 1);
          });
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
                onPressed: widget.onClear,
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
          if (widget.history.length > 5) ...<Widget>[
            TextField(
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Rechercher un calcul',
                hintStyle: TextStyle(color: colors.muted),
                prefixIcon: const Icon(Icons.search, size: 19),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (visibleHistory.isEmpty)
            Text(
              widget.history.isEmpty ? 'Aucun calcul' : 'Aucun résultat',
              style: TextStyle(color: colors.muted.withValues(alpha: 0.75)),
            )
          else
            ...visibleHistory
                .take(20)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () => widget.onSelected(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            if (widget.pinned.contains(item))
                              Icon(
                                Icons.push_pin,
                                size: 16,
                                color: colors.accent,
                              ),
                            PopupMenuButton<_HistoryAction>(
                              tooltip: 'Actions du calcul',
                              icon: Icon(
                                Icons.more_vert,
                                size: 18,
                                color: colors.muted,
                              ),
                              onSelected: (action) {
                                switch (action) {
                                  case _HistoryAction.copy:
                                    widget.onCopy(item);
                                  case _HistoryAction.pin:
                                    widget.onPin(item);
                                  case _HistoryAction.delete:
                                    widget.onDelete(item);
                                }
                              },
                              itemBuilder: (context) =>
                                  <PopupMenuEntry<_HistoryAction>>[
                                    const PopupMenuItem(
                                      value: _HistoryAction.copy,
                                      child: ListTile(
                                        leading: Icon(Icons.copy),
                                        title: Text('Copier'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _HistoryAction.pin,
                                      child: ListTile(
                                        leading: Icon(
                                          widget.pinned.contains(item)
                                              ? Icons.push_pin_outlined
                                              : Icons.push_pin,
                                        ),
                                        title: Text(
                                          widget.pinned.contains(item)
                                              ? 'Désépingler'
                                              : 'Épingler',
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: _HistoryAction.delete,
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline),
                                        title: Text('Supprimer'),
                                      ),
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

enum _HistoryAction { copy, pin, delete }

class _GraphSheet extends StatefulWidget {
  const _GraphSheet({
    required this.initialExpression,
    required this.controller,
  });

  final String initialExpression;
  final CalculatorController controller;

  @override
  State<_GraphSheet> createState() => _GraphSheetState();
}

class _GraphSheetState extends State<_GraphSheet> {
  late final TextEditingController _expressionController;
  double _range = 10;
  double _centerX = 0;
  double _scaleStartRange = 10;
  String? _error;

  @override
  void initState() {
    super.initState();
    _expressionController = TextEditingController(
      text: widget.initialExpression,
    );
  }

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  double? _evaluate(double x) {
    try {
      final value = widget.controller.evaluateForGraph(
        _expressionController.text,
        x,
      );
      return value.isFinite ? value : null;
    } on FormatException catch (error) {
      _error = error.message.toString();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.58,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Material(
        color: const Color(0xFF0B1024),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(18),
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Grapheur cosmique',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Utilisez x, puis pincez ou glissez le graphique.',
                style: TextStyle(color: Color(0xFFAEB9D7)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _expressionController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'f(x)',
                  hintText: 'sin(x) ou x^2',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Tracer',
                    onPressed: () => setState(() => _error = null),
                    icon: const Icon(Icons.play_arrow),
                  ),
                ),
                onSubmitted: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 14),
              AspectRatio(
                aspectRatio: 1.25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: GestureDetector(
                    onScaleStart: (_) => _scaleStartRange = _range,
                    onScaleUpdate: (details) {
                      setState(() {
                        _range = (_scaleStartRange / details.scale).clamp(
                          1.0,
                          100.0,
                        );
                        _centerX -=
                            details.focalPointDelta.dx /
                            context.size!.width *
                            _range *
                            2;
                      });
                    },
                    child: CustomPaint(
                      painter: _GraphPainter(
                        evaluate: _evaluate,
                        range: _range,
                        centerX: _centerX,
                        lineColor: theme.colorScheme.tertiary,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              Row(
                children: <Widget>[
                  const Text('Zoom'),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: 50,
                      value: _range.clamp(1, 50),
                      onChanged: (value) => setState(() => _range = value),
                    ),
                  ),
                  Text('±${_range.toStringAsFixed(0)}'),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _range = 10;
                  _centerX = 0;
                }),
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Recentrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.evaluate,
    required this.range,
    required this.centerX,
    required this.lineColor,
  });

  final double? Function(double x) evaluate;
  final double range;
  final double centerX;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050817),
    );
    final grid = Paint()
      ..color = const Color(0xFF2B355A)
      ..strokeWidth = 0.7;
    for (var step = 0; step <= 10; step++) {
      final x = size.width * step / 10;
      final y = size.height * step / 10;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), grid)
        ..drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final pixelsPerUnit = size.width / (range * 2);
    final originX = size.width / 2 - centerX * pixelsPerUnit;
    final originY = size.height / 2;
    final axes = Paint()
      ..color = const Color(0xFF9EABD0)
      ..strokeWidth = 1.2;
    if (originX >= 0 && originX <= size.width) {
      canvas.drawLine(Offset(originX, 0), Offset(originX, size.height), axes);
    }
    canvas.drawLine(Offset(0, originY), Offset(size.width, originY), axes);

    final path = Path();
    var segmentStarted = false;
    for (var pixel = 0.0; pixel <= size.width; pixel += 1.25) {
      final x = centerX + (pixel - size.width / 2) / pixelsPerUnit;
      final y = evaluate(x);
      if (y == null || y.abs() > range * 8) {
        segmentStarted = false;
        continue;
      }
      final point = Offset(pixel, originY - y * pixelsPerUnit);
      if (!segmentStarted) {
        path.moveTo(point.dx, point.dy);
        segmentStarted = true;
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return oldDelegate.range != range ||
        oldDelegate.centerX != centerX ||
        oldDelegate.evaluate != evaluate ||
        oldDelegate.lineColor != lineColor;
  }
}

class _ConversionSheet extends StatefulWidget {
  const _ConversionSheet();

  @override
  State<_ConversionSheet> createState() => _ConversionSheetState();
}

class _ConversionSheetState extends State<_ConversionSheet> {
  late final TextEditingController _valueController;
  String _category = _conversionCategories.keys.first;
  late String _from;
  late String _to;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: '1');
    _resetUnits();
  }

  void _resetUnits() {
    final units = _conversionCategories[_category]!.units.keys.toList();
    _from = units.first;
    _to = units.length > 1 ? units[1] : units.first;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String get _result {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value == null) {
      return 'Valeur invalide';
    }
    final category = _conversionCategories[_category]!;
    final base = category.units[_from]!.toBase(value);
    final result = category.units[_to]!.fromBase(base);
    return '${_formatConversion(result)} $_to';
  }

  @override
  Widget build(BuildContext context) {
    final category = _conversionCategories[_category]!;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Material(
        color: const Color(0xFF0B1024),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeArea(
          top: false,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(18),
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Convertisseur',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: _conversionCategories.keys
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                      _resetUnits();
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valeur',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _UnitDropdown(
                      label: 'De',
                      value: _from,
                      units: category.units.keys,
                      onChanged: (value) => setState(() => _from = value),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Inverser les unités',
                    onPressed: () => setState(() {
                      final previous = _from;
                      _from = _to;
                      _to = previous;
                    }),
                    icon: const Icon(Icons.swap_horiz),
                  ),
                  Expanded(
                    child: _UnitDropdown(
                      label: 'Vers',
                      value: _to,
                      units: category.units.keys,
                      onChanged: (value) => setState(() => _to = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Semantics(
                liveRegion: true,
                label: 'Résultat de la conversion',
                value: _result,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17213D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD58A)),
                  ),
                  child: SelectableText(
                    _result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE2B3),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({
    required this.label,
    required this.value,
    required this.units,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Iterable<String> units;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: units
          .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
          .toList(),
      onChanged: (unit) {
        if (unit != null) {
          onChanged(unit);
        }
      },
    );
  }
}

class _ConversionCategory {
  const _ConversionCategory(this.units);

  final Map<String, _UnitConversion> units;
}

class _UnitConversion {
  const _UnitConversion({required this.toBase, required this.fromBase});

  final double Function(double) toBase;
  final double Function(double) fromBase;
}

_UnitConversion _factor(double factor) => _UnitConversion(
  toBase: (value) => value * factor,
  fromBase: (value) => value / factor,
);

final Map<String, _ConversionCategory> _conversionCategories =
    <String, _ConversionCategory>{
      'Longueur': _ConversionCategory(<String, _UnitConversion>{
        'mm': _factor(0.001),
        'cm': _factor(0.01),
        'm': _factor(1),
        'km': _factor(1000),
        'in': _factor(0.0254),
        'ft': _factor(0.3048),
        'mi': _factor(1609.344),
      }),
      'Masse': _ConversionCategory(<String, _UnitConversion>{
        'mg': _factor(0.000001),
        'g': _factor(0.001),
        'kg': _factor(1),
        't': _factor(1000),
        'oz': _factor(0.028349523125),
        'lb': _factor(0.45359237),
      }),
      'Température': _ConversionCategory(<String, _UnitConversion>{
        '°C': _UnitConversion(
          toBase: (value) => value,
          fromBase: (value) => value,
        ),
        '°F': _UnitConversion(
          toBase: (value) => (value - 32) * 5 / 9,
          fromBase: (value) => value * 9 / 5 + 32,
        ),
        'K': _UnitConversion(
          toBase: (value) => value - 273.15,
          fromBase: (value) => value + 273.15,
        ),
      }),
      'Vitesse': _ConversionCategory(<String, _UnitConversion>{
        'm/s': _factor(1),
        'km/h': _factor(1 / 3.6),
        'mph': _factor(0.44704),
        'nœud': _factor(0.514444),
      }),
      'Volume': _ConversionCategory(<String, _UnitConversion>{
        'mL': _factor(0.001),
        'cL': _factor(0.01),
        'L': _factor(1),
        'm³': _factor(1000),
        'gal US': _factor(3.785411784),
      }),
      'Angle': _ConversionCategory(<String, _UnitConversion>{
        'degré': _factor(math.pi / 180),
        'radian': _factor(1),
        'grade': _factor(math.pi / 200),
      }),
    };

String _formatConversion(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  if (value.abs() >= 1e12 || (value != 0 && value.abs() < 1e-9)) {
    return value.toStringAsExponential(8);
  }
  return value.toStringAsPrecision(12).replaceFirst(RegExp(r'\.?0+$'), '');
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
      '^' => 'Puissance',
      ',' => 'Virgule décimale',
      'percent' => 'Pourcentage',
      'inverse' => 'Inverse',
      'abs' => 'Valeur absolue',
      'negate' => 'Changer le signe',
      'factorial' => 'Factorielle',
      'pi' => 'Pi',
      'MC' => 'Effacer la mémoire',
      'MR' => 'Rappeler la mémoire',
      'M+' => 'Ajouter à la mémoire',
      'M-' => 'Soustraire de la mémoire',
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
