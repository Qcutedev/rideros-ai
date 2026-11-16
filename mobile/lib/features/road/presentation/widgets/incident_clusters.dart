import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/road_models.dart';
import '../road_labels.dart';
import 'road_map.dart';

/// Groups incidents whose markers would overlap on screen (Phase 7).
///
/// Greedy and order-stable: each incident joins the first group whose anchor
/// (its first incident) lies within [radius] pixels, else it starts a group.
/// [project] maps an incident to screen pixels at the current zoom.
List<List<Incident>> clusterIncidents(
  List<Incident> incidents,
  Offset Function(Incident) project, {
  double radius = IncidentClusterLayer.radius,
}) {
  final anchors = <Offset>[];
  final groups = <List<Incident>>[];
  for (final incident in incidents) {
    final p = project(incident);
    var joined = false;
    for (var g = 0; g < groups.length; g++) {
      if ((anchors[g] - p).distance <= radius) {
        groups[g].add(incident);
        joined = true;
        break;
      }
    }
    if (!joined) {
      anchors.add(p);
      groups.add([incident]);
    }
  }
  return groups;
}

/// The incident markers of the map, clustered. Must sit inside a
/// [FlutterMap]: it re-groups whenever the camera moves.
///
/// One incident: the category marker (`marker.<id>`). Several: a count bubble
/// (`cluster.<first id>`). Tapping a bubble zooms in to its incidents; when
/// they share one spot, or the map is already at full zoom, it lists them
/// instead, so every incident can be opened (P5b known issue).
class IncidentClusterLayer extends StatelessWidget {
  const IncidentClusterLayer({
    required this.incidents,
    required this.onOpen,
    super.key,
  });

  final List<Incident> incidents;
  final ValueChanged<String> onOpen;

  /// Markers are 40 px wide; closer than this they overlap.
  static const radius = 48.0;

  /// Incidents closer together than this count as one spot.
  static const sameSpotMeters = 25.0;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final groups = clusterIncidents(
      incidents,
      (i) => camera.projectAtZoom(toLatLng(i.location)),
    );
    return MarkerLayer(
      markers: [
        for (final group in groups)
          if (group.length == 1)
            Marker(
              point: toLatLng(group.single.location),
              width: 40,
              height: 40,
              child: GestureDetector(
                key: Key('marker.${group.single.id}'),
                onTap: () => onOpen(group.single.id),
                child: IncidentMarkerIcon(incident: group.single),
              ),
            )
          else
            Marker(
              point: _center(group),
              width: 44,
              height: 44,
              child: GestureDetector(
                key: Key('cluster.${group.first.id}'),
                onTap: () => _onClusterTap(context, camera, group),
                child: ClusterMarkerIcon(count: group.length),
              ),
            ),
      ],
    );
  }

  static LatLng _center(List<Incident> group) {
    var lat = 0.0, lng = 0.0;
    for (final i in group) {
      lat += i.location.lat;
      lng += i.location.lng;
    }
    return LatLng(lat / group.length, lng / group.length);
  }

  void _onClusterTap(
    BuildContext context,
    MapCamera camera,
    List<Incident> group,
  ) {
    final points = [for (final i in group) toLatLng(i.location)];
    const distance = Distance();
    final spread = points
        .map((p) => distance.as(LengthUnit.Meter, points.first, p))
        .reduce((a, b) => a > b ? a : b);
    if (spread <= sameSpotMeters ||
        camera.zoom >= (camera.maxZoom ?? 19) - 0.5) {
      _showList(context, group);
      return;
    }
    MapController.of(context).fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(72),
        maxZoom: 18,
      ),
    );
  }

  void _showList(BuildContext context, List<Incident> group) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          key: const Key('road.clusterSheet'),
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.roadClusterSheetTitle(group.length),
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
            ),
            for (final incident in group)
              ListTile(
                key: Key('clusterItem.${incident.id}'),
                leading: Icon(categoryIcon(incident.category)),
                title: Text(categoryLabel(l10n, incident.category)),
                subtitle: Text(statusLabel(l10n, incident.status)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(sheet).pop();
                  onOpen(incident.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A round bubble with the number of incidents it stands for.
class ClusterMarkerIcon extends StatelessWidget {
  const ClusterMarkerIcon({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).roadClusterLabel(count),
      excludeSemantics: true,
      child: Container(
        // Obsidian with a lime count: groups read apart from the red markers.
        decoration: BoxDecoration(
          color: AppColors.obsidian,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lime, width: 2.5),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Color(0x40000000))],
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.lime, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
