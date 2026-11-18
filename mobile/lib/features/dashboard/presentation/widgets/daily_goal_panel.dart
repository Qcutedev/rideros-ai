import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_layout.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/status_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/domain/rider_profile.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../domain/daily_goal.dart';

/// Daily goal block inside today's hero card: a progress ring with what is
/// still to earn, or an invitation to set a goal. Tapping opens the goal sheet.
/// Nothing shows until the rider profile (which holds the goal) has loaded.
class DailyGoalPanel extends ConsumerWidget {
  const DailyGoalPanel({required this.net, required this.currency, super.key});

  /// Today's net profit (server figure).
  final Decimal net;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(riderProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();
    final goal = profile.dailyGoal;
    return Material(
      color: context.semanticColors.mint,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key(goal == null ? 'goal.set' : 'goal.edit'),
        onTap: () => showDailyGoalSheet(context, profile),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: goal == null
              ? const _SetGoal()
              : _Progress(
                  progress: GoalProgress(net: net, goal: goal),
                  currency: currency,
                ),
        ),
      ),
    );
  }
}

class _SetGoal extends StatelessWidget {
  const _SetGoal();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: semantic.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.flag_rounded, size: 20, color: semantic.onAccent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.goalSetTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.goalSetMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.add_rounded, color: theme.colorScheme.onSurface),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress, required this.currency});

  final GoalProgress progress;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String money(Decimal value) => Formats.currency(value, currency);
    final reached = progress.reached;
    return MergeSemantics(
      child: Row(
        children: [
          GoalRing(progress: progress),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalTarget(money(progress.goal)),
                  key: const Key('goal.target'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  reached
                      ? l10n.goalReached
                      : l10n.goalRemaining(money(progress.remaining)),
                  key: const Key('goal.status'),
                  style: AppTypography.figures(
                    theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: reached ? context.semanticColors.accent : null,
                    ),
                  ),
                ),
                if (reached && progress.surplus > Decimal.zero)
                  Text(
                    l10n.goalSurplus(money(progress.surplus)),
                    key: const Key('goal.surplus'),
                    style: AppTypography.figures(theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.edit_rounded,
            size: 18,
            semanticLabel: l10n.goalEdit,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Ring that fills to the goal; at 100% a check pops in and a few lime sparks
/// fly out once (no sparks when the system asks for reduced motion).
class GoalRing extends StatelessWidget {
  const GoalRing({required this.progress, this.size = 60, super.key});

  final GoalProgress progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final animate = motionEnabled(context);
    final accent = context.semanticColors.accent;
    final target = progress.fraction;
    return Semantics(
      label: l10n.goalPercent(progress.percent),
      child: SizedBox.square(
        key: const Key('goal.ring'),
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (progress.reached && animate)
              Positioned.fill(child: _Sparks(color: accent)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0 : target, end: target),
              duration: animate ? AppDurations.reveal : Duration.zero,
              curve: AppCurves.enter,
              builder: (context, value, _) => CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  value: value,
                  color: accent,
                  track: theme.colorScheme.onSurface.withValues(alpha: 0.14),
                  stroke: size * 0.11,
                ),
              ),
            ),
            ExcludeSemantics(
              child: progress.reached
                  ? SuccessCheck(size: size * 0.42)
                  : Text(
                      l10n.goalPercent(progress.percent),
                      key: const Key('goal.percent'),
                      style: AppTypography.figures(
                        theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    canvas.drawArc(
      ring,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (value <= 0) return;
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke;
}

/// One burst of dots flying out of the ring and fading.
class _Sparks extends StatelessWidget {
  const _Sparks({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (context, t, _) => t >= 1
        ? const SizedBox.shrink()
        : CustomPaint(
            painter: _SparksPainter(t: t, color: color),
          ),
  );
}

class _SparksPainter extends CustomPainter {
  _SparksPainter({required this.t, required this.color});

  final double t;
  final Color color;

  static const _count = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final start = size.shortestSide * 0.42;
    final distance = start + t * 10;
    final paint = Paint()..color = color.withValues(alpha: 1 - t);
    for (var i = 0; i < _count; i++) {
      final angle = math.pi * 2 * i / _count - math.pi / 2;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        3 * (1 - t / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.t != t || old.color != color;
}

/// Bottom sheet to set, change or remove the daily goal. Opened from the root
/// navigator's context: over the tab bar, and in the app theme rather than the
/// Obsidian tone of the card the button sits on.
Future<void> showDailyGoalSheet(BuildContext context, RiderProfile profile) =>
    showModalBottomSheet<void>(
      context: Navigator.of(context, rootNavigator: true).context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _GoalSheet(profile: profile),
    );

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({required this.profile});

  final RiderProfile profile;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.profile.dailyGoal == null
        ? ''
        : Formats.decimalInput(widget.profile.dailyGoal!),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await _store(optionalDecimalOf(_amount));
  }

  Future<void> _remove() async {
    FocusScope.of(context).unfocus();
    await _store(null);
  }

  Future<void> _store(Decimal? goal) async {
    final l10n = AppLocalizations.of(context);
    final messenger = shellMessenger(context);
    final ok = await ref
        .read(dailyGoalFormProvider.notifier)
        .save(widget.profile, goal);
    if (!ok || !mounted) return;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        successSnackBar(goal == null ? l10n.goalRemoved : l10n.goalSaved),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(dailyGoalFormProvider);
    final busy = submit.isLoading;
    final limit = RiderProfileLimits.dailyGoal;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.goalSheetTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.goalSheetMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            formGap,
            AppTextField(
              key: const Key('goal.amount'),
              controller: _amount,
              label: l10n.goalField,
              keyboardType: decimalKeyboard,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.flag_outlined,
              suffixText: widget.profile.currency,
              enabled: !busy,
              onFieldSubmitted: (_) => _save(),
              validator: (value) => v.requiredDecimal(
                value,
                maxDigits: limit.maxDigits,
                places: limit.places,
                positive: true,
              ),
            ),
            if (submit case AsyncError(:final AppFailure error)) ...[
              formGap,
              AppBanner.failure(context, error),
            ],
            formGap,
            AppPrimaryButton(
              key: const Key('goal.save'),
              label: l10n.recordSave,
              isLoading: busy,
              onPressed: _save,
            ),
            if (widget.profile.dailyGoal != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('goal.remove'),
                onPressed: busy ? null : _remove,
                child: Text(l10n.goalRemove),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
