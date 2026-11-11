import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/presentation/widgets/profit_metrics_view.dart';
import '../domain/shift_models.dart';
import 'shift_labels.dart';
import 'shift_providers.dart';

/// `/shifts` (S-SHIFTS): the rider's scenarios with their estimates. Ticking 2-5
/// of them shows the compare button.
class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(shiftSelectionProvider);
    void add() => context.push(Routes.shiftNew);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shiftsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('shifts.add'),
        onPressed: add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.shiftsAdd),
      ),
      bottomNavigationBar: selected.isEmpty
          ? null
          : _CompareBar(selected: selected),
      body: PagedListView<ShiftScenario>(
        provider: shiftListProvider,
        keyPrefix: 'shifts',
        loading: const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ListSkeleton(rows: 4),
        ),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBanner(message: l10n.shiftsIntro),
              const SizedBox(height: AppSpacing.md),
              Text(
                selected.length >= ShiftLimits.maxCompare
                    ? l10n.shiftsMaxSelected
                    : l10n.shiftsSelectHint,
                key: const Key('shifts.selectHint'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        empty: StatusView(
          icon: Icons.event_note_outlined,
          title: l10n.shiftsEmptyTitle,
          message: l10n.shiftsEmptyMessage,
          actionLabel: l10n.shiftsAdd,
          onAction: add,
        ),
        itemBuilder: (scenario) => ScenarioTile(
          scenario: scenario,
          selected: selected.contains(scenario.id),
          canSelect: selected.length < ShiftLimits.maxCompare,
        ),
      ),
    );
  }
}

/// One scenario: tick box for the comparison, name, time, day, method and the
/// estimated net profit (per hour too). Tapping opens the details.
class ScenarioTile extends ConsumerWidget {
  const ScenarioTile({
    required this.scenario,
    required this.selected,
    required this.canSelect,
    super.key,
  });

  final ShiftScenario scenario;
  final bool selected;
  final bool canSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currency = ref.watch(shiftCurrencyProvider);
    final s = scenario;
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        key: Key('shift.${s.id}'),
        onTap: () => context.push(Routes.shiftDetail(s.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: Key('shift.${s.id}.select'),
                value: selected,
                semanticLabel: l10n.shiftsSelect(s.name),
                onChanged: selected || canSelect
                    ? (_) =>
                          ref.read(shiftSelectionProvider.notifier).toggle(s.id)
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppBadge(
                          label: l10n.badgeEstimate,
                          tone: BadgeTone.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${shiftTimeRange(s)} · '
                      '${plannedDayLabel(l10n, s.plannedWeekday)} · '
                      '${methodLabel(l10n, s.estimationMethod)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          shiftMoney(s.estimatedNetProfit, currency),
                          key: Key('shift.${s.id}.net'),
                          style: AppTypography.figures(
                            theme.textTheme.titleMedium?.copyWith(
                              color: moneyColor(context, s.estimatedNetProfit),
                            ),
                          ),
                        ),
                        Text(
                          l10n.shiftPerHourValue(
                            shiftMoney(s.estimatedNetProfitPerHour, currency),
                          ),
                          style: AppTypography.figures(
                            theme.textTheme.bodyMedium?.copyWith(
                              color: moneyColor(
                                context,
                                s.estimatedNetProfitPerHour,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareBar extends ConsumerWidget {
  const _CompareBar({required this.selected});

  final List<String> selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canCompare = selected.length >= ShiftLimits.minCompare;
    return Material(
      color: theme.colorScheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.semanticColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.shiftsSelectedCount(selected.length),
                    key: const Key('shifts.selectedCount'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  key: const Key('shifts.clearSelection'),
                  onPressed: () =>
                      ref.read(shiftSelectionProvider.notifier).clear(),
                  child: Text(l10n.shiftsClearSelection),
                ),
                if (canCompare) ...[
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    key: const Key('shifts.compare'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.minTouch),
                    ),
                    onPressed: () =>
                        context.push(Routes.shiftCompareFor(selected)),
                    icon: const Icon(Icons.compare_arrows_rounded),
                    label: Text(l10n.shiftsCompareCount(selected.length)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
