import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/session_state.dart';
import 'session_controller.dart';

/// Shown while the stored session is resumed. The router leaves it as soon as the
/// session is known; on a network/server failure it offers a retry (the stored
/// login is kept).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    if (session case SessionRestoreFailed(:final failure)) {
      return Scaffold(
        body: SafeArea(
          child: ErrorView(
            title: l10n.splashRestoreFailedTitle,
            failure: failure is AppFailure ? failure : UnknownFailure(failure),
            onRetry: () =>
                ref.read(sessionControllerProvider.notifier).restore(),
          ),
        ),
      );
    }
    final muted = context.semanticColors.onHeroMuted;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.obsidian,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: AppSpacing.screen,
                    child: AppWordmark(
                      title: l10n.appTitle,
                      tagline: l10n.appTagline,
                      onDark: true,
                    ),
                  ),
                ),
              ),
              const SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.lime,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.commonLoading,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}
