import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/domain/profit_records.dart';
import '../../profit/presentation/profit_labels.dart';
import '../../profit/presentation/profit_providers.dart';
import '../../profit/presentation/widgets/profit_metrics_view.dart';
import '../domain/shift_models.dart';
import 'shift_labels.dart';
import 'shift_providers.dart';

/// `/shifts/scenarios/:id` (S-SHIFT-DETAIL): the estimate, where it came from,
/// warnings, the inputs and the optional link to a real work session. Actions:
/// re-estimate, edit, delete, link.
class ShiftDetailScreen extends ConsumerWidget {
  const ShiftDetailScreen({required this.id, super.key});

  final String id;

  /// Runs [action]; the outcome is a snackbar (the screen may have closed).
  static Future<bool> _act(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function(ShiftActionController c) action,
    String success,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action(ref.read(shiftDetailActionProvider.notifier));
    final error = ok || !context.mounted
        ? null
        : ref.read(shiftDetailActionProvider).error;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? success
                : failureMessage(
                    l10n,
                    error is AppFailure ? error : const UnknownFailure(),
                  ),
          ),
        ),
      );
    return ok;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDelete(
      context,
      title: l10n.shiftDeleteTitle,
      message: l10n.shiftDeleteMessage,
    );
    if (!confirmed || !context.mounted) return;
    final router = GoRouter.of(context);
    final ok = await _act(
      context,
      ref,
      (c) => c.delete(id),
      l10n.recordDeleted,
    );
    if (ok && router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scenario = ref.watch(shiftScenarioProvider(id));
    final busy = ref.watch(shiftDetailActionProvider).isLoading;
    final loaded = scenario.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(loaded?.name ?? l10n.shiftDetailTitle),
        actions: [
          if (loaded != null) ...[
            IconButton(
              key: const Key('shift.edit'),
              tooltip: l10n.shiftEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: busy
                  ? null
                  : () => context.push(Routes.shiftEdit(loaded.id)),
            ),
            IconButton(
              key: const Key('shift.delete'),
              tooltip: l10n.shiftDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: busy ? null : () => _delete(context, ref),
            ),
          ],
        ],
      ),
      body: AsyncValueView(
        value: scenario.keepingData,
        onRetry: () => ref.invalidate(shiftScenarioProvider(id)),
        loading: const SingleChildScrollView(
          padding: AppSpacing.screen,
          child: SummarySkeleton(cards: 2),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () => ref.refresh(shiftScenarioProvider(id).future),
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              _HeaderCard(scenario: s),
              const SizedBox(height: AppSpacing.lg),
              _EstimateCard(scenario: s),
              const SizedBox(height: AppSpacing.md),
              AppSecondaryButton(
                key: const Key('shift.reEstimate'),
                label: l10n.shiftReEstimate,
                isLoading: busy,
                onPressed: () => _act(
                  context,
                  ref,
                  (c) => c.reEstimate(id),
                  l10n.shiftReEstimated,
                ),
              ),
              for (final warning in s.estimateDetails.warnings) ...[
                const SizedBox(height: AppSpacing.md),
                AppBanner(
                  key: Key('shift.warning.$warning'),
                  message: warningLabel(l10n, warning),
                  tone: BannerTone.warning,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _BasisCard(scenario: s),
              if (s.estimationMethod == EstimationMethod.assumption) ...[
                const SizedBox(height: AppSpacing.lg),
                _InputsCard(assumptions: s.assumptions),
              ],
              const SizedBox(height: AppSpacing.lg),
              _LinkCard(
                scenario: s,
                busy: busy,
                onLink: (sessionId, message) =>
                    _act(context, ref, (c) => c.link(id, sessionId), message),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppBanner(message: l10n.shiftNotInTrueProfit),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.shiftEstimatedAt(
                  '${Formats.date(s.updatedAt.toLocal(), l10n.localeName)} '
                  '${Formats.time(s.updatedAt.toLocal(), l10n.localeName)}',
                ),
                key: const Key('shift.estimatedAt'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.scenario});

  final ShiftScenario scenario;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final s = scenario;
    return Card(
      key: const Key('shift.header'),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
                AppBadge(
                  label: methodLabel(l10n, s.estimationMethod),
                  tone: BadgeTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              shiftTimeRange(s),
              key: const Key('shift.time'),
              style: AppTypography.figures(theme.textTheme.titleMedium),
            ),
            Text(
              '${shiftLengthLabel(l10n, s)} · '
              '${plannedDayLabel(l10n, s.plannedWeekday)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends ConsumerWidget {
  const _EstimateCard({required this.scenario});

  final ShiftScenario scenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency = ref.watch(shiftCurrencyProvider);
    final s = scenario;
    String money(Decimal v) => shiftMoney(v, currency);
    return SectionCard(
      title: l10n.shiftNetEstimate,
      trailing: AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            money(s.estimatedNetProfit),
            key: const Key('shift.net'),
            style: AppTypography.figures(
              theme.textTheme.headlineSmall?.copyWith(
                color: moneyColor(context, s.estimatedNetProfit),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MetricTileRow(
            tiles: [
              MetricTile(
                key: const Key('shift.revenue'),
                label: l10n.shiftEstimatedRevenue,
                value: money(s.estimatedRevenue),
                icon: Icons.trending_up_rounded,
              ),
              MetricTile(
                key: const Key('shift.expenses'),
                label: l10n.shiftEstimatedExpenses,
                value: money(s.estimatedExpenses),
                icon: Icons.trending_down_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MetricTileRow(
            tiles: [
              MetricTile(
                key: const Key('shift.perHour'),
                label: l10n.shiftPerHourEstimate,
                value: l10n.shiftPerHourValue(
                  money(s.estimatedNetProfitPerHour),
                ),
                icon: Icons.schedule_rounded,
                valueColor: moneyColor(context, s.estimatedNetProfitPerHour),
              ),
              MetricTile(
                label: l10n.shiftShiftHours,
                value: durationLabel(
                  l10n,
                  Duration(minutes: s.durationMinutes),
                ),
                icon: Icons.timelapse_rounded,
              ),
            ],
          ),
          if (s.hasRange) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.shiftRangeTitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.shiftRangeValue(
                money(s.estimateLow!),
                money(s.estimateHigh!),
              ),
              key: const Key('shift.range'),
              style: AppTypography.figures(theme.textTheme.titleMedium),
            ),
            Text(l10n.shiftRangeHint, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Label-value line inside a card.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  if (note != null)
                    Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.figures(theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasisCard extends ConsumerWidget {
  const _BasisCard({required this.scenario});

  final ShiftScenario scenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(shiftCurrencyProvider);
    final d = scenario.estimateDetails;
    String money(Decimal? v) =>
        v == null ? l10n.shiftNotSet : shiftMoney(v, currency);
    String number(Decimal? v) =>
        v == null ? l10n.shiftNotSet : Formats.compact(v);
    String? source(String key) => switch (d.sources[key]) {
      'scenario' => l10n.shiftSourceScenario,
      'rider_profile' => l10n.shiftSourceProfile,
      _ => null,
    };

    final List<Widget> rows;
    if (scenario.estimationMethod == EstimationMethod.historical) {
      final days = d.nDays ?? 0;
      final weekday = scenario.plannedWeekday;
      rows = [
        Text(
          d.usesSameWeekday && weekday != null
              ? l10n.shiftBasisSameWeekday(weekdayLabel(l10n, weekday), days)
              : l10n.shiftBasisAllDays(days),
          key: const Key('shift.basis'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (d.windowStart != null && d.windowEnd != null)
          Text(
            l10n.shiftBasisWindow(
              Formats.date(d.windowStart!, l10n.localeName),
              Formats.date(d.windowEnd!, l10n.localeName),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: AppSpacing.sm),
        _InfoRow(
          label: l10n.shiftHistoricalHours,
          value: d.historicalHours == null
              ? l10n.shiftNotSet
              : l10n.shiftHoursValue(Formats.compact(d.historicalHours!)),
        ),
        _InfoRow(
          label: l10n.shiftRevenuePerHour,
          value: money(d.revenuePerHour),
        ),
        _InfoRow(
          label: l10n.shiftExpensesPerHour,
          value: money(d.expensesPerHour),
        ),
        _InfoRow(label: l10n.shiftOtherCosts, value: money(d.otherCosts)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.shiftHistoricalNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    } else {
      rows = [
        _InfoRow(
          label: l10n.shiftExpectedOrders,
          value: number(d.expectedOrders),
        ),
        _InfoRow(label: l10n.shiftExpectedKm, value: number(d.expectedKm)),
        _InfoRow(
          label: l10n.shiftFuelCost,
          value: money(d.fuelCost),
          note: [
            source('fuel_km_per_liter'),
            source('fuel_price_per_liter'),
          ].nonNulls.toSet().join(' · ').emptyToNull,
        ),
        _InfoRow(
          label: l10n.shiftDepreciationCost,
          value: money(d.depreciationCost),
          note: source('depreciation_per_km'),
        ),
        _InfoRow(label: l10n.shiftOtherCosts, value: money(d.otherCosts)),
      ];
    }
    return SectionCard(
      key: const Key('shift.basisCard'),
      title: l10n.shiftBasisTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

extension on String {
  String? get emptyToNull => isEmpty ? null : this;
}

class _InputsCard extends ConsumerWidget {
  const _InputsCard({required this.assumptions});

  final ShiftAssumptions assumptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currency = ref.watch(shiftCurrencyProvider);
    final a = assumptions;
    String value(Decimal? v, {bool isMoney = false}) => v == null
        ? l10n.shiftNotSet
        : isMoney
        ? shiftMoney(v, currency)
        : Formats.decimalInput(v);
    return SectionCard(
      key: const Key('shift.inputsCard'),
      title: l10n.shiftInputsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: l10n.shiftFieldOrdersPerHour,
            value: value(a.ordersPerHour),
          ),
          _InfoRow(
            label: l10n.shiftFieldIncomePerOrder,
            value: value(a.incomePerOrder, isMoney: true),
          ),
          _InfoRow(
            label: l10n.shiftFieldKmPerOrder,
            value: value(a.kmPerOrder),
          ),
          _InfoRow(
            label: l10n.onboardingFuelKmPerLiter,
            value: value(a.fuelKmPerLiter),
            note: a.fuelKmPerLiter == null ? l10n.shiftInputFromProfile : null,
          ),
          _InfoRow(
            label: l10n.onboardingFuelPricePerLiter,
            value: value(a.fuelPricePerLiter),
            note: a.fuelPricePerLiter == null
                ? l10n.shiftInputFromProfile
                : null,
          ),
          _InfoRow(
            label: l10n.onboardingDepreciationPerKm,
            value: value(a.depreciationPerKm),
            note: a.depreciationPerKm == null
                ? l10n.shiftInputFromProfile
                : null,
          ),
          _InfoRow(
            label: l10n.shiftFieldOtherCosts,
            value: value(a.otherCosts, isMoney: true),
          ),
        ],
      ),
    );
  }
}

/// The optional real work session of this scenario.
class _LinkCard extends ConsumerWidget {
  const _LinkCard({
    required this.scenario,
    required this.busy,
    required this.onLink,
  });

  final ShiftScenario scenario;
  final bool busy;

  /// `null` session = remove the link; the message is the success text.
  final void Function(String? sessionId, String message) onLink;

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final session = await context.push<WorkSession>(Routes.shiftSessionPicker);
    if (session != null) onLink(session.id, l10n.shiftLinked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sessionId = scenario.actualWorkSessionId;
    return SectionCard(
      key: const Key('shift.linkCard'),
      title: l10n.shiftLinkTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sessionId == null)
            Text(l10n.shiftLinkNone, style: theme.textTheme.bodyMedium)
          else
            _LinkedSession(id: sessionId),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.shiftLinkHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          if (sessionId == null)
            AppSecondaryButton(
              key: const Key('shift.link'),
              label: l10n.shiftLinkAction,
              onPressed: busy ? null : () => _pick(context),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  key: const Key('shift.linkChange'),
                  onPressed: busy ? null : () => _pick(context),
                  child: Text(l10n.shiftLinkChange),
                ),
                TextButton(
                  key: const Key('shift.unlink'),
                  onPressed: busy
                      ? null
                      : () => onLink(null, l10n.shiftUnlinked),
                  child: Text(l10n.shiftUnlink),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LinkedSession extends ConsumerWidget {
  const _LinkedSession({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(workSessionDetailProvider(id));
    return switch (session) {
      AsyncData(value: final s) => Text(
        workSessionLabel(l10n, s),
        key: const Key('shift.linkedSession'),
        style: theme.textTheme.bodyLarge,
      ),
      AsyncError(:final error) => Text(
        failureMessage(
          l10n,
          error is AppFailure ? error : const UnknownFailure(),
        ),
        style: theme.textTheme.bodyMedium,
      ),
      _ => const SkeletonBox(width: 200),
    };
  }
}
