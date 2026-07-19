import 'dart:async';

import 'package:flutter/services.dart';

class CalculatorSettings {
  const CalculatorSettings({
    this.history = const <String>[],
    this.pinnedHistory = const <String>[],
    this.highContrast = false,
    this.radians = false,
    this.memory = 0,
    this.launchSeen = false,
  });

  final List<String> history;
  final List<String> pinnedHistory;
  final bool highContrast;
  final bool radians;
  final double memory;
  final bool launchSeen;
}

abstract interface class CalculatorPreferences {
  Future<CalculatorSettings> load();

  Future<void> save({
    required List<String> history,
    required List<String> pinnedHistory,
    required bool highContrast,
    required bool radians,
    required double memory,
    required bool launchSeen,
  });
}

class NativeCalculatorPreferences implements CalculatorPreferences {
  static const _channel = MethodChannel(
    'com.kevincreation.calculatricecosmique/preferences',
  );

  @override
  Future<CalculatorSettings> load() async {
    try {
      final values = await _channel
          .invokeMapMethod<String, dynamic>('load')
          .timeout(const Duration(milliseconds: 200));
      return CalculatorSettings(
        history: (values?['history'] as List<Object?>? ?? const <Object?>[])
            .whereType<String>()
            .toList(growable: false),
        pinnedHistory:
            (values?['pinnedHistory'] as List<Object?>? ?? const <Object?>[])
                .whereType<String>()
                .toList(growable: false),
        highContrast: values?['highContrast'] as bool? ?? false,
        radians: values?['radians'] as bool? ?? false,
        memory: (values?['memory'] as num?)?.toDouble() ?? 0,
        launchSeen: values?['launchSeen'] as bool? ?? false,
      );
    } on PlatformException {
      return const CalculatorSettings();
    } on MissingPluginException {
      return const CalculatorSettings();
    } on TimeoutException {
      return const CalculatorSettings();
    }
  }

  @override
  Future<void> save({
    required List<String> history,
    required List<String> pinnedHistory,
    required bool highContrast,
    required bool radians,
    required double memory,
    required bool launchSeen,
  }) async {
    try {
      await _channel.invokeMethod<void>('save', <String, Object>{
        'history': history,
        'pinnedHistory': pinnedHistory,
        'highContrast': highContrast,
        'radians': radians,
        'memory': memory,
        'launchSeen': launchSeen,
      });
    } on PlatformException {
      // A storage failure must not interrupt a calculation.
    } on MissingPluginException {
      // The native channel is intentionally absent in widget tests.
    }
  }
}
