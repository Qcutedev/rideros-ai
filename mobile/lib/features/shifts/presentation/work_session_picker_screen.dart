import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../profit/domain/profit_records.dart';
import '../../profit/presentation/profit_providers.dart';
import 'shift_labels.dart';

/// `/shifts/select-session`: the rider's work sessions, newest first. Tapping one
/// pops it as the result.
class WorkSessionPickerScreen extends ConsumerWidget {
  const WorkSessionPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shiftPickSessionTitle)),
      body: PagedListView<WorkSession>(
        provider: workSessionListProvider,
        keyPrefix: 'pickSession',
        bottomPadding: AppSpacing.lg,
        loading: const SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: ListSkeleton(rows: 5),
        ),
        empty: StatusView(
          icon: Icons.timer_outlined,
          title: l10n.shiftPickSessionEmptyTitle,
          message: l10n.shiftPickSessionEmptyMessage,
          actionLabel: l10n.sessionAdd,
          onAction: () => context.push(Routes.workSessionNew),
        ),
        itemBuilder: (session) => ListTile(
          key: Key('pickSession.${session.id}'),
          tileColor: Theme.of(context).colorScheme.surface,
          leading: const RoundIcon(Icons.timer_outlined),
          title: Text(workSessionLabel(l10n, session)),
          subtitle: session.notes == null
              ? null
              : Text(
                  session.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: session.isDemo ? AppBadge.demo(context) : null,
          onTap: () => context.pop(session),
        ),
      ),
    );
  }
}
