import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/road_models.dart';

String categoryLabel(AppLocalizations l10n, RoadCategory category) =>
    switch (category) {
      RoadCategory.flooding => l10n.roadCategoryFlooding,
      RoadCategory.roadDamage => l10n.roadCategoryRoadDamage,
      RoadCategory.roadClosure => l10n.roadCategoryRoadClosure,
      RoadCategory.roadObstacle => l10n.roadCategoryRoadObstacle,
      RoadCategory.trafficIncident => l10n.roadCategoryTrafficIncident,
    };

IconData categoryIcon(RoadCategory category) => switch (category) {
  RoadCategory.flooding => Icons.flood_outlined,
  RoadCategory.roadDamage => Icons.construction_rounded,
  RoadCategory.roadClosure => Icons.do_not_disturb_on_outlined,
  RoadCategory.roadObstacle => Icons.warning_amber_rounded,
  RoadCategory.trafficIncident => Icons.car_crash_outlined,
};

/// Never "verified": `corroborated` reads "several riders reported it".
String statusLabel(AppLocalizations l10n, IncidentStatus status) =>
    switch (status) {
      IncidentStatus.unverified => l10n.roadStatusUnverified,
      IncidentStatus.corroborated => l10n.roadStatusCorroborated,
      IncidentStatus.resolved => l10n.roadStatusResolved,
      IncidentStatus.expired => l10n.roadStatusExpired,
      IncidentStatus.rejected => l10n.roadStatusRejected,
    };

/// `เมื่อสักครู่`, `5 นาทีที่แล้ว`, `3 ชั่วโมงที่แล้ว`, `2 วันที่แล้ว`.
String agoLabel(AppLocalizations l10n, DateTime at, DateTime now) {
  final elapsed = now.difference(at);
  if (elapsed.inMinutes < 1) return l10n.roadAgoJustNow;
  if (elapsed.inHours < 1) return l10n.roadAgoMinutes(elapsed.inMinutes);
  if (elapsed.inDays < 1) return l10n.roadAgoHours(elapsed.inHours);
  return l10n.roadAgoDays(elapsed.inDays);
}

/// `350 ม.` below 1 km (rounded to 10 m), else `1.2 กม.`.
String distanceLabel(AppLocalizations l10n, double meters) {
  if (meters < 995) {
    return l10n.roadDistanceM(((meters / 10).round() * 10).clamp(0, 990));
  }
  final km = Decimal.parse((meters / 1000).toStringAsFixed(1)).round(scale: 1);
  return l10n.roadDistanceKm(Formats.compact(km));
}

/// `13 พ.ย. 2026 18:30` in the device's time zone.
String dateTimeLabel(AppLocalizations l10n, DateTime value) {
  final local = value.toLocal();
  return l10n.roadDateTime(
    Formats.date(local, l10n.localeName),
    Formats.time(local, l10n.localeName),
  );
}

/// Below this confidence the app says the AI is unsure instead of naming a
/// category (decision 10, §4.11).
const aiMinConfidence = 0.6;

/// The photo classifier's suggestion for a report, or `null` when there is
/// nothing to show (no photo, not classified, failed). Never a verdict.
String? aiSuggestionText(AppLocalizations l10n, OwnReport report) {
  switch (report.aiStatus) {
    case AiStatus.pending:
      return l10n.roadAiPending;
    case AiStatus.none || AiStatus.failed:
      return null;
    case AiStatus.done:
      final label = report.aiLabel;
      final confidence = report.aiConfidence?.toDouble();
      if (label == null || confidence == null) return null;
      if (confidence < aiMinConfidence) return l10n.roadAiUnsure;
      final name = switch (label) {
        'other' => l10n.roadAiOther,
        _ => switch (RoadCategory.values.where((c) => c.apiValue == label)) {
          final matches when matches.isNotEmpty => categoryLabel(
            l10n,
            matches.first,
          ),
          _ => label,
        },
      };
      return l10n.roadAiSuggestion(name, (confidence * 100).round());
  }
}

/// Status as text (never colour alone).
class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({required this.status, super.key});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) => AppBadge(
    label: statusLabel(AppLocalizations.of(context), status),
    tone: switch (status) {
      IncidentStatus.corroborated => BadgeTone.warning,
      IncidentStatus.unverified => BadgeTone.info,
      _ => BadgeTone.neutral,
    },
  );
}

/// Category icon on an amber rounded square (hazard colour).
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({required this.category, this.size = 40, super.key});

  final RoadCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.semanticColors.warningContainer,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        categoryIcon(category),
        size: size * 0.55,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// One incident in a list: category, status, last update, distance.
class IncidentRow extends StatelessWidget {
  const IncidentRow({required this.incident, required this.now, super.key});

  final Incident incident;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final distance = incident.distanceM;
    return ListTile(
      key: Key('incident.${incident.id}'),
      tileColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CategoryIcon(category: incident.category),
      title: Text(categoryLabel(l10n, incident.category)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.roadReportedByUsers(
                agoLabel(l10n, incident.lastReportedAt, now),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            IncidentStatusBadge(status: incident.status),
          ],
        ),
      ),
      trailing: distance == null
          ? const Icon(Icons.chevron_right_rounded)
          : Text(
              distanceLabel(l10n, distance),
              style: AppTypography.figures(theme.textTheme.labelLarge)
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
      onTap: () => context.push(Routes.incident(incident.id)),
    );
  }
}

/// The "reported by riders, not verified" note under every RoadContext list.
class RoadNotice extends StatelessWidget {
  const RoadNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppLocalizations.of(context).roadNotice,
            key: const Key('road.notice'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
