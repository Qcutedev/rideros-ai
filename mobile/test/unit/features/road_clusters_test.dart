import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/features/road/domain/road_models.dart';
import 'package:rideros_ai/features/road/presentation/widgets/incident_clusters.dart';

import '../../helpers/road_fakes.dart';

void main() {
  // Screen positions by id, so the grouping can be checked without a map.
  List<List<String>> groups(Map<String, Offset> at, {double radius = 48}) {
    final incidents = [for (final id in at.keys) testIncident(id: id)];
    return [
      for (final g in clusterIncidents(
        incidents,
        (Incident i) => at[i.id]!,
        radius: radius,
      ))
        [for (final i in g) i.id],
    ];
  }

  test('no incidents, no groups', () {
    expect(groups({}), isEmpty);
  });

  test('markers that would overlap share a group; others stay alone', () {
    expect(
      groups({
        'a': const Offset(100, 100),
        'b': const Offset(130, 100), // 30 px from a
        'c': const Offset(300, 100),
        'd': const Offset(100, 148), // exactly the radius from a
      }),
      [
        ['a', 'b', 'd'],
        ['c'],
      ],
    );
  });

  test('distance is measured to the group anchor, not to its last member', () {
    // b joins a; c is 40 px from b but 80 px from a, so it starts a new group.
    expect(
      groups({
        'a': const Offset(0, 0),
        'b': const Offset(40, 0),
        'c': const Offset(80, 0),
      }),
      [
        ['a', 'b'],
        ['c'],
      ],
    );
  });

  test('the same input order gives the same groups', () {
    final at = {
      for (var i = 0; i < 20; i++) 'i$i': Offset(i * 13.0 % 97, i * 29.0 % 89),
    };
    expect(groups(at), groups(at));
  });
}
