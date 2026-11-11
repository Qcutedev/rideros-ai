import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profit/data/profit_repositories_impl.dart';
import '../../profit/domain/profit_summary.dart';
import '../../profit/presentation/profit_labels.dart';
import '../../profit/presentation/profit_providers.dart';
import '../../profit/presentation/widgets/profit_metrics_view.dart';

class HomeSummary {
  const HomeSummary({required this.today, required this.week});

  final ProfitSummary today;
  final ProfitSummary week;

  bool get isEmpty => today.metrics.isEmpty && week.metrics.isEmpty;
}

/// Today and this week (rider's time zone), reloaded after every record change.
final homeSummaryProvider = FutureProvider.autoDispose<HomeSummary>((
  ref,
) async {
  ref.watch(profitDataRevisionProvider);
  final repository = ref.watch(profitRepositoryProvider);
  final results = await Future.wait([
    repository.summary(ProfitPeriod.day),
    repository.summary(ProfitPeriod.week),
  ]);
  return HomeSummary(today: results[0], week: results[1]);
});

/// Signed-in landing tab: greeting, today's and this week's actual profit, and
/// shortcuts to record income, expenses and work sessions.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider);
    final user = session is SignedIn ? session.user : null;
    final summary = ref.watch(homeSummaryProvider);

    return Scaffold(
      // Logout lives on the profile tab.
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeSummaryProvider.future),
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            if (user != null) ...[
              Text(
                l10n.homeGreeting(user.displayName),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.homeSignedInAs(user.email),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            AsyncValueView(
              value: summary,
              onRetry: () => ref.invalidate(homeSummaryProvider),
              loading: const SummarySkeleton(),
              isEmpty: (s) => s.isEmpty,
              // The quick actions below stay visible in the empty state.
              empty: const _EmptyCard(),
              data: (s) => _Summaries(summary: s),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _QuickActions(),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      key: const Key('home.empty'),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.semanticColors.mint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeEmptyTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.homeEmptyMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summaries extends StatelessWidget {
  const _Summaries({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = summary.today;
    final week = summary.week;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfitHeroCard(
          key: const Key('home.today'),
          title: l10n.homeToday(
            periodRangeLabel(
              l10n,
              today.period,
              today.startDate,
              today.endDate,
            ),
          ),
          metrics: today.metrics,
          currency: today.currency,
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          key: const Key('home.week'),
          title: l10n.homeThisWeek(
            periodRangeLabel(l10n, week.period, week.startDate, week.endDate),
          ),
          child: ProfitMetricsView(
            metrics: week.metrics,
            currency: week.currency,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeQuickActions),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickAction(
                  key: const Key('home.addIncome'),
                  icon: Icons.payments_outlined,
                  label: l10n.incomeAdd,
                  route: Routes.incomeNew,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickAction(
                  key: const Key('home.addExpense'),
                  icon: Icons.receipt_outlined,
                  label: l10n.expenseAdd,
                  route: Routes.expenseNew,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickAction(
                  key: const Key('home.addSession'),
                  icon: Icons.timer_outlined,
                  label: l10n.sessionAdd,
                  route: Routes.workSessionNew,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('home.openProfit'),
            onPressed: () => context.go(Routes.profit),
            icon: const Icon(Icons.insights_outlined),
            label: Text(l10n.homeOpenProfit),
          ),
        ),
      ],
    );
  }
}

/// Shortcut tile: icon on mint above a short label.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    super.key,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: semantic.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: semantic.mint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
