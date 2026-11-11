import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/theme/app_theme.dart';
import 'package:rideros_ai/app/theme/tokens.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/errors/failure_messages.dart';
import 'package:rideros_ai/core/widgets/app_badge.dart';
import 'package:rideros_ai/core/widgets/app_buttons.dart';
import 'package:rideros_ai/core/widgets/app_cards.dart';
import 'package:rideros_ai/core/widgets/app_text_field.dart';
import 'package:rideros_ai/core/widgets/auth_layout.dart';
import 'package:rideros_ai/core/widgets/form_layout.dart';
import 'package:rideros_ai/core/widgets/status_views.dart';
import 'package:rideros_ai/l10n/app_localizations.dart';

import '../helpers/pump.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('AsyncValueView renders the four states', () {
    Widget view(AsyncValue<List<int>> value, {VoidCallback? onRetry}) =>
        AsyncValueView<List<int>>(
          value: value,
          isEmpty: (items) => items.isEmpty,
          empty: const Text('empty'),
          onRetry: onRetry,
          data: (items) => Text('items:${items.length}'),
        );

    testWidgets('loading', (tester) async {
      await _pump(tester, view(const AsyncLoading()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await _pump(tester, view(const AsyncData([])));
      expect(find.text('empty'), findsOneWidget);
    });

    testWidgets('data', (tester) async {
      await _pump(tester, view(const AsyncData([1, 2])));
      expect(find.text('items:2'), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      var retried = 0;
      await _pump(
        tester,
        view(
          const AsyncError(NetworkFailure(), StackTrace.empty),
          onRetry: () => retried++,
        ),
      );
      expect(find.text(t.failureNetwork), findsOneWidget);
      await tester.tap(find.text(t.commonRetry));
      expect(retried, 1);
    });

    testWidgets('non-AppFailure errors show the generic message', (
      tester,
    ) async {
      await _pump(tester, view(AsyncError(StateError('x'), StackTrace.empty)));
      expect(find.text(t.failureUnknown), findsOneWidget);
    });
  });

  test('failure messages cover every case', () {
    expect(
      failureMessage(t, const NetworkFailure(isTimeout: true)),
      t.failureTimeout,
    );
    expect(
      failureMessage(t, const SessionExpiredFailure()),
      t.failureSessionExpired,
    );
    expect(
      failureMessage(t, const RateLimitedFailure()),
      t.failureRateLimitedNoTime,
    );
    expect(
      failureMessage(
        t,
        const RateLimitedFailure(retryAfter: Duration(milliseconds: 10)),
      ),
      t.failureRateLimited(1),
    );
    expect(
      failureMessage(t, const ApiFailure(statusCode: 503, code: 'x')),
      t.failureServer,
    );
    expect(
      failureMessage(t, const ApiFailure(statusCode: 418, code: 'x')),
      t.failureUnknown,
    );
    expect(
      failureMessage(
        t,
        const ApiFailure(statusCode: 422, code: ApiErrorCode.validationError),
      ),
      t.failureValidation,
    );
    expect(
      failureMessage(
        t,
        const ApiFailure(statusCode: 400, code: ApiErrorCode.invalidTimezone),
      ),
      t.failureInvalidTimezone,
    );
    expect(failureMessage(t, const UnknownFailure()), t.failureUnknown);
  });

  testWidgets('light and dark themes expose the semantic colours', (
    tester,
  ) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await _pump(
        tester,
        Column(
          children: [
            for (final tone in BannerTone.values)
              AppBanner(message: tone.name, tone: tone),
          ],
        ),
        theme: theme,
      );
      final context = tester.element(find.text('warning'));
      expect(context.semanticColors, isNotNull);
      expect(find.byType(AppBanner), findsNWidgets(BannerTone.values.length));
    }
    expect(
      AppSemanticColors.light.lerp(AppSemanticColors.dark, 1).warning,
      AppSemanticColors.dark.warning,
    );
  });

  group('Rider Green components', () {
    testWidgets('AsyncValueView uses the given loading widget', (tester) async {
      await _pump(
        tester,
        AsyncValueView<int>(
          value: const AsyncLoading(),
          loading: const SummarySkeleton(),
          data: (v) => Text('$v'),
        ),
      );
      expect(find.byKey(const Key('skeleton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel(t.commonLoading), findsOneWidget);
    });

    testWidgets('label above the field names the field for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        AppTextField(controller: controller, label: 'ชื่อร้าน'),
      );
      expect(find.text('ชื่อร้าน'), findsOneWidget);
      expect(tester.getSemantics(find.byType(EditableText)).label, 'ชื่อร้าน');
      handle.dispose();
    });

    testWidgets('badges, tiles and buttons render in light and dark', (
      tester,
    ) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        var deleted = 0;
        await _pump(
          tester,
          Builder(
            builder: (context) => Column(
              children: [
                AppBadge.demo(context),
                const AppBadge(label: 'ค่าประมาณ', tone: BadgeTone.warning),
                const AppBadge(label: 'Dataset'),
                const AppBadge(label: 'จำกัด', tone: BadgeTone.neutral),
                const MetricTileRow(
                  tiles: [
                    MetricTile(label: 'รายได้', value: '฿1,049.50'),
                    MetricTile(label: 'ค่าใช้จ่าย', value: '฿0.00'),
                  ],
                ),
                AppDestructiveButton(label: 'ลบ', onPressed: () => deleted++),
              ],
            ),
          ),
          theme: theme,
        );
        // Let the theme change animation finish.
        await tester.pumpAndSettle();
        expect(find.text(t.demoLabel), findsOneWidget);
        expect(find.text('฿1,049.50'), findsOneWidget);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(
          button.style?.backgroundColor?.resolve({}),
          theme.colorScheme.error,
        );
        await tester.tap(find.text('ลบ'));
        expect(deleted, 1);
      }
    });

    testWidgets('auth page header shows a back button only when it can pop', (
      tester,
    ) async {
      Widget page(String title) => AuthLayout(
        header: AuthHeader.page(title: title, subtitle: 'sub'),
        children: [Text('body:$title')],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('th'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: page('first'),
        ),
      );
      expect(find.text('body:first'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(builder: (_) => page('second')));
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.text('sub'), findsOneWidget);
      // Logo, title and description centred like the login header; the back
      // button stays at the left edge.
      final header = tester.getRect(find.byType(AuthHeader).last);
      for (final part in [
        find.byType(AppLogoMark).last,
        find.text('second'),
        find.text('sub'),
      ]) {
        expect(tester.getCenter(part).dx, closeTo(header.center.dx, 0.5));
      }
      expect(
        tester.getCenter(find.byType(BackButton)).dx,
        lessThan(header.center.dx - 150),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('body:first'), findsOneWidget);
      expect(find.text('body:second'), findsNothing);
    });

    test('themes use the Rider Green tokens and the bundled font', () {
      expect(AppTheme.light.colorScheme.primary, AppColors.brand);
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.background);
      expect(AppTheme.light.appBarTheme.backgroundColor, AppColors.brand);
      expect(AppTheme.dark.colorScheme.primary, AppColors.darkBrand);
      expect(AppTheme.dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(
        AppTheme.light.textTheme.bodyLarge?.fontFamily,
        AppTypography.fontFamily,
      );
      expect(AppTheme.light.textTheme.displaySmall?.fontSize, 32);
      expect(AppTheme.light.textTheme.bodyLarge?.fontSize, 16);
    });
  });
}
