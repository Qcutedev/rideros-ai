import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_labels.dart';
import 'pickup_providers.dart';

/// `/pickup/restaurants/:id/prediction` (S-PREDICTION-RESULT): asks the model for
/// an order placed now and shows the interval first, the midpoint second, the
/// warnings and the disclaimer.
class PredictionResultScreen extends ConsumerWidget {
  const PredictionResultScreen({required this.restaurantId, super.key});

  final String restaurantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final prediction = ref.watch(predictionProvider(restaurantId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.predictionTitle)),
      body: AsyncValueView(
        value: prediction,
        loading: LoadingView(message: l10n.predictionLoading),
        onRetry: () => ref.invalidate(predictionProvider(restaurantId)),
        data: (p) => ListView(
          padding: AppSpacing.screen,
          children: [
            PredictionCard(prediction: p),
            const SizedBox(height: AppSpacing.lg),
            for (final code in predictionWarnings(p)) ...[
              AppBanner(
                key: Key('prediction.warning.$code'),
                message: predictionWarningText(l10n, code),
                tone: BannerTone.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            _DisclaimerCard(prediction: p),
            const SizedBox(height: AppSpacing.xl),
            AppSecondaryButton(
              key: const Key('prediction.log'),
              label: l10n.restaurantLogPickup,
              onPressed: () => context.push(
                Routes.pickupLogNewFor(
                  restaurantId: restaurantId,
                  name: p.restaurantName,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              key: const Key('prediction.again'),
              onPressed: () => ref.invalidate(predictionProvider(restaurantId)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.predictionAgain),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero card: title, the interval (large), midpoint (small), coverage.
class PredictionCard extends StatelessWidget {
  const PredictionCard({required this.prediction, super.key});

  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final coverage = prediction.interval.nominalCoverage;
    final name = prediction.restaurantName;
    return Card(
      key: const Key('prediction.card'),
      color: semantic.hero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.predictionTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: semantic.onHero,
                    ),
                  ),
                ),
                _HeroBadge(label: l10n.badgeEstimate),
              ],
            ),
            if (name != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: semantic.onHeroMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              minutesRange(l10n, prediction.interval),
              key: const Key('prediction.range'),
              style: AppTypography.figures(
                theme.textTheme.displaySmall?.copyWith(
                  color: semantic.onHero,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.predictionMidpoint(minutes1(prediction.predictedMinutes)),
              key: const Key('prediction.midpoint'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: semantic.onHeroMuted,
              ),
            ),
            if (coverage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.predictionCoverage((coverage * 100).round().toString()),
                key: const Key('prediction.coverage'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: semantic.onHero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `ค่าประมาณ` on the dark hero card (the amber badge is for light surfaces).
class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    return Container(
      key: const Key('prediction.estimateBadge'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: semantic.onHero.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: semantic.onHero, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.prediction});

  final Prediction prediction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final requested = prediction.requestedAt;
    return SectionCard(
      key: const Key('prediction.disclaimer'),
      title: l10n.predictionDisclaimerTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.predictionDisclaimerThai,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.predictionServerText, style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            prediction.disclaimer,
            key: const Key('prediction.serverDisclaimer'),
            style: muted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.predictionMeta(
              prediction.modelVersion,
              '${Formats.date(requested, l10n.localeName)} '
              '${Formats.time(requested, l10n.localeName)}',
            ),
            key: const Key('prediction.meta'),
            style: muted,
          ),
        ],
      ),
    );
  }
}
