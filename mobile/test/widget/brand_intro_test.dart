import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/intro/brand_intro.dart';
import 'package:rideros_ai/app/intro/ride_scene.dart';
import 'package:rideros_ai/app/theme/tokens.dart';
import 'package:rideros_ai/l10n/app_localizations.dart';

import '../helpers/file_bundle.dart';

void main() {
  var taps = 0;
  setUp(() => taps = 0);

  Widget app({required bool waiting}) => DefaultAssetBundle(
    bundle: FileAssetBundle(),
    child: MaterialApp(
      locale: const Locale('th'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => BrandIntro(waiting: waiting, child: child!),
      home: Scaffold(
        body: Center(
          child: TextButton(onPressed: () => taps++, child: const Text('dash')),
        ),
      ),
    ),
  );

  final logo = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is RideScenePainter,
  );
  const frame = Duration(milliseconds: 16);

  /// Plays [time] at 60 fps, as a device would.
  Future<void> play(WidgetTester tester, Duration time) async {
    for (var t = Duration.zero; t < time; t += frame) {
      await tester.pump(frame);
    }
  }

  testWidgets('draws the logo over the app, then hands over in about 3 s', (
    tester,
  ) async {
    await tester.pumpWidget(app(waiting: false));
    await tester.pump();
    expect(logo, findsOneWidget);

    // Blocks the screen underneath while it plays.
    await tester.tap(find.text('dash'), warnIfMissed: false);
    expect(taps, 0);

    await play(tester, const Duration(milliseconds: 2500));
    expect(logo, findsOneWidget);
    await play(tester, const Duration(milliseconds: 700));
    expect(logo, findsNothing);
    expect(
      (AppDurations.introReveal + AppDurations.introExit).inMilliseconds,
      inInclusiveRange(2800, 3200),
    );

    await tester.tap(find.text('dash'));
    expect(taps, 1);
  });

  testWidgets('holds the finished logo while the session is resumed', (
    tester,
  ) async {
    await tester.pumpWidget(app(waiting: true));
    await tester.pump();
    await play(tester, const Duration(seconds: 6));
    expect(logo, findsOneWidget);

    await tester.pumpWidget(app(waiting: false));
    await play(tester, const Duration(milliseconds: 600));
    expect(logo, findsNothing);
    expect(find.text('dash'), findsOneWidget);
  });
}
