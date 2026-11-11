import 'dart:ui';

import 'package:flutter/rendering.dart' hide Gradient;
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';

/// The layers of the logo: one `<path id>` each in [BrandLogo.asset].
enum BrandLayer {
  speedLines('speed-lines'),
  body('body'),
  shoulder('shoulder'),
  helmet('helmet'),
  wordmarkRider('wordmark-rider'),
  wordmarkOs('wordmark-os');

  const BrandLayer(this.svgId);

  final String svgId;

  /// The rider (emblem) without its built-in speed trails.
  static const rider = [body, shoulder, helmet];

  /// The emblem as drawn in the artwork: speed trails and rider, no wordmark.
  static const emblem = [speedLines, body, shoulder, helmet];
  static const wordmark = [wordmarkRider, wordmarkOs];
}

/// The RiderOS logo as Flutter paths, read from the SVG asset (the single source
/// of the artwork; the Android launcher icons are rendered from the same file).
class BrandLogo {
  BrandLogo._(this.paths)
    : riderBounds = _union(paths, BrandLayer.rider),
      speedLinesBounds = paths[BrandLayer.speedLines]!.getBounds(),
      wordmarkBounds = _union(paths, BrandLayer.wordmark),
      emblemBounds = _union(paths, BrandLayer.emblem);

  static const asset = 'assets/brand/rideros_logo.svg';

  /// The SVG `viewBox` (logo units).
  static const viewBox = Size(808, 600);

  final Map<BrandLayer, Path> paths;
  final Rect riderBounds;
  final Rect speedLinesBounds;
  final Rect wordmarkBounds;
  final Rect emblemBounds;

  /// Fill of one [layer] in [color]. As in the artwork, the speed trails and the
  /// back of the body fade in from the left (gradient in logo units).
  static Paint layerPaint(BrandLayer layer, Color color) {
    final paint = Paint()..color = color;
    final (double from, double to, double start)? fade = switch (layer) {
      BrandLayer.speedLines => (20, 160, 0),
      BrandLayer.body => (58, 200, 0.15),
      _ => null,
    };
    if (fade != null) {
      paint
        ..color =
            const Color(0xFF000000) // opaque: the gradient carries alpha
        ..shader = Gradient.linear(Offset(fade.$1, 0), Offset(fade.$2, 0), [
          color.withValues(alpha: color.a * fade.$3),
          color,
        ]);
    }
    return paint;
  }

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

  static Rect _union(Map<BrandLayer, Path> paths, List<BrandLayer> layers) =>
      layers
          .map((l) => paths[l]!.getBounds())
          .reduce((a, b) => a.expandToInclude(b));

  static Path _toPath(String d) {
    final path = Path()..fillType = PathFillType.evenOdd;
    writeSvgPathDataToPath(d, _PathWriter(path));
    return path;
  }
}

/// The emblem ([BrandLayer.emblem]) in [color], scaled to fit and centred.
class BrandEmblemPainter extends CustomPainter {
  BrandEmblemPainter(this.logo, this.color);

  final BrandLogo logo;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final b = logo.emblemBounds;
    final scale = (size.width / b.width) < (size.height / b.height)
        ? size.width / b.width
        : size.height / b.height;
    canvas
      ..save()
      ..translate(
        (size.width - b.width * scale) / 2,
        (size.height - b.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-b.left, -b.top);
    for (final layer in BrandLayer.emblem) {
      canvas.drawPath(logo.paths[layer]!, BrandLogo.layerPaint(layer, color));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandEmblemPainter old) =>
      old.logo != logo || old.color != color;
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
