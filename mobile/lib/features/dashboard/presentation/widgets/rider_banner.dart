import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../core/widgets/app_surfaces.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';

/// Top of Home: the greeting on a sage card, with a delivery rider riding in
/// on a scooter. The illustration is drawn in code (no image asset), in the
/// app palette, and is decorative only.
class RiderGreetingBanner extends StatelessWidget {
  const RiderGreetingBanner({required this.name, super.key});

  final String name;

  /// Space under the wheels for the road markings.
  static const _groundInset = 20.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ToneCard(
      tone: AppTone.sage,
      radius: AppRadius.xl,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = Theme.of(context);
          final semantic = context.semanticColors;
          final riderWidth = (constraints.maxWidth * 0.5).clamp(140.0, 230.0);
          final riderHeight = riderWidth * RideScenePainter.aspectRatio;
          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: riderHeight + _groundInset + AppSpacing.md,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: RideScene(
                      riderWidth: riderWidth,
                      groundInset: _groundInset,
                    ),
                  ),
                ),
                Padding(
                  // The text keeps clear of the rider at any text size.
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    riderWidth + AppSpacing.xs,
                    _groundInset + AppSpacing.md,
                  ),
                  child: Semantics(
                    container: true,
                    label:
                        '${l10n.homeGreeting(name)}, ${l10n.homeBannerMessage}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: semantic.accent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xxs,
                            ),
                            child: Text(
                              l10n.homeHello,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: semantic.onAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          name,
                          key: const Key('home.name'),
                          style: theme.textTheme.headlineMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          l10n.homeBannerMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Plays the ride-in once (skipped with reduced motion), then holds still.
class RideScene extends StatefulWidget {
  const RideScene({
    required this.riderWidth,
    required this.groundInset,
    super.key,
  });

  final double riderWidth;
  final double groundInset;

  @override
  State<RideScene> createState() => _RideSceneState();
}

class _RideSceneState extends State<RideScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final Animation<double> _ride = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionEnabled(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: RideScenePainter(
          progress: _ride,
          palette: RideScenePalette.of(Theme.of(context).brightness),
          riderWidth: widget.riderWidth,
          groundInset: widget.groundInset,
        ),
      ),
    );
  }
}

/// Colours of the scene for each theme.
@immutable
class RideScenePalette {
  const RideScenePalette({
    required this.ink,
    required this.inkShade,
    required this.inkDetail,
    required this.pale,
    required this.accent,
    required this.accentShade,
    required this.accentDetail,
    required this.tire,
    required this.rim,
    required this.visor,
    required this.glow,
    required this.ring,
    required this.road,
    required this.dash,
    required this.speed,
    required this.shadow,
  });

  /// Obsidian scooter and jacket on the sage card.
  static const light = RideScenePalette(
    ink: AppColors.obsidian,
    inkShade: Color(0xFF2B3530),
    inkDetail: Color(0x8CF5F6F1),
    pale: AppColors.ivory,
    accent: AppColors.lime,
    accentShade: Color(0xFFB9E25E),
    accentDetail: Color(0x59151A17),
    tire: AppColors.obsidian,
    rim: AppColors.ivory,
    visor: AppColors.obsidian,
    glow: Color(0x61F5F6F1),
    ring: Color(0x80F5F6F1),
    road: Color(0x38151A17),
    dash: Color(0xD9F5F6F1),
    speed: Color(0xE6F5F6F1),
    shadow: Color(0x29151A17),
  );

  /// Sage scooter on the dark sage card; lime stays the highlight.
  static const dark = RideScenePalette(
    ink: AppColors.sage,
    inkShade: AppColors.teal,
    inkDetail: Color(0x99172B26),
    pale: AppColors.ivory,
    accent: AppColors.lime,
    accentShade: Color(0xFFB9E25E),
    accentDetail: Color(0x59151A17),
    tire: Color(0xFF0B0E0C),
    rim: AppColors.ivory,
    visor: AppColors.obsidian,
    glow: Color(0x14D5FF83),
    ring: Color(0x33D5FF83),
    road: Color(0x29F5F6F1),
    dash: Color(0x59F5F6F1),
    speed: Color(0xB3D5FF83),
    shadow: Color(0x59000000),
  );

  static RideScenePalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  final Color ink;
  final Color inkShade;
  final Color inkDetail;
  final Color pale;
  final Color accent;
  final Color accentShade;
  final Color accentDetail;
  final Color tire;
  final Color rim;
  final Color visor;
  final Color glow;
  final Color ring;
  final Color road;
  final Color dash;
  final Color speed;
  final Color shadow;
}

/// Flat side view of a delivery rider on a scooter, facing right. Drawn in
/// units with the wheels on y = 170; the box x 14–226, y 8–170 is scaled to
/// [riderWidth] and placed at the right of the canvas on the road.
class RideScenePainter extends CustomPainter {
  RideScenePainter({
    required this.progress,
    required this.palette,
    required this.riderWidth,
    required this.groundInset,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final RideScenePalette palette;
  final double riderWidth;
  final double groundInset;

  static const _left = 14.0;
  static const _top = 8.0;
  static const _unitWidth = 212.0;
  static const _ground = 170.0;

  /// Height / width of the rider box.
  static const aspectRatio = (_ground - _top) / _unitWidth;

  /// How far behind its resting place (units) the ride starts.
  static const _travel = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final s = riderWidth / _unitWidth;
    final riderHeight = riderWidth * aspectRatio;
    final groundY = size.height - groundInset;
    final riderLeft = size.width - riderWidth - AppSpacing.xs;

    _paintBackdrop(canvas, size, t, groundY, riderLeft, riderHeight);

    final opacity = (t * 3).clamp(0.0, 1.0);
    if (opacity < 1) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
    } else {
      canvas.save();
    }
    canvas
      ..translate(
        riderLeft - (_left + (1 - t) * _travel) * s,
        groundY - _ground * s,
      )
      ..scale(s);
    _paintRider(canvas, t);
    canvas.restore();
  }

  void _paintBackdrop(
    Canvas canvas,
    Size size,
    double t,
    double groundY,
    double riderLeft,
    double riderHeight,
  ) {
    final centre = Offset(
      riderLeft + riderWidth * 0.56,
      groundY - riderHeight * 0.56,
    );
    final radius = riderHeight * 0.6;
    canvas
      ..drawCircle(centre, radius, Paint()..color = palette.glow)
      ..drawCircle(
        centre,
        radius * 1.18,
        Paint()
          ..color = palette.ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawLine(
        Offset(0, groundY),
        Offset(size.width, groundY),
        Paint()
          ..color = palette.road
          ..strokeWidth = 1.5,
      );

    // Lane markings slide past while the rider arrives.
    const dash = 18.0;
    const gap = 14.0;
    final shift = (t * 150) % (dash + gap);
    final markY = groundY + 9;
    final markPaint = Paint()
      ..color = palette.dash
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = -shift; x < size.width; x += dash + gap) {
      final start = math.max(x, AppSpacing.xl);
      final end = math.min(x + dash, size.width - AppSpacing.xl);
      if (end > start) {
        canvas.drawLine(Offset(start, markY), Offset(end, markY), markPaint);
      }
    }
  }

  void _paintRider(Canvas canvas, double t) {
    final p = palette;
    Paint fill(Color color) => Paint()..color = color;
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(124, 171), width: 200, height: 8),
      fill(p.shadow),
    );

    // Speed lines while moving.
    final speed = 1 - t;
    if (speed > 0.01) {
      final paint = stroke(p.speed.withValues(alpha: p.speed.a * speed), 3.2);
      final length = 18 + 30 * speed;
      for (final (y, x) in const [(98.0, 8.0), (114.0, 14.0), (130.0, 2.0)]) {
        canvas.drawLine(Offset(x - length, y), Offset(x, y), paint);
      }
    }

    // Wheels turn with the distance travelled.
    final turn = t * _travel / 22 * 1.6;
    _wheel(canvas, const Offset(62, 148), turn);
    _wheel(canvas, const Offset(186, 148), turn);

    // A small bounce that settles as the scooter stops.
    canvas
      ..save()
      ..translate(0, math.sin(t * math.pi * 5) * 1.8 * speed);

    // Scooter.
    canvas.drawRRect(
      RRect.fromLTRBR(98, 140, 150, 158, const Radius.circular(6)),
      fill(p.inkShade),
    );
    final cowl = Path()
      ..moveTo(20, 146)
      ..cubicTo(18, 124, 38, 104, 74, 102)
      ..lineTo(116, 102)
      ..cubicTo(126, 102, 130, 110, 128, 120)
      ..lineTo(122, 146)
      ..close();
    final floor = Path()
      ..moveTo(116, 132)
      ..lineTo(166, 132)
      ..lineTo(166, 148)
      ..lineTo(112, 148)
      ..close();
    final stem = Path()
      ..moveTo(150, 148)
      ..cubicTo(158, 122, 160, 96, 156, 70)
      ..lineTo(170, 68)
      ..cubicTo(176, 98, 178, 124, 172, 148)
      ..close();
    final fender = Path()
      ..moveTo(162, 148)
      ..cubicTo(162, 128, 174, 118, 190, 118)
      ..cubicTo(204, 118, 216, 128, 218, 142)
      ..lineTo(210, 143)
      ..cubicTo(207, 132, 198, 126, 188, 126)
      ..cubicTo(176, 126, 170, 136, 170, 148)
      ..close();
    final ink = fill(p.ink);
    canvas
      ..drawPath(cowl, ink)
      ..drawPath(floor, ink)
      ..drawPath(stem, ink)
      ..drawPath(fender, ink)
      ..drawPath(
        Path()
          ..moveTo(34, 138)
          ..cubicTo(32, 124, 42, 114, 56, 110),
        stroke(p.inkDetail, 2.2),
      )
      // Mirror, headset, grip and lamp.
      ..drawLine(
        const Offset(160, 55),
        const Offset(156, 43),
        stroke(p.ink, 2.6),
      )
      ..drawCircle(const Offset(155.5, 40.5), 3.6, ink)
      ..drawRRect(
        RRect.fromLTRBR(150, 54, 178, 68, const Radius.circular(7)),
        ink,
      )
      ..drawLine(const Offset(152, 59), const Offset(140, 61), stroke(p.ink, 6))
      ..drawCircle(const Offset(182, 61), 6.5, ink)
      ..drawCircle(const Offset(183.5, 61), 3.2, fill(p.pale))
      // Seat.
      ..drawRRect(
        RRect.fromLTRBR(56, 92, 118, 104, const Radius.circular(6)),
        fill(p.accent),
      );

    // Rider: delivery box on the back.
    canvas
      ..drawRRect(
        RRect.fromLTRBR(58, 30, 100, 80, const Radius.circular(7)),
        fill(p.accent),
      )
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          90,
          30,
          100,
          80,
          topRight: const Radius.circular(7),
          bottomRight: const Radius.circular(7),
        ),
        fill(p.accentShade),
      )
      ..drawLine(
        const Offset(66, 40),
        const Offset(84, 40),
        stroke(p.accentDetail, 2.2),
      )
      ..drawLine(
        const Offset(66, 47),
        const Offset(78, 47),
        stroke(p.accentDetail, 2.2),
      );

    // Legs and shoe.
    final pale = fill(p.pale);
    canvas
      ..drawLine(
        const Offset(98, 90),
        const Offset(138, 88),
        stroke(p.pale, 17),
      )
      ..drawLine(
        const Offset(138, 88),
        const Offset(144, 124),
        stroke(p.pale, 14),
      )
      ..drawRRect(
        RRect.fromLTRBR(133, 119, 160, 132, const Radius.circular(5)),
        ink,
      )
      ..drawRRect(
        RRect.fromLTRBR(132, 129, 161, 133.5, const Radius.circular(2)),
        pale,
      )
      ..drawLine(
        const Offset(140, 124),
        const Offset(146, 121),
        stroke(p.inkDetail, 1.6),
      )
      ..drawLine(
        const Offset(144, 127),
        const Offset(150, 124),
        stroke(p.inkDetail, 1.6),
      );

    // Jacket, collar, helmet.
    final torso = Path()
      ..moveTo(90, 94)
      ..cubicTo(88, 74, 92, 58, 102, 50)
      ..cubicTo(108, 45, 118, 44, 124, 50)
      ..cubicTo(130, 58, 130, 76, 124, 96)
      ..close();
    canvas
      ..drawPath(torso, ink)
      ..drawPath(
        Path()
          ..moveTo(119, 54)
          ..cubicTo(124, 66, 124, 80, 119, 94),
        stroke(p.inkDetail, 1.8),
      )
      ..drawRRect(
        RRect.fromLTRBR(110, 38, 122, 50, const Radius.circular(4)),
        ink,
      )
      ..drawCircle(const Offset(120, 28), 15, pale)
      ..drawRRect(
        RRect.fromLTRBR(118, 19, 136, 33, const Radius.circular(6)),
        fill(p.visor),
      )
      ..drawLine(
        const Offset(124, 23.5),
        const Offset(130, 23.5),
        stroke(p.pale.withValues(alpha: 0.7), 1.6),
      );

    // Arm reaching the grip, glove on top.
    canvas
      ..drawPath(
        Path()
          ..moveTo(112, 58)
          ..quadraticBezierTo(128, 66, 146, 60),
        stroke(p.ink, 11),
      )
      ..drawPath(
        Path()
          ..moveTo(116, 64)
          ..quadraticBezierTo(129, 70, 143, 65.5),
        stroke(p.inkDetail, 1.6),
      )
      ..drawCircle(const Offset(148, 59.5), 6.5, fill(p.accent))
      ..restore();
  }

  void _wheel(Canvas canvas, Offset centre, double turn) {
    final p = palette;
    canvas
      ..drawCircle(centre, 22, Paint()..color = p.tire)
      ..drawCircle(centre, 13, Paint()..color = p.rim);
    final spoke = Paint()
      ..color = p.tire
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final angle = turn + i * 2 * math.pi / 5;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        centre + direction * 6.5,
        centre + direction * 10.5,
        spoke,
      );
    }
    canvas.drawCircle(centre, 4.5, Paint()..color = p.tire);
  }

  @override
  bool shouldRepaint(RideScenePainter oldDelegate) =>
      oldDelegate.palette != palette ||
      oldDelegate.riderWidth != riderWidth ||
      oldDelegate.groundInset != groundInset ||
      oldDelegate.progress != progress;
}
