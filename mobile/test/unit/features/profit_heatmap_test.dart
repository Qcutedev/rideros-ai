import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/features/profit/domain/profit_heatmap.dart';

import '../../helpers/profit_fakes.dart';

void main() {
  group('HeatScale', () {
    test('five equal-width levels between the lowest and highest profit', () {
      final scale = HeatScale([
        heatCell(0, 0, netPerHour: '100.00'),
        heatCell(0, 1, netPerHour: '200.00'),
        heatCell(0, 2, netPerHour: '-10.00'),
        heatCell(0, 3, netPerHour: null),
      ]);
      expect((scale.min, scale.max), (d('100.00'), d('200.00')));
      expect(scale.levelOf(d('100.00')), 1);
      expect(scale.levelOf(d('119.99')), 1);
      expect(scale.levelOf(d('120.00')), 2);
      expect(scale.levelOf(d('150.00')), 3);
      expect(scale.levelOf(d('199.99')), 5);
      expect(scale.levelOf(d('200.00')), 5);
    });

    test('loss and break-even are level 0', () {
      final scale = HeatScale([heatCell(0, 0, netPerHour: '80.00')]);
      expect(scale.levelOf(d('0')), 0);
      expect(scale.levelOf(d('-0.01')), 0);
    });

    test('a single positive value is the top level', () {
      final scale = HeatScale([
        heatCell(0, 0, netPerHour: '80.00'),
        heatCell(1, 0, netPerHour: '80.00'),
      ]);
      expect(scale.levelOf(d('80.00')), HeatScale.levels);
    });

    test('no positive estimate: no range', () {
      final scale = HeatScale([
        heatCell(0, 0, netPerHour: '-5.00'),
        heatCell(0, 1, netPerHour: null),
      ]);
      expect((scale.min, scale.max), (null, null));
      expect(scale.levelOf(d('10.00')), HeatScale.levels);
    });
  });

  group('ProfitHeatmap', () {
    test('best: positive estimates only, highest first, ties by order', () {
      final map = profitHeatmap(
        status: HeatmapStatus.ok,
        sessions: 20,
        cells: [
          heatCell(0, 9, netPerHour: '150.00'),
          heatCell(1, 9, netPerHour: '210.00'),
          heatCell(2, 9, netPerHour: null),
          heatCell(3, 9, netPerHour: '150.00'),
          heatCell(4, 9, netPerHour: '-20.00'),
          heatCell(5, 9, netPerHour: '90.00'),
        ],
      );
      expect(
        [for (final c in map.best()) (c.weekday, c.slot)],
        [(1, 9), (0, 9), (3, 9)],
      );
      expect(map.best(1).single.weekday, 1);
    });

    test('sessionsMissing and cellAt', () {
      final map = profitHeatmap(sessions: 7, cells: [heatCell(6, 11)]);
      expect(map.sessionsMissing, 3);
      expect(map.slotsPerDay, 12);
      expect(map.cellAt(6, 11)?.sessionCount, 3);
      expect(map.cellAt(0, 0), isNull);
      expect(profitHeatmap(sessions: 12).sessionsMissing, 0);
    });

    test('status codes', () {
      expect(HeatmapStatus.fromJson('ok'), HeatmapStatus.ok);
      expect(
        HeatmapStatus.fromJson('insufficient_data'),
        HeatmapStatus.insufficientData,
      );
      expect(() => HeatmapStatus.fromJson('x'), throwsFormatException);
    });
  });
}
