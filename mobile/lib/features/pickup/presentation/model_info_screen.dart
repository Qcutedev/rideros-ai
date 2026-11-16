import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';
import 'pickup_providers.dart';

/// `/pickup/model` (S-MODEL-INFO): what the model predicts, its single test
/// against the baseline, interval coverage, limitations, data source and licence,
/// and the required Meituan acknowledgement. Every figure comes from
/// `GET /pickup/model`; a missing figure is not shown.
class ModelInfoScreen extends ConsumerWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final info = ref.watch(modelInfoProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.modelTitle)),
      body: AsyncValueView(
        value: info,
        onRetry: () => ref.invalidate(modelInfoProvider),
        loading: const SingleChildScrollView(
          padding: AppSpacing.screen,
          child: SummarySkeleton(cards: 2),
        ),
        data: (m) => ListView(
          padding: AppSpacing.screen,
          children: [
            _WhatCard(info: m),
            const SizedBox(height: AppSpacing.lg),
            if (m.testMae != null) ...[
              _TestCard(info: m),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (m.testCoverage != null) ...[
              _CoverageCard(info: m),
              const SizedBox(height: AppSpacing.lg),
            ],
            _LimitationsCard(info: m),
            const SizedBox(height: AppSpacing.lg),
            _SourceCard(info: m),
          ],
        ),
      ),
    );
  }
}

String _fixed(double value, [int places = 2]) => value.toStringAsFixed(places);

String _percent(double ratio) => '${(ratio * 100).toStringAsFixed(1)}%';

TextStyle? _muted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodySmall?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}

class _WhatCard extends StatelessWidget {
  const _WhatCard({required this.info});

  final ModelInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trained = info.trainedAt;
    final algorithm = info.algorithm;
    return SectionCard(
      tone: AppTone.obsidian,
      key: const Key('model.what'),
      title: l10n.modelWhatTitle,
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.modelWhatBody),
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                l10n.modelVersion(info.name, info.version),
                if (algorithm != null) l10n.modelAlgorithm(algorithm),
                if (trained != null)
                  l10n.modelTrainedAt(
                    Formats.date(trained.toLocal(), l10n.localeName),
                  ),
              ].join(' · '),
              key: const Key('model.version'),
              style: _muted(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.info});

  final ModelInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final baseline = info.baselineMae;
    final orders = info.testOrders;
    return SectionCard(
      key: const Key('model.test'),
      title: l10n.modelTestTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MetricTileRow(
            tiles: [
              MetricTile(
                key: const Key('model.mae'),
                label: l10n.modelMae,
                value: l10n.pickupMinutesValue(_fixed(info.testMae!)),
              ),
              if (baseline != null)
                MetricTile(
                  key: const Key('model.baselineMae'),
                  label: l10n.modelBaselineMae,
                  value: l10n.pickupMinutesValue(_fixed(baseline)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            [
              l10n.modelBaselineHint,
              if (orders != null) l10n.modelTestOrders(Formats.count(orders)),
            ].join(' · '),
            style: _muted(context),
          ),
        ],
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.info});

  final ModelInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nominal = info.nominalCoverage;
    final width = info.meanWidthMinutes;
    return SectionCard(
      tone: AppTone.sage,
      key: const Key('model.coverage'),
      title: l10n.modelCoverageTitle,
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MetricTileRow(
              tiles: [
                if (nominal != null)
                  MetricTile(
                    label: l10n.modelNominalCoverage,
                    value: '${(nominal * 100).round()}%',
                  ),
                MetricTile(
                  key: const Key('model.testCoverage'),
                  label: l10n.modelTestCoverage,
                  value: _percent(info.testCoverage!),
                ),
              ],
            ),
            if (width != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.modelMeanWidth(_fixed(width, 1)),
                style: _muted(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LimitationsCard extends StatelessWidget {
  const _LimitationsCard({required this.info});

  final ModelInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      tone: AppTone.mist,
      key: const Key('model.limitations'),
      title: l10n.modelLimitationsTitle,
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.modelLimitationsBody),
            if (info.limitations.isNotEmpty)
              Theme(
                // No divider lines around the expansion tile inside the card.
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: const Key('model.serverLimitations'),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  title: Text(
                    l10n.modelServerLimitations,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  children: [
                    for (final item in info.limitations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: _muted(context)),
                            Expanded(child: Text(item, style: _muted(context))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.info});

  final ModelInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SectionCard(
      key: const Key('model.source'),
      title: l10n.modelSourceTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.modelLicense),
          const SizedBox(height: AppSpacing.sm),
          Text(info.dataset, style: _muted(context)),
          const SizedBox(height: AppSpacing.md),
          // Required wording, kept in English (Meituan licence terms). The
          // fixed text is shown even if the server ever sent something else.
          Text(
            l10n.meituanAcknowledgement,
            key: const Key('model.acknowledgement'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
