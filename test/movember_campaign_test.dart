import 'package:calculatrice_cosmique/main.dart';
import 'package:calculatrice_cosmique/movember_campaign.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('campaign is exclusive to November 2026 and can be disabled', () {
    expect(isMovember2026(DateTime(2026, 10, 31, 23, 59)), isFalse);
    expect(isMovember2026(DateTime(2026, 11)), isTrue);
    expect(isMovember2026(DateTime(2026, 11, 30, 23, 59)), isTrue);
    expect(isMovember2026(DateTime(2026, 12)), isFalse);
    expect(isMovember2026(DateTime(2027, 11)), isFalse);
    expect(isMovember2026(DateTime(2026, 11), enabled: false), isFalse);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(800, 1280),
  ]) {
    testWidgets('campaign preserves calculation and layout at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var date = DateTime(2026, 11, 30, 23, 59, 59);
      await tester.pumpWidget(
        MaterialApp(
          home: MovemberCampaign(
            now: () => date,
            child: const CalculatorScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('movember-card')), findsOneWidget);
      for (final key in ['2', '+', '3', '=']) {
        await tester.ensureVisible(find.text(key).first);
        await tester.tap(find.text(key).first);
        await tester.pump();
      }
      expect(find.text('2+3 = 5'), findsOneWidget);
      await tester.ensureVisible(find.text(movemberMessage));
      await tester.pump();
      expect(tester.takeException(), isNull);
      date = DateTime(2026, 12);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('movember-card')), findsNothing);
      expect(find.text('2+3 = 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('resume refreshes campaign after background date change', (
    tester,
  ) async {
    var date = DateTime(2026, 10, 31);
    await tester.pumpWidget(
      MaterialApp(
        home: MovemberCampaign(
          now: () => date,
          child: const Scaffold(
            body: SingleChildScrollView(child: MovemberCard()),
          ),
        ),
      ),
    );
    expect(find.text(movemberMessage), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    date = DateTime(2026, 11);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text(movemberMessage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
