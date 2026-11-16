import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/theme/app_theme.dart';
import 'package:rideros_ai/features/dashboard/presentation/widgets/rider_banner.dart';
import 'package:rideros_ai/l10n/app_localizations.dart';
import 'package:rideros_ai/l10n/app_localizations_th.dart';

final t = AppLocalizationsTh();

Future<void> _pump(
  WidgetTester tester, {
  String name = 'Demo Rider',
  bool reduceMotion = false,
  double textScale = 1,
  double width = 360,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: const Locale('th'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [RiderGreetingBanner(name: name)],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('greets the rider by name, read as one sentence', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(t.homeHello), findsOneWidget);
    expect(find.text('Demo Rider'), findsOneWidget);
    expect(find.text(t.homeBannerMessage), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        '${t.homeGreeting('Demo Rider')}, ${t.homeBannerMessage}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the rider rides in once, then the scene holds still', (
    tester,
  ) async {
    await _pump(tester);
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('with reduced motion the rider is already parked', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: true);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('long names and large text fit on a small phone, both themes', (
    tester,
  ) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await _pump(
        tester,
        name: 'Somchai Rattanaphongphaisan Delivery',
        width: 320,
        textScale: 2,
        theme: theme,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final name = tester.widget<Text>(
        find.text('Somchai Rattanaphongphaisan Delivery'),
      );
      expect(name.maxLines, 2);
    }
  });
}
