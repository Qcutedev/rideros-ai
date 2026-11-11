import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_labels.dart';
import 'pickup_providers.dart';

/// `/pickup/predictions` (S-PREDICTION-HISTORY): the rider's predictions, newest
/// first.
class PredictionHistoryScreen extends StatelessWidget {
  const PredictionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pickupHistory)),
      body: PagedListView<Prediction>(
        provider: predictionHistoryProvider,
        keyPrefix: 'history',
        bottomPadding: AppSpacing.xl,
        loading: const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ListSkeleton(rows: 5),
        ),
        empty: StatusView(
          icon: Icons.history_rounded,
          title: l10n.historyEmptyTitle,
          message: l10n.historyEmptyMessage,
          actionLabel: l10n.historyFindRestaurant,
          onAction: () => context.go(Routes.pickup),
        ),
        itemBuilder: (p) => _PredictionTile(prediction: p),
      ),
    );
  }
}

class _PredictionTile extends StatelessWidget {
  const _PredictionTile({required this.prediction});

  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final at = prediction.requestedAt;
    return ListTile(
      key: Key('prediction.${prediction.id}'),
      tileColor: Theme.of(context).colorScheme.surface,
      leading: const RoundIcon(Icons.schedule_outlined),
      title: Text(
        '${prediction.restaurantName ?? l10n.historyDeletedRestaurant}'
        ' · ${minutesRange(l10n, prediction.interval)}',
      ),
      subtitle: Text(
        '${Formats.date(at, l10n.localeName)} ${Formats.time(at, l10n.localeName)}',
      ),
      trailing: AppBadge(label: l10n.badgeEstimate, tone: BadgeTone.warning),
    );
  }
}
