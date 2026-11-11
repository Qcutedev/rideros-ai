import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../theme/tokens.dart';
import 'brand_logo.dart';

/// The moving parts of the ride intro.
class RideScene {
  RideScene({
    required this.arrive,
    required this.wordmark,
    required this.leave,
    required this.road,
    this.motion = true,
  });

  /// The intro timeline on [reveal] (2.4 s) and [exit] (0.6 s): the rider rides
  /// in from the left and slows to the centre, the camera then rides along
  /// (road and wind keep streaming), the wordmark rises in under the road; at
  /// the end the rider accelerates off to the right.
  factory RideScene.timeline({
    required Animation<double> reveal,
    required Animation<double> exit,
    required ValueListenable<double> road,
    bool motion = true,
  }) => RideScene(
    arrive: TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0), weight: 6),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 46,
      ),
      TweenSequenceItem(tween: ConstantTween(1), weight: 48),
    ]).animate(reveal),
    wordmark: CurvedAnimation(
      parent: reveal,
      curve: const Interval(0.50, 0.76, curve: Curves.easeOutCubic),
    ),
    leave: CurvedAnimation(
      parent: exit,
      curve: const Interval(0, 0.85, curve: Curves.easeInCubic),
    ),
    road: road,
    motion: motion,
  );

  /// 0 = off-screen left, 1 = at the centre.
  final Animation<double> arrive;

  /// Wordmark fade-and-rise, 0–1.
  final Animation<double> wordmark;

  /// 0 = at the centre, 1 = off-screen right.
  final Animation<double> leave;

  /// Distance the camera has travelled (logo units); drives the road and wind.
  final ValueListenable<double> road;

  /// False when the system asks for reduced motion: nothing slides or leans.
  final bool motion;

  /// How fast the camera rides along (0 = still, 1 = cruising).
  double get cruise => arrive.value * (1 - leave.value);

  Listenable get listenable =>
      Listenable.merge([arrive, wordmark, leave, road]);
}

/// Paints the ride intro over the whole screen, logo centred.
/// Repaints itself from the scene, so the widget above never rebuilds.
class RideScenePainter extends CustomPainter {
  RideScenePainter({required this.logo, required this.scene})
    : super(repaint: scene.listenable);

  final BrandLogo logo;
  final RideScene scene;

  /// The road, in logo units: just under the rider, above the wordmark.
  static const _roadY = 436.0;

  /// Lane-mark rhythm and length (logo units).
  static const _laneGap = 150.0;
  static const _laneLength = 46.0;

  /// Wind streaks behind the rider: height, length (logo units), opacity and
  /// parallax (how much faster than the road they stream past).
  static const _wind = [
    (y: 118.0, length: 150.0, alpha: 0.16, parallax: 1.5, phase: 0.15),
    (y: 214.0, length: 260.0, alpha: 0.22, parallax: 2.2, phase: 0.62),
    (y: 300.0, length: 120.0, alpha: 0.15, parallax: 1.3, phase: 0.38),
    (y: 384.0, length: 210.0, alpha: 0.19, parallax: 1.9, phase: 0.87),
    (y: 520.0, length: 170.0, alpha: 0.12, parallax: 1.1, phase: 0.05),
  ];

  /// Logo width on screen: ~62 % of the short side, kept readable on small
  /// phones and modest on tablets.
  static double logoWidth(Size screen) =>
      (screen.shortestSide * 0.62).clamp(160.0, 340.0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = logoWidth(size) / BrandLogo.viewBox.width;
    if (s <= 0) return;
    // Logo space → screen: the viewBox centre sits at the screen centre.
    Offset at(double x, double y) => Offset(
      size.width / 2 + (x - BrandLogo.viewBox.width / 2) * s,
      size.height / 2 + (y - BrandLogo.viewBox.height / 2) * s,
    );
    final cruise = scene.cruise;
    final travelled = scene.road.value * s;

    _paintWind(canvas, size, at, s, travelled, cruise);
    _paintRoad(canvas, size, at(0, _roadY).dy, s, travelled);
    _paintRider(canvas, size, at, s, cruise);
    _paintWordmark(canvas, at, s);
  }

  void _paintRoad(
    Canvas canvas,
    Size size,
    double y,
    double s,
    double travelled,
  ) {
    // A hairline across the screen, fading out at both edges.
    double edge(double x) {
      final t = (x / size.width).clamp(0.0, 1.0);
      return math.min(1.0, math.min(t, 1 - t) / 0.22);
    }

    final ivory = AppColors.logoIvory;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 1
        ..shader = ui.Gradient.linear(
          Offset(0, y),
          Offset(size.width, y),
          [
            ivory.withValues(alpha: 0),
            ivory.withValues(alpha: 0.26),
            ivory.withValues(alpha: 0.26),
            ivory.withValues(alpha: 0),
          ],
          const [0, 0.22, 0.78, 1],
        ),
    );

    // Lane marks streaming backwards under the rider.
    final gap = _laneGap * s;
    final dash = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = -(travelled % gap); x < size.width + gap; x += gap) {
      final mid = x + _laneLength * s / 2;
      final alpha = 0.42 * edge(mid);
      if (alpha <= 0) continue;
      dash.color = ivory.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y + 6),
        Offset(x + _laneLength * s, y + 6),
        dash,
      );
    }
  }

  void _paintWind(
    Canvas canvas,
    Size size,
    Offset Function(double, double) at,
    double s,
    double travelled,
    double cruise,
  ) {
    if (cruise <= 0.01) return;
    final paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final w in _wind) {
      final length = w.length * s;
      final span = size.width + length;
      final head =
          size.width - ((travelled * w.parallax + w.phase * span) % span);
      final y = at(0, w.y).dy;
      final colour = AppColors.logoIvory.withValues(alpha: w.alpha * cruise);
      paint.shader = ui.Gradient.linear(
        Offset(head, y),
        Offset(head + length, y),
        [colour, colour.withValues(alpha: 0)],
      );
      canvas.drawLine(Offset(head, y), Offset(head + length, y), paint);
    }
  }

  void _paintRider(
    Canvas canvas,
    Size size,
    Offset Function(double, double) at,
    double s,
    double cruise,
  ) {
    final arrive = scene.arrive.value;
    final leave = scene.leave.value;
    if (arrive <= 0) return;

    // Screen speed of the rider (0–1): fast as it rides in, slowing to the
    // centre; picking up again as it leaves.
    final speed = scene.motion
        ? math.max(math.pow(1 - arrive, 2).toDouble(), leave * leave)
        : 0.0;
    final offstage = size.width / 2 + 420 * s;
    final dx = scene.motion ? -offstage * (1 - arrive) + offstage * leave : 0.0;
    // Engine/road vibration while cruising: under a pixel.
    final bob = scene.motion
        ? math.sin(scene.road.value / _laneGap * math.pi) * 0.8 * cruise
        : 0.0;
    final lean = -0.12 * speed;
    final opacity = scene.motion ? 1.0 : arrive;

    final base = Offset(logo.riderBounds.center.dx, logo.riderBounds.bottom);
    final anchor = at(base.dx, base.dy) + Offset(dx, bob);
    canvas
      ..save()
      ..translate(anchor.dx, anchor.dy)
      ..skew(lean, 0)
      ..scale(s)
      ..translate(-base.dx, -base.dy);

    // Speed trails stretch backwards with speed, anchored at the rider.
    final trails = logo.speedLinesBounds;
    final stretch = 1 + 0.9 * speed + 0.18 * cruise;
    canvas
      ..save()
      ..translate(trails.right, 0)
      ..scale(stretch, 1)
      ..translate(-trails.right, 0);
    _fill(canvas, BrandLayer.speedLines, opacity);
    canvas.restore();

    for (final layer in BrandLayer.rider) {
      _fill(canvas, layer, opacity);
    }
    canvas.restore();
  }

  void _paintWordmark(
    Canvas canvas,
    Offset Function(double, double) at,
    double s,
  ) {
    final t =
        scene.wordmark.value * (1 - (scene.leave.value * 2.5).clamp(0, 1));
    if (t <= 0) return;
    final centre = logo.wordmarkBounds.center;
    final screen = at(centre.dx, centre.dy) + Offset(0, (1 - t) * 10);
    final scale = s * ui.lerpDouble(0.95, 1, t)!;
    canvas
      ..save()
      ..translate(screen.dx, screen.dy)
      ..scale(scale)
      ..translate(-centre.dx, -centre.dy);
    final paint = Paint();
    for (final layer in BrandLayer.wordmark) {
      final colour = layer == BrandLayer.wordmarkOs
          ? AppColors.logoMint
          : AppColors.logoIvory;
      paint.color = colour.withValues(alpha: t);
      canvas.drawPath(logo.paths[layer]!, paint);
    }
    canvas.restore();
  }

  /// Ivory fill; the speed trails and the body's tail fade in from the left,
  /// as the `fade-*` gradients of the SVG do.
  void _fill(Canvas canvas, BrandLayer layer, double opacity) {
    final ivory = AppColors.logoIvory.withValues(alpha: opacity);
    final paint = Paint()..color = ivory;
    final (double from, double to, double start)? fade = switch (layer) {
      BrandLayer.speedLines => (20, 160, 0),
      BrandLayer.body => (58, 200, 0.15),
      _ => null,
    };
    if (fade != null) {
      paint
        ..color =
            const Color(0xFF000000) // opaque: the gradient carries alpha
        ..shader = ui.Gradient.linear(Offset(fade.$1, 0), Offset(fade.$2, 0), [
          ivory.withValues(alpha: opacity * fade.$3),
          ivory,
        ]);
    }
    canvas.drawPath(logo.paths[layer]!, paint);
  }

  @override
  bool shouldRepaint(RideScenePainter old) =>
      old.logo != logo || old.scene != scene;
}
