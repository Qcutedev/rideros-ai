import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/pickup_models.dart';

String dataAvailabilityLabel(AppLocalizations l10n, DataAvailability value) =>
    switch (value) {
      DataAvailability.sufficient => l10n.dataSufficient,
      DataAvailability.limited => l10n.dataLimited,
      DataAvailability.insufficient => l10n.dataInsufficient,
    };

/// Minutes with at most one decimal: `10.433` → `10.4`, `12.0` → `12`.
String minutes1(Decimal value) => Formats.compact(value.round(scale: 1));

/// A prediction interval in whole minutes, widened outwards (low down, high up)
/// so rounding never narrows what the model said: `5.04–19.99` → `5–20 นาที`.
String minutesRange(AppLocalizations l10n, PredictionInterval interval) =>
    l10n.pickupMinutesRange(
      interval.low.floor().toBigInt().toString(),
      interval.high.ceil().toBigInt().toString(),
    );

/// Source badge (`Dataset` / `ร้านของฉัน`) and data level of a restaurant.
class RestaurantBadges extends StatelessWidget {
  const RestaurantBadges({required this.restaurant, super.key});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final availability = restaurant.dataAvailability;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        AppBadge(
          label: restaurant.isOwn ? l10n.badgeOwn : l10n.badgeDataset,
          tone: restaurant.isOwn ? BadgeTone.neutral : BadgeTone.info,
        ),
        // Own restaurants have no dataset orders: no data level.
        if (!restaurant.isOwn && availability != null)
          AppBadge(
            label: dataAvailabilityLabel(l10n, availability),
            tone: availability == DataAvailability.sufficient
                ? BadgeTone.neutral
                : BadgeTone.warning,
          ),
      ],
    );
  }
}

/// Thai text of a prediction warning code.
String predictionWarningText(AppLocalizations l10n, String code) =>
    switch (code) {
      PredictionWarning.foreignDataset => l10n.predictionWarningForeign,
      PredictionWarning.limitedRestaurantData => l10n.predictionWarningLimited,
      PredictionWarning.insufficientRestaurantData =>
        l10n.predictionWarningInsufficient,
      _ => l10n.predictionWarningOther(code),
    };

/// Warnings in display order; `foreign_dataset` is always first and always shown,
/// even if a server response ever lacked it.
List<String> predictionWarnings(Prediction prediction) => [
  PredictionWarning.foreignDataset,
  ...prediction.warnings.where((w) => w != PredictionWarning.foreignDataset),
];
