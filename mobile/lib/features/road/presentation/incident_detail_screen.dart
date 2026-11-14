import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/road_models.dart';
import 'road_labels.dart';
import 'road_providers.dart';
import 'widgets/road_map.dart';

/// `/road/incidents/:id`: what was reported where, how many riders, and the
/// rider's "still there" / "gone" answer and own report.
class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(incidentDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roadDetailTitle)),
      body: AsyncValueView(
        // Keep the detail (and its scroll position) while an answer reloads it.
        value: detail.keepingData,
        onRetry: () => ref.invalidate(incidentDetailProvider(id)),
        loading: const Padding(
          padding: AppSpacing.screen,
          child: SummarySkeleton(),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(incidentDetailProvider(id).future),
          child: _DetailBody(detail: d),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.detail});

  final IncidentDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final incident = detail.incident;
    final myReport = detail.myReport;
    return ListView(
      padding: AppSpacing.screen,
      children: [
        Row(
          children: [
            CategoryIcon(category: incident.category, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel(l10n, incident.category),
                    key: const Key('detail.category'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.roadReportedByUsers(
                      agoLabel(l10n, incident.lastReportedAt, now),
                    ),
                    key: const Key('detail.updated'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: IncidentStatusBadge(
            key: const Key('detail.status'),
            status: incident.status,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaticPinMap(key: const Key('detail.map'), point: incident.location),
        const SizedBox(height: AppSpacing.lg),
        MetricTileRow(
          tiles: [
            MetricTile(
              key: const Key('detail.reporters'),
              label: l10n.roadDetailReporters,
              value: l10n.roadPeople(incident.distinctReporters),
              icon: Icons.group_outlined,
            ),
            MetricTile(
              key: const Key('detail.reports'),
              label: l10n.roadDetailReports,
              value: l10n.roadTimes(incident.reportCount),
              icon: Icons.campaign_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        MetricTileRow(
          tiles: [
            MetricTile(
              key: const Key('detail.cleared'),
              label: l10n.roadDetailCleared,
              value: l10n.roadPeople(incident.clearedCount),
              icon: Icons.check_circle_outline_rounded,
            ),
            MetricTile(
              key: const Key('detail.first'),
              label: l10n.roadDetailFirstReported,
              value: dateTimeLabel(l10n, incident.firstReportedAt),
              icon: Icons.schedule_outlined,
            ),
          ],
        ),
        if (incident.status.isOpen) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            '${l10n.roadDetailExpires} ${dateTimeLabel(l10n, incident.expiresAt)}',
            key: const Key('detail.expires'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _Confirmation(detail: detail, now: now),
        if (myReport != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _MyReport(report: myReport),
        ],
        const SizedBox(height: AppSpacing.xl),
        const RoadNotice(),
      ],
    );
  }
}

class _Confirmation extends ConsumerWidget {
  const _Confirmation({required this.detail, required this.now});

  final IncidentDetail detail;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final incident = detail.incident;
    if (!incident.status.isOpen) {
      return AppBanner(
        key: const Key('detail.closed'),
        message: l10n.roadClosedMessage(statusLabel(l10n, incident.status)),
      );
    }
    final provider = confirmationProvider(incident.id);
    final submit = ref.watch(provider);
    final busy = submit.isLoading;
    final mine = detail.myConfirmation;
    // The server counts "gone" only when it is newer than the latest report
    // (or "still there"); an older one no longer counts and must be sent again.
    final staleCleared =
        mine != null &&
        !mine.stillPresent &&
        !mine.createdAt.isAfter(incident.lastReportedAt);

    Future<void> answer(bool stillPresent) async {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await ref
          .read(provider.notifier)
          .answer(stillPresent: stillPresent);
      if (ok) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.roadConfirmSaved)));
      }
    }

    final failure = switch (submit) {
      AsyncError(:final AppFailure error) => error,
      _ => null,
    };
    return SectionCard(
      key: const Key('detail.confirm'),
      title: l10n.roadConfirmQuestion,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mine != null) ...[
            if (staleCleared)
              AppBanner(
                key: const Key('detail.mineStale'),
                message: l10n.roadConfirmMineClearedStale(
                  agoLabel(l10n, mine.createdAt, now),
                ),
                tone: BannerTone.warning,
              )
            else
              Text(
                mine.stillPresent
                    ? l10n.roadConfirmMineStill(
                        agoLabel(l10n, mine.createdAt, now),
                      )
                    : l10n.roadConfirmMineCleared(
                        agoLabel(l10n, mine.createdAt, now),
                      ),
                key: const Key('detail.mine'),
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: _AnswerButton(
                  key: const Key('detail.still'),
                  label: l10n.roadConfirmStill,
                  icon: Icons.report_outlined,
                  selected: mine?.stillPresent == true,
                  onPressed: busy ? null : () => answer(true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _AnswerButton(
                  key: const Key('detail.gone'),
                  label: l10n.roadConfirmCleared,
                  icon: Icons.check_circle_outline_rounded,
                  selected: mine?.stillPresent == false && !staleCleared,
                  onPressed: busy ? null : () => answer(false),
                ),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppBanner.failure(context, failure, key: const Key('detail.error')),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.roadConfirmHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled when it is the rider's current answer.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(selected ? Icons.check_rounded : icon, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label)),
      ],
    );
    return Semantics(
      selected: selected,
      child: selected
          ? FilledButton(onPressed: onPressed, child: child)
          : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}

class _MyReport extends ConsumerWidget {
  const _MyReport({required this.report});

  final OwnReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = report.description;
    final ai = aiSuggestionText(l10n, report);
    return SectionCard(
      key: const Key('detail.myReport'),
      title: l10n.roadMyReport,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${categoryLabel(l10n, report.category)} · ${dateTimeLabel(l10n, report.createdAt)}',
            style: theme.textTheme.bodyMedium,
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(description, key: const Key('detail.description')),
          ],
          if (report.hasImage) ...[
            const SizedBox(height: AppSpacing.md),
            ReportImage(reportId: report.id),
          ],
          if (ai != null) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  ai,
                  key: const Key('detail.ai'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The photo of one of the rider's own reports (fetched with the session).
class ReportImage extends ConsumerWidget {
  const ReportImage({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final image = ref.watch(reportImageProvider(reportId));
    Widget box(Widget child) => ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 200,
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: child,
      ),
    );
    return switch (image) {
      AsyncData(:final value) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.memory(
          value,
          key: const Key('detail.photo'),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) =>
              box(Text(l10n.roadPhotoLoadFailed)),
        ),
      ),
      AsyncError() => box(
        TextButton.icon(
          key: const Key('detail.photoRetry'),
          onPressed: () => ref.invalidate(reportImageProvider(reportId)),
          icon: const Icon(Icons.refresh_rounded),
          label: Text('${l10n.roadPhotoLoadFailed} · ${l10n.commonRetry}'),
        ),
      ),
      _ => box(const CircularProgressIndicator()),
    };
  }
}
