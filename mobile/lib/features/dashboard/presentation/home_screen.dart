import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/presentation/session_controller.dart';
import '../../profit/data/profit_repositories_impl.dart';
import '../../profit/domain/profit_summary.dart';
import '../../profit/presentation/profit_labels.dart';
import '../../profit/presentation/profit_providers.dart';
import '../../profit/presentation/widgets/profit_metrics_view.dart';
import 'widgets/rider_banner.dart';

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

/// Signed-in landing tab, the rider's command centre: greeting, today's actual
/// profit (hero), this week, quick record shortcuts and the AI tools.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    final user = session is SignedIn ? session.user : null;
    final summary = ref.watch(homeSummaryProvider);

    return Scaffold(
      // Logout lives on the profile tab.
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogoMark(size: 30),
            const SizedBox(width: AppSpacing.sm + AppSpacing.xxs),
            Text(l10n.appTitle),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _ProfileAvatar(name: user.displayName),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeSummaryProvider.future),
        child: PageColumn(
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              if (user != null) ...[
                RevealIn(child: RiderGreetingBanner(name: user.displayName)),
                const SizedBox(height: AppSpacing.xl),
              ],
              AsyncValueView(
                value: summary,
                onRetry: () => ref.invalidate(homeSummaryProvider),
                loading: const SummarySkeleton(),
                isEmpty: (s) => s.isEmpty,
                // The quick actions below stay visible in the empty state.
                empty: const RevealIn(child: _EmptyCard()),
                data: (s) => _Summaries(summary: s),
              ),
              const SizedBox(height: AppSpacing.xl),
              const RevealIn(index: 2, child: _QuickActions()),
              const SizedBox(height: AppSpacing.xl),
              const RevealIn(index: 3, child: _AiTools()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rider's initial in a lime circle; opens the profile tab.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return IconButton(
      key: const Key('home.avatar'),
      tooltip: l10n.navProfile,
      onPressed: () => context.go(Routes.profile),
      icon: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.semanticColors.accent,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: theme.textTheme.titleSmall?.copyWith(
            color: context.semanticColors.onAccent,
            fontWeight: FontWeight.w700,
          ),
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
    return ToneCard(
      key: const Key('home.empty'),
      tone: AppTone.obsidian,
      radius: AppRadius.xl,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconWell(icon: Icons.bolt_rounded, square: true),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeEmptyTitle,
                      style: theme.textTheme.titleSmall,
                    ),
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
          );
        },
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
        RevealIn(
          child: ProfitHeroCard(
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
        ),
        const SizedBox(height: AppSpacing.cardGap),
        RevealIn(
          index: 1,
          child: SectionCard(
            key: const Key('home.week'),
            tone: AppTone.sage,
            title: l10n.homeThisWeek(
              periodRangeLabel(l10n, week.period, week.startDate, week.endDate),
            ),
            child: ProfitMetricsView(
              metrics: week.metrics,
              currency: week.currency,
            ),
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
                  tone: AppTone.lime,
                  icon: Icons.add_card_rounded,
                  label: l10n.incomeAdd,
                  route: Routes.incomeNew,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickAction(
                  key: const Key('home.addExpense'),
                  tone: AppTone.teal,
                  icon: Icons.receipt_long_rounded,
                  label: l10n.expenseAdd,
                  route: Routes.expenseNew,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickAction(
                  key: const Key('home.addSession'),
                  tone: AppTone.mist,
                  icon: Icons.timer_rounded,
                  label: l10n.sessionAdd,
                  route: Routes.workSessionNew,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('home.openProfit'),
            onPressed: () => context.go(Routes.profit),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(l10n.homeOpenProfit),
          ),
        ),
      ],
    );
  }
}

/// Shortcut tile on a coloured surface: icon above a short label.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.tone,
    required this.icon,
    required this.label,
    required this.route,
    super.key,
  });

  final AppTone tone;
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ToneCard(
      tone: tone,
      radius: AppRadius.lg - AppSpacing.xs,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md + AppSpacing.xxs,
      ),
      onTap: () => context.push(route),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 84),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconWell(
                  icon: icon,
                  size: 40,
                  color: theme.colorScheme.onSurface,
                  iconColor: theme.colorScheme.surface,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Entry cards to the AI modules. Descriptions only: every figure the rider
/// sees comes from the module itself.
class _AiTools extends StatelessWidget {
  const _AiTools();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.homeAiTools),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AiToolCard(
                  key: const Key('home.pickup'),
                  tone: AppTone.obsidian,
                  icon: Icons.storefront_rounded,
                  title: l10n.homePickupCardTitle,
                  message: l10n.homePickupCardMessage,
                  onTap: () => context.go(Routes.pickup),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _AiToolCard(
                  key: const Key('home.shifts'),
                  tone: AppTone.teal,
                  icon: Icons.auto_graph_rounded,
                  title: l10n.homeShiftCardTitle,
                  message: l10n.homeShiftCardMessage,
                  onTap: () => context.go(Routes.shifts),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _RoadCard(),
      ],
    );
  }
}

class _AiToolCard extends StatelessWidget {
  const _AiToolCard({
    required this.tone,
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
    super.key,
  });

  final AppTone tone;
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ToneCard(
      tone: tone,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconWell(icon: icon, size: 40, square: true),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Entry to RoadContext (no tab of its own). Asks for nothing until opened.
class _RoadCard extends StatelessWidget {
  const _RoadCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToneCard(
      key: const Key('home.road'),
      tone: AppTone.sage,
      onTap: () => context.push(Routes.road),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Row(
            children: [
              const IconWell(icon: Icons.alt_route_rounded, square: true),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeRoadTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.homeRoadMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded),
            ],
          );
        },
      ),
    );
  }
}
