import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pending_record.dart';
import '../domain/profit_records.dart';
import 'pending_sync_controller.dart';
import 'profit_labels.dart';

/// `/pending-records`: what the offline queue holds, oldest first.
class PendingRecordsScreen extends ConsumerWidget {
  const PendingRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queue = ref.watch(pendingSyncProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingTitle)),
      body: queue.isEmpty
          ? StatusView(
              key: const Key('pending.empty'),
              icon: Icons.cloud_done_outlined,
              title: l10n.pendingEmptyTitle,
              message: l10n.pendingEmptyMessage,
            )
          : PageColumn(
              child: ListView(
                padding: AppSpacing.screen,
                children: [
                  AppBanner(message: l10n.pendingIntro),
                  if (queue.failedCount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppBanner(
                      tone: BannerTone.warning,
                      message: l10n.pendingFailedHint,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    key: const Key('pending.sendNow'),
                    onPressed: queue.syncing || queue.waitingCount == 0
                        ? null
                        : () =>
                              ref.read(pendingSyncProvider.notifier).retryNow(),
                    icon: queue.syncing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      queue.syncing ? l10n.pendingSending : l10n.pendingSendNow,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final item in queue.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _PendingTile(item: item, busy: queue.syncing),
                    ),
                ],
              ),
            ),
    );
  }
}

class _PendingTile extends ConsumerWidget {
  const _PendingTile({required this.item, required this.busy});

  final PendingRecord item;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, title, detail) = _describe(l10n, item);
    final status = item.isFailed
        ? l10n.pendingStatusFailed(_reason(l10n, item))
        : l10n.pendingStatusWaiting;
    return ListTile(
      key: Key('pending.${item.id}'),
      tileColor: theme.colorScheme.surface,
      leading: RoundIcon(icon),
      title: Text(title),
      subtitle: Text(
        '$detail\n$status',
        style: item.isFailed ? TextStyle(color: theme.colorScheme.error) : null,
      ),
      isThreeLine: true,
      trailing: IconButton(
        key: Key('pending.delete.${item.id}'),
        tooltip: l10n.recordDelete,
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: busy ? null : () => _delete(context, ref),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final queue = ref.read(pendingSyncProvider.notifier);
    final linked = item.kind == PendingKind.workSession
        ? queue.linkedCount(item.id)
        : 0;
    final confirmed = await confirmDelete(
      context,
      title: l10n.pendingDeleteTitle,
      message: linked > 0
          ? l10n.pendingDeleteLinkedMessage(linked)
          : l10n.pendingDeleteMessage,
    );
    if (confirmed) await queue.remove(item.id);
  }
}

/// Icon, title and one detail line, from the record the queue will create.
(IconData, String, String) _describe(
  AppLocalizations l10n,
  PendingRecord item,
) {
  final locale = l10n.localeName;
  final json = item.asStoredJson;
  switch (item.kind) {
    case PendingKind.income:
      final income = Income.fromJson(json);
      return (
        Icons.payments_outlined,
        '${l10n.incomeTitle} ${Formats.money(income.amount)}',
        [
          Formats.date(income.occurredOn, locale),
          ?income.sourceLabel,
        ].join(' · '),
      );
    case PendingKind.expense:
      final expense = Expense.fromJson(json);
      return (
        Icons.receipt_outlined,
        '${l10n.expenseTitle} ${Formats.money(expense.amount)}',
        [
          expenseCategoryLabel(l10n, expense.category),
          Formats.date(expense.occurredOn, locale),
        ].join(' · '),
      );
    case PendingKind.workSession:
      final session = WorkSession.fromJson(json);
      return (
        Icons.timer_outlined,
        '${l10n.sessionTitle} ${sessionTimeRange(l10n, session)}',
        [
          Formats.date(session.startedAt, locale),
          durationLabel(l10n, session.duration),
        ].join(' · '),
      );
  }
}

String _reason(AppLocalizations l10n, PendingRecord item) =>
    item.failureCode == linkedSessionFailedCode
    ? l10n.failureLinkedSessionFailed
    : failureMessage(
        l10n,
        ApiFailure(
          statusCode: item.failureStatus ?? 0,
          code: item.failureCode ?? '',
        ),
      );
