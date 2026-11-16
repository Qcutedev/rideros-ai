import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/app/intro/brand_logo.dart';
import 'package:rideros_ai/app/theme/tokens.dart';
import 'package:rideros_ai/core/widgets/form_layout.dart';

import '../helpers/file_bundle.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool onDark}) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: FileAssetBundle(),
        child: MaterialApp(
          home: Center(child: AppLogoMark(size: 64, onDark: onDark)),
        ),
      ),
    );
    await tester.pump();
  }

  BrandEmblemPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<BrandEmblemPainter>()
      .single;

  testWidgets('on the green header: the ivory emblem, no tile', (tester) async {
    await pump(tester, onDark: true);
    expect(painter(tester).color, AppColors.logoIvory);
    final box = tester.getSize(
      find.descendant(
        of: find.byType(AppLogoMark),
        matching: find.byType(SizedBox),
      ),
    );
    expect(box, const Size(96, 64));
    expect(
      find.descendant(
        of: find.byType(AppLogoMark),
        matching: find.byType(Container),
      ),
      findsNothing,
    );
  });

  testWidgets('elsewhere: the emblem on a rounded Obsidian tile', (
    tester,
  ) async {
    await pump(tester, onDark: false);
    expect(painter(tester).color, AppColors.logoIvory);
    final tile = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppLogoMark),
        matching: find.byType(Container),
      ),
    );
    expect((tile.decoration! as BoxDecoration).color, AppColors.obsidian);
  });
}
