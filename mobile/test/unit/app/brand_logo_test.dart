import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/intro/brand_logo.dart';

void main() {
  test('the logo asset has every animation layer inside its viewBox', () {
    final logo = BrandLogo.parse(File(BrandLogo.asset).readAsStringSync());
    final box = Offset.zero & BrandLogo.viewBox;
    for (final layer in BrandLayer.values) {
      final bounds = logo.paths[layer]!.getBounds();
      expect(bounds.isEmpty, isFalse, reason: layer.svgId);
      expect(box.contains(bounds.topLeft), isTrue, reason: layer.svgId);
      expect(box.contains(bounds.bottomRight), isTrue, reason: layer.svgId);
    }
    // The emblem sits above the wordmark.
    expect(logo.emblemBounds.bottom, lessThan(logo.wordmarkBounds.top));
  });

  test('a pen outline grows with its progress', () {
    final logo = BrandLogo.parse(File(BrandLogo.asset).readAsStringSync());
    final half = logo.outline(BrandLayer.body, 0.5).computeMetrics().toList();
    final full = logo.outline(BrandLayer.body, 1).computeMetrics().toList();
    double length(Iterable<PathMetric> ms) =>
        ms.fold(0, (sum, m) => sum + m.length);
    expect(length(half), closeTo(length(full) / 2, length(full) * 0.01));
  });

  test('a missing layer is a format error', () {
    expect(
      () => BrandLogo.parse('<svg><path id="body" d="M0 0L1 1Z"/></svg>'),
      throwsFormatException,
    );
  });
}
