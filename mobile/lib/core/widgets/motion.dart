import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Whether decorative motion should run. Off when the rider asked the system
/// to reduce motion.
bool motionEnabled(BuildContext context) =>
    !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Shrinks its child slightly while a finger is down: tactile feedback for
/// cards and tiles. Listens to raw pointers, so the child's own [InkWell] or
/// buttons still receive the tap.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
    super.key,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !motionEnabled(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: widget.child,
      ),
    );
  }
}

/// Fades and lifts its child into place once, after a short stagger by
/// [index]. Used for cards appearing on a page.
class RevealIn extends StatefulWidget {
  const RevealIn({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<RevealIn> createState() => _RevealInState();
}

class _RevealInState extends State<RevealIn>
    with SingleTickerProviderStateMixin {
  static const _step = 70;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds:
          AppDurations.slow.inMilliseconds + math.min(widget.index, 6) * _step,
    ),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      1 -
          AppDurations.slow.inMilliseconds /
              _controller.duration!.inMilliseconds,
      1,
      curve: AppCurves.enter,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      motionEnabled(context) ? _controller.forward() : _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, (1 - _curve.value) * 16),
        child: child,
      ),
    ),
  );
}

/// A figure that counts up to [value] when it first appears and glides to a
/// new value when it changes. [text] is the exact final text (formatted from
/// the real number, not the double) and is what screen readers hear.
class AnimatedFigure extends StatelessWidget {
  const AnimatedFigure({
    required this.value,
    required this.text,
    required this.format,
    this.style,
    this.textKey,
    super.key,
  });

  final double value;
  final String text;
  final String Function(double value) format;
  final TextStyle? style;

  /// Key of the [Text] showing the figure (tests and finders use it).
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final animate = motionEnabled(context);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: animate ? 0 : value, end: value),
          duration: animate ? AppDurations.reveal : Duration.zero,
          curve: Curves.easeOutQuart,
          builder: (context, v, _) => Text(
            v == value ? text : format(v),
            key: textKey,
            style: style,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

/// Rounded progress bar that animates to [value] (0–1). Lime on Obsidian by
/// default, so it reads on any surface.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = 10,
    this.color,
    this.trackColor,
    super.key,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final track =
        trackColor ??
        (dark ? Colors.white.withValues(alpha: 0.1) : AppColors.obsidian);
    final fill = color ?? AppColors.lime;
    final target = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: track,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: target),
            duration: motionEnabled(context)
                ? AppDurations.reveal
                : Duration.zero,
            curve: AppCurves.enter,
            builder: (context, v, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws its child (a chart) in from left to right once.
class RevealFromStart extends StatelessWidget {
  const RevealFromStart({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.reveal,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: t == 0 ? 0.0001 : t,
          child: child,
        ),
      ),
    );
  }
}

/// A soft light band sweeping over skeleton placeholders. Runs for a bounded
/// time (long loads keep a still skeleton), and not at all with reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1400);
  static const _cycles = 6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period * _cycles,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionEnabled(context) && _controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!motionEnabled(context)) return widget.child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highlight = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          if (_controller.isCompleted) return child!;
          // Position of the band within the current cycle, −1 → 2.
          final t = (_controller.value * _cycles) % 1;
          final x = -1 + 3 * t;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment(x - 1, -0.3),
              end: Alignment(x, 0.3),
              colors: [Colors.transparent, highlight, Colors.transparent],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(rect),
            child: child,
          );
        },
      ),
    );
  }
}

/// "AI is working" indicator: a lime core with rings pulsing outward. Runs for
/// a bounded time, then holds still.
class AiPulse extends StatefulWidget {
  const AiPulse({this.size = 40, super.key});

  final double size;

  @override
  State<AiPulse> createState() => _AiPulseState();
}

class _AiPulseState extends State<AiPulse> with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1600);
  static const _cycles = 12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period * _cycles,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionEnabled(context) && _controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.onSurface;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _AiPulsePainter(
                phase: _controller.isAnimating
                    ? (_controller.value * _cycles) % 1
                    : 0.35,
                ring: ring,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiPulsePainter extends CustomPainter {
  _AiPulsePainter({required this.phase, required this.ring});

  final double phase;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    for (final offset in [0.0, 0.5]) {
      final p = (phase + offset) % 1;
      canvas.drawCircle(
        center,
        maxR * (0.35 + 0.65 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = ring.withValues(alpha: (1 - p) * 0.45),
      );
    }
    canvas.drawCircle(center, maxR * 0.32, Paint()..color = AppColors.lime);
    canvas.drawCircle(
      center,
      maxR * 0.32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.obsidian.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_AiPulsePainter old) =>
      old.phase != phase || old.ring != ring;
}

/// Check mark that pops in: the leading icon of "saved" messages.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({this.size = 22, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final animate = motionEnabled(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0 : 1, end: 1),
      duration: animate ? AppDurations.slow : Duration.zero,
      curve: Curves.elasticOut,
      builder: (context, t, child) =>
          Transform.scale(scale: t.clamp(0.0, 1.2), child: child),
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.lime,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: size * 0.72,
          color: AppColors.obsidian,
        ),
      ),
    );
  }
}
