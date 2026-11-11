import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_labels.dart';
import 'pickup_providers.dart';

/// `/pickup/logs` (S-PICKUP-LOGS): real pickups the rider logged, newest arrival
/// first; each can be deleted after confirming.
class PickupLogsScreen extends ConsumerWidget {
  const PickupLogsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PickupLog log,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await confirmDelete(
      context,
      title: l10n.logsDeleteTitle,
      message: l10n.logsDeleteMessage,
    );
    if (!confirmed) return;
    final controller = ref.read(pickupLogDeleteProvider.notifier);
    final ok = await controller.deleteLog(log.id);
    // The rider may have left the list meanwhile: `ref` is unusable then, but
    // the app-wide messenger still shows the outcome.
    final error = ok || !context.mounted
        ? null
        : ref.read(pickupLogDeleteProvider).error;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? l10n.recordDeleted
                : failureMessage(
                    l10n,
                    error is AppFailure ? error : const UnknownFailure(),
                  ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final deleting = ref.watch(pickupLogDeleteProvider).isLoading;
    void add() => context.push(Routes.pickupLogNew);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.logsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('logs.add'),
        onPressed: add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.logsAdd),
      ),
      body: PagedListView<PickupLog>(
        provider: pickupLogListProvider,
        keyPrefix: 'logs',
        loading: const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ListSkeleton(rows: 5),
        ),
        empty: StatusView(
          icon: Icons.timer_outlined,
          title: l10n.logsEmptyTitle,
          message: l10n.logsEmptyMessage,
          actionLabel: l10n.logsAdd,
          onAction: add,
        ),
        itemBuilder: (log) => ListTile(
          key: Key('log.${log.id}'),
          tileColor: Theme.of(context).colorScheme.surface,
          leading: const RoundIcon(Icons.timer_outlined),
          title: Text(
            '${log.restaurantName} · '
            '${l10n.logsWait(minutes1(log.waitMinutes))}',
          ),
          subtitle: Text(
            '${Formats.date(log.arrivedAt, l10n.localeName)} '
            '${Formats.time(log.arrivedAt, l10n.localeName)}'
            '–${Formats.time(log.pickedUpAt, l10n.localeName)}'
            '${log.notes == null ? '' : '\n${log.notes}'}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            key: Key('log.${log.id}.delete'),
            tooltip: l10n.logsDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: deleting ? null : () => _delete(context, ref, log),
          ),
        ),
      ),
    );
  }
}
