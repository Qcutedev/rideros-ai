import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_surfaces.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profit/domain/shift_timer.dart';
import '../../../profit/presentation/profit_labels.dart';
import '../../../profit/presentation/shift_timer_controller.dart';

/// Home "start work" card. Start → a live clock; stop → the work session form
/// opens with the start and end filled in. The work session exists only once
/// the rider saves that form; until then the timer lives on this device.
class ShiftTimerCard extends ConsumerStatefulWidget {
  const ShiftTimerCard({super.key});

  @override
  ConsumerState<ShiftTimerCard> createState() => _ShiftTimerCardState();
}

/// The handlers live here, not in the three card faces: a face is replaced as
/// soon as the timer changes state, but this widget stays for the whole flow.
class _ShiftTimerCardState extends ConsumerState<ShiftTimerCard> {
  ShiftTimerController get _timer => ref.read(shiftTimerProvider.notifier);

  Future<void> _stop() async {
    final stopped = await _timer.stop();
    if (stopped != null && mounted) await _save(stopped);
  }

  /// Opens the work session form for a stopped timer, after the checks the form
  /// cannot make on its own (under a minute, over 24 hours).
  Future<void> _save(TimerStopped stopped) async {
    final l10n = AppLocalizations.of(context);
    final draft = stopped.draft;
    if (draft.tooShort) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.timerTooShortTitle),
          content: Text(l10n.timerTooShortMessage),
          actions: [
            TextButton(
              key: const Key('timer.shortDiscard'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.timerDiscard),
            ),
            FilledButton(
              key: const Key('timer.shortResume'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.timerResume),
            ),
          ],
        ),
      );
      if (discard == true) await _timer.reset();
      if (discard == false) await _timer.resume();
      return;
    }
    if (draft.tooLong) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.history_toggle_off_rounded),
          title: Text(l10n.timerTooLongTitle),
          content: Text(
            l10n.timerTooLongMessage(durationLabel(l10n, draft.length)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              key: const Key('timer.longContinue'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.timerTooLongContinue),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    final saved = await context.push<bool>(Routes.workSessionNew, extra: draft);
    if (saved == true) await _timer.reset();
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmDelete(
      context,
      title: l10n.timerDiscardTitle,
      message: l10n.timerDiscardMessage,
      confirmLabel: l10n.timerDiscard,
    );
    if (confirmed) await _timer.reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftTimerProvider).value;
    if (state == null) return const SizedBox.shrink();
    final face = switch (state) {
      TimerIdle() => _IdleFace(
        key: const ValueKey('idle'),
        onStart: _timer.start,
      ),
      TimerRunning() => _RunningFace(
        key: const ValueKey('running'),
        timer: state,
        onStop: _stop,
        onDiscard: _discard,
      ),
      TimerStopped() => _StoppedFace(
        key: const ValueKey('stopped'),
        timer: state,
        onSave: () => _save(state),
        onResume: _timer.resume,
        onDiscard: _discard,
      ),
    };
    return AnimatedSwitcher(
      duration: motionEnabled(context) ? AppDurations.medium : Duration.zero,
      child: face,
    );
  }
}

class _IdleFace extends StatelessWidget {
  const _IdleFace({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToneCard(
      key: const Key('timer.idle'),
      tone: AppTone.lime,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconWell(
                    icon: Icons.two_wheeler_rounded,
                    size: 40,
                    color: theme.colorScheme.onSurface,
                    iconColor: theme.colorScheme.surface,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.timerIdleTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.timerIdleMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                key: const Key('timer.start'),
                icon: Icons.play_arrow_rounded,
                label: l10n.timerStart,
                onPressed: onStart,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RunningFace extends StatelessWidget {
  const _RunningFace({
    required this.timer,
    required this.onStop,
    required this.onDiscard,
    super.key,
  });

  final TimerRunning timer;
  final VoidCallback onStop;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToneCard(
      key: const Key('timer.running'),
      tone: AppTone.obsidian,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final accent = context.semanticColors.accent;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.timerRunningTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l10n.timerStartedAt(
                      Formats.time(timer.startedAt.toLocal(), l10n.localeName),
                    ),
                    key: const Key('timer.startedAt'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Elapsed(
                startedAt: timer.startedAt,
                style: theme.textTheme.displaySmall?.copyWith(color: accent),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      key: const Key('timer.stop'),
                      icon: Icons.stop_rounded,
                      label: l10n.timerStop,
                      onPressed: onStop,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    key: const Key('timer.discard'),
                    onPressed: onDiscard,
                    child: Text(l10n.timerDiscard),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// `HH:MM:SS` since [startedAt], redrawn every second. Screen readers get the
/// hours and minutes only, so they are not interrupted every second.
class _Elapsed extends ConsumerStatefulWidget {
  const _Elapsed({required this.startedAt, this.style});

  final DateTime startedAt;
  final TextStyle? style;

  @override
  ConsumerState<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends ConsumerState<_Elapsed> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final elapsed = TimerRunning(widget.startedAt)
        .elapsed(ref.read(clockProvider)());
    return Semantics(
      label: l10n.timerElapsed(durationLabel(l10n, elapsed)),
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            clockLabel(elapsed),
            key: const Key('timer.elapsed'),
            style: AppTypography.figures(widget.style),
          ),
        ),
      ),
    );
  }
}

/// `4:05:09` → `04:05:09`; hours keep counting past 24.
String clockLabel(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

class _StoppedFace extends StatelessWidget {
  const _StoppedFace({
    required this.timer,
    required this.onSave,
    required this.onResume,
    required this.onDiscard,
    super.key,
  });

  final TimerStopped timer;
  final VoidCallback onSave;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String time(DateTime t) => Formats.time(t.toLocal(), l10n.localeName);
    return ToneCard(
      key: const Key('timer.stopped'),
      tone: AppTone.mist,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.timerStoppedTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.timerStoppedRange(
                  durationLabel(l10n, timer.elapsed),
                  time(timer.startedAt),
                  time(timer.stoppedAt),
                ),
                key: const Key('timer.range'),
                style: AppTypography.figures(theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                key: const Key('timer.save'),
                icon: Icons.save_rounded,
                label: l10n.timerSave,
                onPressed: onSave,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      key: const Key('timer.resume'),
                      label: l10n.timerResume,
                      onPressed: onResume,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextButton(
                      key: const Key('timer.discard'),
                      onPressed: onDiscard,
                      child: Text(l10n.timerDiscard),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
