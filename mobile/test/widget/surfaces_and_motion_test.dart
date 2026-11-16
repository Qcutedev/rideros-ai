import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/theme/app_theme.dart';
import 'package:rideros_ai/app/theme/tokens.dart';
import 'package:rideros_ai/core/widgets/app_surfaces.dart';
import 'package:rideros_ai/core/widgets/motion.dart';
import 'package:rideros_ai/core/widgets/status_views.dart';
import 'package:rideros_ai/l10n/app_localizations.dart';

/// WCAG 2.1 contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: const Locale('th'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('tones keep text readable (WCAG AA 4.5:1)', () {
    for (final brightness in Brightness.values) {
      for (final tone in AppTone.values) {
        test('${brightness.name} ${tone.name}', () {
          final theme = AppTheme.toned(brightness, tone);
          final scheme = theme.colorScheme;
          final semantic = theme.extension<AppSemanticColors>()!;
          final surface = scheme.surface;
          expect(_contrast(scheme.onSurface, surface), greaterThan(4.5));
          expect(_contrast(scheme.onSurfaceVariant, surface), greaterThan(4.5));
          expect(_contrast(scheme.error, surface), greaterThan(4.5));
          expect(_contrast(semantic.success, surface), greaterThan(4.5));
          // Text on the soft tiles (metric tiles, banners) inside the tone.
          expect(
            _contrast(scheme.onSurfaceVariant, semantic.mint),
            greaterThan(4.5),
          );
          // Filled buttons.
          expect(_contrast(scheme.onPrimary, scheme.primary), greaterThan(4.5));
          // Lime fills always carry their own content colour.
          expect(
            _contrast(semantic.onAccent, semantic.accent),
            greaterThan(4.5),
          );
        });
      }
    }

    test('hero figures on the Obsidian card', () {
      for (final brightness in Brightness.values) {
        final theme = AppTheme.toned(brightness, AppTone.obsidian);
        final semantic = theme.extension<AppSemanticColors>()!;
        final surface = theme.colorScheme.surface;
        expect(_contrast(semantic.heroPositive, surface), greaterThan(4.5));
        expect(_contrast(semantic.heroNegative, surface), greaterThan(4.5));
      }
    });

    test('toned themes are built once and cached', () {
      expect(
        identical(
          AppTheme.toned(Brightness.light, AppTone.sage),
          AppTheme.toned(Brightness.light, AppTone.sage),
        ),
        isTrue,
      );
      expect(AppTheme.toned(Brightness.dark, AppTone.paper), AppTheme.dark);
    });
  });

  testWidgets('ToneCard gives its content the tone theme and is pressable', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      ToneCard(
        tone: AppTone.obsidian,
        onTap: () => taps++,
        child: Builder(
          builder: (context) => Text(
            'inside',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('inside'));
    expect(
      text.style?.color,
      AppTheme.toned(Brightness.light, AppTone.obsidian).colorScheme.onSurface,
    );
    expect(find.byType(PressableScale), findsOneWidget);
    await tester.tap(find.text('inside'));
    expect(taps, 1);
  });

  testWidgets('AnimatedFigure counts up and ends on the exact text', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      AnimatedFigure(
        value: 1049.5,
        text: '฿1,049.50',
        format: (v) => '฿${v.toStringAsFixed(2)}',
        textKey: const Key('figure'),
      ),
    );
    // Mid-animation the figure is on its way, but screen readers hear the
    // final amount only.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('฿1,049.50'), findsNothing);
    expect(find.bySemanticsLabel('฿1,049.50'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('฿1,049.50'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('with reduced motion figures and pulses hold still', (
    tester,
  ) async {
    await _pump(
      tester,
      Column(
        children: [
          AnimatedFigure(
            value: 12,
            text: '12',
            format: (v) => v.toStringAsFixed(0),
          ),
          const AiPulse(),
          const Shimmer(child: SizedBox(height: 10, width: 10)),
        ],
      ),
      reduceMotion: true,
    );
    expect(find.text('12'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('decorative loops are bounded, so the screen settles', (
    tester,
  ) async {
    await _pump(
      tester,
      const Column(
        children: [
          AiPulse(),
          Shimmer(child: SizedBox(height: 10, width: 10)),
        ],
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('AiLoadingView announces its message', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const AiLoadingView(message: 'กำลังประมาณเวลา'),
      reduceMotion: true,
    );
    expect(find.byType(AiPulse), findsOneWidget);
    expect(find.bySemanticsLabel('กำลังประมาณเวลา'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('PillTabBar switches tabs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: const PillTabBar(
                tabs: [
                  Tab(text: 'A'),
                  Tab(text: 'B'),
                ],
              ),
            ),
            body: const TabBarView(children: [Text('page A'), Text('page B')]),
          ),
        ),
      ),
    );
    expect(find.text('page A'), findsOneWidget);
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(find.text('page B'), findsOneWidget);
  });

  testWidgets('AppProgressBar animates to its value', (tester) async {
    await _pump(tester, const AppProgressBar(value: 0.5));
    await tester.pumpAndSettle();
    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.widthFactor, 0.5);
  });

  testWidgets('SuccessCheck pops in', (tester) async {
    await _pump(tester, const SuccessCheck());
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('IconWell defaults to lime with Obsidian content', (
    tester,
  ) async {
    await _pump(tester, const IconWell(icon: Icons.bolt_rounded));
    final icon = tester.widget<Icon>(find.byIcon(Icons.bolt_rounded));
    expect(icon.color, AppColors.obsidian);
  });
}
