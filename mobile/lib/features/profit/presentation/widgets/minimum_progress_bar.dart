import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/widgets/motion.dart';

/// Progress towards a server minimum (sessions needed before an analysis is
/// shown): Lime on Obsidian, the theme's progress style, animated in unless
/// the rider reduces motion.
class MinimumProgressBar extends StatelessWidget {
  const MinimumProgressBar({
    required this.have,
    required this.need,
    required this.barKey,
    super.key,
  });

  final int have;
  final int need;

  /// Key of the [LinearProgressIndicator] itself, for tests.
  final Key barKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: need <= 0 ? 1 : (have / need).clamp(0, 1)),
      duration: motionEnabled(context) ? AppDurations.reveal : Duration.zero,
      curve: AppCurves.enter,
      builder: (context, v, _) => LinearProgressIndicator(
        key: barKey,
        value: v,
        minHeight: 10,
        color: AppColors.lime,
        backgroundColor: theme.brightness == Brightness.light
            ? AppColors.obsidian
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
