import 'dart:async';

import 'package:flutter/material.dart';

const movemberAsset = 'assets/brand/movember_2026.png';
const movemberMessage =
    '🪐🥸 Même dans l’espace, on parle de santé masculine ! '
    'Movember : sensibilisons, échangeons et soutenons-nous. 💙';

bool isMovember2026(DateTime date, {bool enabled = true}) =>
    enabled && date.year == 2026 && date.month == 11;

/// Presentation only: never writes calculator preferences or history.
class MovemberCampaign extends StatefulWidget {
  const MovemberCampaign({
    super.key,
    required this.child,
    this.now,
    this.enabled = const bool.fromEnvironment(
      'MOVEMBER_ENABLED',
      defaultValue: true,
    ),
  });

  final Widget child;
  final DateTime Function()? now;
  final bool enabled;

  @override
  State<MovemberCampaign> createState() => _MovemberCampaignState();
}

class _MovemberCampaignState extends State<MovemberCampaign>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  void _refresh() {
    _timer?.cancel();
    final now = (widget.now ?? DateTime.now)().toLocal();
    _active = isMovember2026(now, enabled: widget.enabled);
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now), () {
      if (mounted) setState(_refresh);
    });
  }

  @override
  void didUpdateWidget(covariant MovemberCampaign oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_refresh);
    if (state == AppLifecycleState.paused) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MovemberScope(active: _active, child: widget.child);
}

class MovemberScope extends InheritedWidget {
  const MovemberScope({super.key, required this.active, required super.child});
  final bool active;
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MovemberScope>()?.active ??
      false;
  @override
  bool updateShouldNotify(MovemberScope oldWidget) =>
      active != oldWidget.active;
}

class MovemberCard extends StatelessWidget {
  const MovemberCard({super.key});
  @override
  Widget build(BuildContext context) {
    if (!MovemberScope.of(context)) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('movember-card'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151D38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF779FE4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Movember 2026',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            movemberMessage,
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }
}
