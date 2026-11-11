import 'dart:io';

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
    // The rider and its trails sit above the wordmark; the trails trail it.
    expect(logo.riderBounds.bottom, lessThan(logo.wordmarkBounds.top));
    expect(logo.speedLinesBounds.left, lessThan(logo.riderBounds.left));
    // The emblem (login, splash) is the trails plus the rider, no wordmark.
    expect(
      logo.emblemBounds,
      logo.speedLinesBounds.expandToInclude(logo.riderBounds),
    );
  });

  test('a missing layer is a format error', () {
    expect(
      () => BrandLogo.parse('<svg><path id="body" d="M0 0L1 1Z"/></svg>'),
      throwsFormatException,
    );
  });
}
