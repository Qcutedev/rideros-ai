import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/router.dart';
import 'package:rideros_ai/app/theme/app_theme.dart';
import 'package:rideros_ai/app/theme/tokens.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/widgets/status_views.dart';
import 'package:rideros_ai/features/profit/domain/profit_heatmap.dart';
import 'package:rideros_ai/features/profit/presentation/profit_providers.dart';
import 'package:rideros_ai/features/profit/presentation/true_profit_screen.dart';
import 'package:rideros_ai/features/profit/presentation/widgets/profit_heatmap_card.dart';
import 'package:rideros_ai/l10n/app_localizations.dart';

import '../helpers/fakes.dart';
import '../helpers/profit_fakes.dart';
import '../helpers/pump.dart';

void main() {
  late ProfitFakes profit;

  setUp(() => profit = ProfitFakes());

  List<Override> overrides() => fakeRepositories(
    FakeAuthRepository()..restoreUser = testUser,
    FakeRiderProfileRepository(configured: true),
    profit,
  );

  Future<void> pumpCard(WidgetTester tester, {bool settle = true}) =>
      pumpScreen(
        tester,
        path: Routes.profit,
        screen: const Scaffold(
          body: SingleChildScrollView(child: ProfitHeatmapCard()),
        ),
        overrides: overrides(),
        settle: settle,
      );

  /// Monday 18–20 best, Friday 18–20 second, Saturday 10–12 third, a loss on
  /// Tuesday 06–08, a thin cell on Sunday 22–24.
  ProfitHeatmap okMap({int excludedIncome = 0}) => profitHeatmap(
    status: HeatmapStatus.ok,
    sessions: 24,
    netPerHour: '141.25',
    hours: '60.0',
    excludedIncome: excludedIncome,
    cells: [
      heatCell(0, 9, netPerHour: '220.00', hours: '20.0', count: 10),
      heatCell(1, 3, netPerHour: '-15.00', hours: '4.0', count: 2),
      heatCell(4, 9, netPerHour: '180.50'),
      heatCell(5, 5, netPerHour: '120.00'),
      heatCell(6, 11, netPerHour: null, hours: '0.5', count: 1),
    ],
  );

  Color fillOf(WidgetTester tester, int weekday, int slot) {
    final box = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(Key('heatmap.cell.$weekday.$slot')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  Finder inCell(int weekday, int slot, String text) => find.descendant(
    of: find.byKey(Key('heatmap.cell.$weekday.$slot')),
    matching: find.text(text),
  );

  testWidgets('loading skeleton, then too few sessions with progress', (
    tester,
  ) async {
    profit.profit
      ..gate = Completer<void>()
      ..heatmapResult = profitHeatmap(sessions: 4, excludedSessions: 3);
    await pumpCard(tester, settle: false);
    await tester.pump();
    expect(find.byType(SkeletonBox), findsOneWidget);
    profit.profit.gate!.complete();
    await tester.pumpAndSettle();

    expect(find.text(t.profitHeatmapTitle), findsOneWidget);
    expect(find.text(t.profitHeatmapInsufficient(6)), findsOneWidget);
    expect(find.text(t.profitHeatmapProgress(4, 10, 90)), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const Key('heatmap.progress')),
    );
    expect(bar.value, closeTo(0.4, 1e-9));
    expect(find.text(t.profitHeatmapUnpaidSessions(3)), findsOneWidget);
    expect(find.text(t.profitHeatmapTimerHint), findsOneWidget);
    expect(find.text(t.badgeEstimate), findsNothing);
    expect(find.byKey(const Key('heatmap.grid')), findsNothing);
  });

  testWidgets('no unpaid hint when every session has income', (tester) async {
    profit.profit.heatmapResult = profitHeatmap(sessions: 9);
    await pumpCard(tester);
    expect(find.text(t.profitHeatmapInsufficient(1)), findsOneWidget);
    expect(find.byKey(const Key('heatmap.unpaid')), findsNothing);
  });

  testWidgets('grid: 7 × 12 cells, levels, glyphs and the best list', (
    tester,
  ) async {
    profit.profit.heatmapResult = okMap(excludedIncome: 2);
    await pumpCard(tester);

    expect(find.text(t.badgeEstimate), findsOneWidget);
    for (final day in [0, 6]) {
      for (final slot in [0, 11]) {
        expect(find.byKey(Key('heatmap.cell.$day.$slot')), findsOneWidget);
      }
    }
    expect(find.byKey(const Key('heatmap.cell.7.0')), findsNothing);
    expect(find.byKey(const Key('heatmap.cell.0.12')), findsNothing);
    expect(find.text('จ.'), findsOneWidget);
    expect(find.text('อา.'), findsOneWidget);
    expect(find.text('22:00'), findsOneWidget);

    // Highest = top step, lowest positive = first step, loss and thin keep a glyph.
    expect(fillOf(tester, 0, 9), AppColors.heatLight[4]);
    expect(fillOf(tester, 5, 5), AppColors.heatLight[0]);
    expect(fillOf(tester, 1, 3), AppColors.errorSurface);
    expect(fillOf(tester, 6, 11), AppColors.mist);
    expect(fillOf(tester, 2, 0), Colors.transparent);
    expect(inCell(0, 9, '1'), findsOneWidget);
    expect(inCell(4, 9, '2'), findsOneWidget);
    expect(inCell(5, 5, '3'), findsOneWidget);
    expect(inCell(1, 3, '−'), findsOneWidget);
    expect(inCell(6, 11, '·'), findsOneWidget);

    expect(
      find.text(t.profitHeatmapLegendRange('฿120.00', '฿220.00')),
      findsOneWidget,
    );
    expect(find.text(t.profitHeatmapLegendLoss), findsOneWidget);
    expect(find.text(t.profitHeatmapLegendThin), findsOneWidget);
    expect(find.text(t.profitHeatmapTapHint), findsOneWidget);

    final first = find.byKey(const Key('heatmap.best.0'));
    expect(
      find.descendant(of: first, matching: find.text('วันจันทร์ 18:00–20:00')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text(t.profitHeatmapPerHour('฿220.00')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('heatmap.best.1')),
        matching: find.text('วันศุกร์ 18:00–20:00'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('heatmap.best.3')), findsNothing);
    expect(find.text(t.profitHeatmapAverage('฿141.25')), findsOneWidget);
    expect(find.text(t.profitHeatmapNote(24, 90)), findsOneWidget);
    expect(find.text(t.profitHeatmapExcluded(2, 0, 0)), findsOneWidget);
  });

  testWidgets('tapping a cell shows its figures; thin and empty explain', (
    tester,
  ) async {
    profit.profit.heatmapResult = okMap();
    await pumpCard(tester);
    final detail = find.byKey(const Key('heatmap.detail'));

    expect(find.byKey(const Key('heatmap.selected')), findsNothing);
    await tapKey(tester, 'heatmap.cell.0.9');
    // The selection ring keeps the cell's own fill inside it.
    final ring = find.descendant(
      of: find.byKey(const Key('heatmap.cell.0.9')),
      matching: find.byKey(const Key('heatmap.selected')),
    );
    expect(
      (tester.widget<Container>(ring).decoration! as BoxDecoration).color,
      AppColors.heatLight[4],
    );
    expect(find.byKey(const Key('heatmap.selected')), findsOneWidget);
    expect(
      find.descendant(of: detail, matching: find.text('วันจันทร์ 18:00–20:00')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detail, matching: find.text(t.profitHeatmapRank(1))),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detail,
        matching: find.text(t.profitHeatmapPerHour('฿220.00')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detail,
        matching: find.text(t.profitHeatmapCellDetail('฿240.00', '20', 10)),
      ),
      findsOneWidget,
    );
    expect(find.text(t.profitHeatmapTapHint), findsNothing);

    await tapKey(tester, 'heatmap.cell.6.11');
    expect(
      find.descendant(
        of: detail,
        matching: find.text(t.profitHeatmapCellThin(1, '0.5', 2, 1)),
      ),
      findsOneWidget,
    );

    await tapKey(tester, 'heatmap.cell.3.0');
    expect(
      find.descendant(
        of: detail,
        matching: find.text('วันพฤหัสบดี 00:00–02:00'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detail,
        matching: find.text(t.profitHeatmapCellEmpty),
      ),
      findsOneWidget,
    );

    // A row of the best list selects its cell too.
    await tapKey(tester, 'heatmap.best.1');
    expect(
      find.descendant(
        of: detail,
        matching: find.text(t.profitHeatmapPerHour('฿180.50')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every cell has a spoken label and the selection is announced', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    profit.profit.heatmapResult = okMap();
    await pumpCard(tester);
    final label =
        '${t.profitNetPerHour} ฿220.00 · '
        '${t.profitHeatmapCellDetail('฿240.00', '20', 10)}';
    expect(
      tester.getSemantics(find.byKey(const Key('heatmap.cell.0.9'))),
      isSemantics(
        label: t.profitHeatmapCellSemantics(
          'วันจันทร์',
          '18:00–20:00',
          '${t.profitHeatmapRank(1)} · $label',
        ),
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('heatmap.cell.2.0'))).label,
      t.profitHeatmapCellSemantics(
        'วันพุธ',
        '00:00–02:00',
        t.profitHeatmapCellEmpty,
      ),
    );
    await tapKey(tester, 'heatmap.cell.0.9');
    expect(
      tester.getSemantics(find.byKey(const Key('heatmap.cell.0.9'))),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('no positive cell: no best list, no colour range', (
    tester,
  ) async {
    profit.profit.heatmapResult = profitHeatmap(
      status: HeatmapStatus.ok,
      sessions: 12,
      netPerHour: '-4.00',
      cells: [
        heatCell(0, 9, netPerHour: '-4.00'),
        heatCell(1, 9, netPerHour: null, count: 1),
      ],
    );
    await pumpCard(tester);
    expect(find.text(t.profitHeatmapBestNone(2)), findsOneWidget);
    expect(find.byKey(const Key('heatmap.best.0')), findsNothing);
    expect(find.byKey(const Key('heatmap.legendRange')), findsNothing);
    expect(find.byKey(const Key('heatmap.excluded')), findsNothing);
    expect(find.text(t.profitHeatmapAverage('฿-4.00')), findsOneWidget);
  });

  testWidgets('dark theme: the top step is Electric Lime', (tester) async {
    profit.profit.heatmapResult = okMap();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        retry: (retryCount, error) => null,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('th'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SingleChildScrollView(child: ProfitHeatmapCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fillOf(tester, 0, 9), AppColors.lime);
    expect(fillOf(tester, 5, 5), AppColors.heatDark[0]);
    expect(fillOf(tester, 1, 3), AppColors.darkErrorSurface);
    expect(fillOf(tester, 6, 11), AppColors.darkSurfaceHighest);
  });

  testWidgets('an error stays inside the card', (tester) async {
    profit.profit.heatmapError = const ApiFailure(
      statusCode: 500,
      code: 'internal_error',
    );
    await pumpCard(tester);
    expect(find.byKey(const Key('heatmap.error')), findsOneWidget);
    expect(find.text(t.failureServer), findsOneWidget);
  });

  testWidgets('reloads after a record change', (tester) async {
    await pumpCard(tester);
    expect(profit.profit.calls.where((c) => c == 'heatmap'), hasLength(1));
    profit.profit.heatmapResult = okMap();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ProfitHeatmapCard)),
    );
    container.read(profitDataRevisionProvider.notifier).bump();
    await tester.pumpAndSettle();
    expect(profit.profit.calls.where((c) => c == 'heatmap'), hasLength(2));
    expect(find.byKey(const Key('heatmap.grid')), findsOneWidget);
  });

  testWidgets('the TrueProfit screen shows the card below the trend', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      path: Routes.profit,
      screen: const TrueProfitScreen(),
      overrides: overrides(),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('heatmap.insufficient')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(t.profitHeatmapInsufficient(10)), findsOneWidget);
  });

  test('labels', () {
    expect(hourLabel(6), '06:00');
    expect(slotRange(11, 2), '22:00–24:00');
    expect(weekdayShort(t, 3), 'พฤ.');
    expect(weekdayLabelFull(t, 6), 'วันอาทิตย์');
  });
}
