import 'package:flutter/services.dart';

class CalculatorSettings {
  const CalculatorSettings({
    this.history = const <String>[],
    this.highContrast = false,
    this.radians = false,
    this.memory = 0,
  });

  final List<String> history;
  final bool highContrast;
  final bool radians;
  final double memory;
}

abstract interface class CalculatorPreferences {
  Future<CalculatorSettings> load();

  Future<void> save({
    required List<String> history,
    required bool highContrast,
    required bool radians,
    required double memory,
  });
}

class NativeCalculatorPreferences implements CalculatorPreferences {
  static const _channel = MethodChannel(
    'com.kevincreation.calculatricecosmique/preferences',
  );

  @override
  Future<CalculatorSettings> load() async {
    try {
      final values = await _channel.invokeMapMethod<String, dynamic>('load');
      return CalculatorSettings(
        history: (values?['history'] as List<Object?>? ?? const <Object?>[])
            .whereType<String>()
            .toList(growable: false),
        highContrast: values?['highContrast'] as bool? ?? false,
        radians: values?['radians'] as bool? ?? false,
        memory: (values?['memory'] as num?)?.toDouble() ?? 0,
      );
    } on MissingPluginException {
      return const CalculatorSettings();
    }
  }

  @override
  Future<void> save({
    required List<String> history,
    required bool highContrast,
    required bool radians,
    required double memory,
  }) async {
    try {
      await _channel.invokeMethod<void>('save', <String, Object>{
        'history': history,
        'highContrast': highContrast,
        'radians': radians,
        'memory': memory,
      });
    } on MissingPluginException {
      // The native channel is intentionally absent in widget tests.
    }
  }
}
