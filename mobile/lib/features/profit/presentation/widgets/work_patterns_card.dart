import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/status_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/work_patterns.dart';
import '../profit_providers.dart';
import 'profit_metrics_view.dart';

/// "รูปแบบการทำงาน": K-Means groups of the rider's sessions (last 180 days).
/// Below the minimum it shows how many sessions are still missing; when the
/// server finds no clear grouping it says so instead of showing weak groups.
class WorkPatternsCard extends ConsumerWidget {
  const WorkPatternsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final value = ref.watch(workPatternsProvider);
    return SectionCard(
      key: const Key('profit.patterns'),
      title: l10n.patternsTitle,
      child: switch (value) {
        AsyncData(:final value) => _Body(patterns: value),
        AsyncError(:final error) => AppBanner.failure(
          context,
          error is AppFailure ? error : UnknownFailure(error),
          key: const Key('patterns.error'),
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: SkeletonBox(height: 72),
        ),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.patterns});

  final WorkPatterns patterns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return switch (patterns.status) {
      PatternStatus.insufficientData => Column(
        key: const Key('patterns.insufficient'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.patternsInsufficient(patterns.sessionsMissing)),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              key: const Key('patterns.progress'),
              value: patterns.sessionCount / patterns.minSessions,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.patternsProgress(
              patterns.sessionCount,
              patterns.minSessions,
              patterns.windowDays,
            ),
            style: muted,
          ),
        ],
      ),
      PatternStatus.noClearPattern => Text(
        l10n.patternsNoClear(patterns.sessionCount, patterns.windowDays),
        key: const Key('patterns.noClear'),
        style: muted,
      ),
      PatternStatus.ok => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, group) in patterns.groups.indexed) ...[
            if (i > 0) const Divider(height: AppSpacing.xl),
            _GroupTile(
              key: Key('patterns.group.$i'),
              group: group,
              currency: patterns.currency,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(l10n.patternsNote(patterns.windowDays), style: muted),
        ],
      ),
    };
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.currency, super.key});

  final PatternGroup group;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final perHour = group.netProfitPerHour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(patternGroupName(l10n, group), style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.patternsGroupDetail(
            startTimeLabel(group.meanStartMinute),
            group.sessionCount,
            (group.share * 100).round(),
          ),
          style: muted,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.profitNetPerHour,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              perHour == null
                  ? l10n.profitNotAvailable
                  : Formats.currency(perHour, currency),
              style: theme.textTheme.titleMedium?.copyWith(
                color: perHour == null ? null : moneyColor(context, perHour),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (perHour == null)
          Text(l10n.patternsNoLinkedIncome, style: muted)
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
              Text(
                l10n.patternsPerHourBasis(group.profitSessionCount),
                style: muted,
              ),
            ],
          ),
      ],
    );
  }
}

/// `เย็น · สั้น ~3 ชม. · วันธรรมดา`
String patternGroupName(AppLocalizations l10n, PatternGroup group) =>
    l10n.patternsGroupName(
      switch (group.timeOfDay) {
        ShiftTimeOfDay.morning => l10n.patternsTimeMorning,
        ShiftTimeOfDay.midday => l10n.patternsTimeMidday,
        ShiftTimeOfDay.evening => l10n.patternsTimeEvening,
        ShiftTimeOfDay.night => l10n.patternsTimeNight,
      },
      switch (group.length) {
        ShiftLength.short => l10n.patternsLengthShort,
        ShiftLength.medium => l10n.patternsLengthMedium,
        ShiftLength.long => l10n.patternsLengthLong,
      },
      Formats.compact(group.meanHours),
      switch (group.dayType) {
        ShiftDayType.weekday => l10n.patternsDayWeekday,
        ShiftDayType.weekend => l10n.patternsDayWeekend,
        ShiftDayType.mixed => l10n.patternsDayMixed,
      },
    );

/// `18:30` from minutes after local midnight.
String startTimeLabel(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';
