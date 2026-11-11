import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/road_models.dart';
import 'road_labels.dart';
import 'road_providers.dart';

/// `/road/my-reports`: the rider's own reports, newest first. A row opens the
/// incident it joined.
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roadMyReports)),
      body: PagedListView<OwnReport>(
        provider: myReportsProvider,
        keyPrefix: 'myReports',
        bottomPadding: AppSpacing.xl,
        loading: const Padding(
          padding: AppSpacing.screen,
          child: ListSkeleton(),
        ),
        empty: StatusView(
          key: const Key('myReports.empty'),
          icon: Icons.add_location_alt_outlined,
          title: l10n.roadMyReportsEmptyTitle,
          message: l10n.roadMyReportsEmptyMessage,
        ),
        itemBuilder: (report) => _ReportRow(report: report),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final OwnReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final description = report.description;
    return ListTile(
      key: Key('myReport.${report.id}'),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CategoryIcon(category: report.category),
      title: Text(categoryLabel(l10n, report.category)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateTimeLabel(l10n, report.createdAt)),
            if (description != null)
              Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IncidentStatusBadge(status: report.incidentStatus),
                if (report.hasImage)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        l10n.roadHasPhoto,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push(Routes.incident(report.incidentId)),
    );
  }
}
