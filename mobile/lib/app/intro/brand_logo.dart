import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';

import '../theme/tokens.dart';

/// The animation layers of the logo: one `<path id>` each in [BrandLogo.asset].
enum BrandLayer {
  speedLines('speed-lines'),
  body('body'),
  shoulder('shoulder'),
  helmet('helmet'),
  wordmarkRider('wordmark-rider'),
  wordmarkOs('wordmark-os');

  const BrandLayer(this.svgId);

  final String svgId;

  static const emblem = [speedLines, body, shoulder, helmet];
  static const wordmark = [wordmarkRider, wordmarkOs];
}

/// The RiderOS logo as Flutter paths, read from the SVG asset (the single source
/// of the artwork; the Android launcher icons are rendered from the same file).
class BrandLogo {
  BrandLogo._(this.paths)
    : _contours = {
        for (final e in paths.entries)
          e.key: e.value.computeMetrics().toList(growable: false),
      },
      emblemBounds = BrandLayer.emblem
          .map((l) => paths[l]!.getBounds())
          .reduce((a, b) => a.expandToInclude(b)),
      wordmarkBounds = BrandLayer.wordmark
          .map((l) => paths[l]!.getBounds())
          .reduce((a, b) => a.expandToInclude(b));

  static const asset = 'assets/brand/rideros_logo.svg';

  /// The SVG `viewBox` (logo units).
  static const viewBox = Size(808, 600);

  final Map<BrandLayer, Path> paths;
  final Map<BrandLayer, List<ui.PathMetric>> _contours;
  final Rect emblemBounds;
  final Rect wordmarkBounds;

  static Future<BrandLogo> load(AssetBundle bundle) async =>
      parse(await bundle.loadString(asset));

  /// Reads every layer's `d` attribute; throws [FormatException] if one is missing.
  static BrandLogo parse(String svg) {
    final data = <String, String>{};
    for (final tag in RegExp(r'<path\b[^>]*>').allMatches(svg)) {
      final text = tag[0]!;
      final id = RegExp(r'\sid="([^"]+)"').firstMatch(text)?[1];
      final d = RegExp(r'\sd="([^"]+)"').firstMatch(text)?[1];
      if (id != null && d != null) data[id] = d;
    }
    return BrandLogo._({
      for (final layer in BrandLayer.values)
        layer: _toPath(
          data[layer.svgId] ??
              (throw FormatException('Logo layer "${layer.svgId}" missing')),
        ),
    });
  }

  static Path _toPath(String d) {
    final path = Path()..fillType = PathFillType.evenOdd;
    writeSvgPathDataToPath(d, _PathWriter(path));
    return path;
  }

  /// The first [t] (0–1) of every contour of [layer], as drawn by a pen.
  Path outline(BrandLayer layer, double t) {
    final out = Path();
    for (final contour in _contours[layer]!) {
      out.addPath(contour.extractPath(0, contour.length * t), Offset.zero);
    }
    return out;
  }
}

class _PathWriter extends PathProxy {
  _PathWriter(this.path);

  final Path path;

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}

/// How far each stage of the logo reveal has got (all 0–1).
class LogoReveal {
  const LogoReveal({
    required this.speedLines,
    required this.body,
    required this.shoulder,
    required this.helmet,
    required this.fill,
    required this.wordmark,
  });

  /// The intro timeline on [parent] (the 2.6 s reveal controller):
  /// outlines draw in the direction of travel, the solid fill sweeps in behind
  /// them, then the wordmark rises in and the finished logo holds.
  factory LogoReveal.timeline(Animation<double> parent) {
    Animation<double> stage(
      double begin,
      double end, [
      Curve c = Curves.easeInOutCubic,
    ]) => CurvedAnimation(
      parent: parent,
      curve: Interval(begin, end, curve: c),
    );
    return LogoReveal(
      speedLines: stage(0.06, 0.34),
      body: stage(0.12, 0.48),
      shoulder: stage(0.26, 0.50),
      helmet: stage(0.30, 0.54),
      fill: stage(0.40, 0.66, Curves.easeInOutSine),
      wordmark: TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0), weight: 58),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 24,
        ),
        TweenSequenceItem(tween: ConstantTween(1), weight: 18),
      ]).animate(parent),
    );
  }

  /// The finished logo, for static use.
  static const complete = LogoReveal(
    speedLines: kAlwaysCompleteAnimation,
    body: kAlwaysCompleteAnimation,
    shoulder: kAlwaysCompleteAnimation,
    helmet: kAlwaysCompleteAnimation,
    fill: kAlwaysCompleteAnimation,
    wordmark: kAlwaysCompleteAnimation,
  );

  final Animation<double> speedLines;
  final Animation<double> body;
  final Animation<double> shoulder;
  final Animation<double> helmet;
  final Animation<double> fill;
  final Animation<double> wordmark;

  Animation<double> outline(BrandLayer layer) => switch (layer) {
    BrandLayer.speedLines => speedLines,
    BrandLayer.body => body,
    BrandLayer.shoulder => shoulder,
    BrandLayer.helmet => helmet,
    _ => fill,
  };

  Listenable get listenable =>
      Listenable.merge([speedLines, body, shoulder, helmet, fill, wordmark]);
}

/// Paints [logo] at the stage given by [reveal], scaled to fit (centred).
/// Repaints itself from the animations, so the widget above never rebuilds.
class BrandLogoPainter extends CustomPainter {
  BrandLogoPainter({required this.logo, required this.reveal})
    : super(repaint: reveal.listenable);

  final BrandLogo logo;
  final LogoReveal reveal;

  /// Outline width in logical pixels, whatever the logo's size.
  static const _penWidth = 1.2;

  /// Soft edge of the fill sweep, in logo units.
  static const _sweepFeather = 140.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / BrandLogo.viewBox.width).clamp(
      0.0,
      size.height / BrandLogo.viewBox.height,
    );
    if (scale <= 0) return;
    canvas
      ..save()
      ..translate(
        (size.width - BrandLogo.viewBox.width * scale) / 2,
        (size.height - BrandLogo.viewBox.height * scale) / 2,
      )
      ..scale(scale);
    _paintEmblem(canvas, scale);
    _paintWordmark(canvas);
    canvas.restore();
  }

  void _paintEmblem(Canvas canvas, double scale) {
    final fill = reveal.fill.value;

    // 1. Pen outlines, fading as the fill takes over.
    if (fill < 1) {
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _penWidth / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final layer in BrandLayer.emblem) {
        final t = reveal.outline(layer).value;
        if (t <= 0) continue;
        _ink(pen, layer, 1 - fill);
        canvas.drawPath(
          t >= 1 ? logo.paths[layer]! : logo.outline(layer, t),
          pen,
        );
      }
    }

    // 2. Solid fill, swept in from the left (the direction of travel).
    if (fill <= 0) return;
    final sweeping = fill < 1;
    final bounds = logo.emblemBounds.inflate(4);
    if (sweeping) canvas.saveLayer(bounds, Paint());
    final solid = Paint();
    for (final layer in BrandLayer.emblem) {
      _ink(solid, layer, 1);
      canvas.drawPath(logo.paths[layer]!, solid);
    }
    if (sweeping) {
      final edge = ui.lerpDouble(
        bounds.left - _sweepFeather,
        bounds.right,
        fill,
      )!;
      canvas
        ..drawRect(
          bounds,
          Paint()
            ..blendMode = BlendMode.dstIn
            ..shader = ui.Gradient.linear(
              Offset(edge, 0),
              Offset(edge + _sweepFeather, 0),
              const [Color(0xFF000000), Color(0x00000000)],
            ),
        )
        ..restore();
    }
  }

  void _paintWordmark(Canvas canvas) {
    final t = reveal.wordmark.value;
    if (t <= 0) return;
    final centre = logo.wordmarkBounds.center;
    final scale = ui.lerpDouble(0.94, 1, t)!;
    canvas
      ..save()
      ..translate(centre.dx, centre.dy + (1 - t) * 10)
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

  /// Ivory at [opacity]; the speed trails and the body's tail fade in from the
  /// left, as the `fade-*` gradients of the SVG do.
  static void _ink(Paint paint, BrandLayer layer, double opacity) {
    final (double from, double to, double start)? fade = switch (layer) {
      BrandLayer.speedLines => (20, 160, 0),
      BrandLayer.body => (58, 200, 0.15),
      _ => null,
    };
    final ivory = AppColors.logoIvory.withValues(alpha: opacity);
    if (fade == null) {
      paint
        ..shader = null
        ..color = ivory;
      return;
    }
    paint
      ..color =
          const Color(0xFF000000) // opaque: the gradient carries the alpha
      ..shader = ui.Gradient.linear(Offset(fade.$1, 0), Offset(fade.$2, 0), [
        ivory.withValues(alpha: opacity * fade.$3),
        ivory,
      ]);
  }

  @override
  bool shouldRepaint(BrandLogoPainter old) =>
      old.logo != logo || old.reveal != reveal;
}
