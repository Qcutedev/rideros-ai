import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../core/widgets/status_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../pending_sync_controller.dart';

/// "รอส่ง N รายการ" on Home and TrueProfit while the offline queue holds records,
/// so the rider knows the figures below do not include them yet. Hidden when
/// the queue is empty; a tap opens the queue.
class PendingSyncBanner extends ConsumerWidget {
  const PendingSyncBanner({this.bottomGap = AppSpacing.cardGap, super.key});

  /// Space below the banner (only while it shows).
  final double bottomGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(pendingSyncProvider);
    if (queue.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final failed = queue.failedCount > 0;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('pending.banner'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => context.push(Routes.pendingRecords),
          child: AppBanner(
            tone: failed ? BannerTone.warning : BannerTone.info,
            message: failed
                ? l10n.pendingBannerFailed(queue.failedCount)
                : l10n.pendingBannerWaiting(queue.waitingCount),
          ),
        ),
      ),
    );
  }
}
