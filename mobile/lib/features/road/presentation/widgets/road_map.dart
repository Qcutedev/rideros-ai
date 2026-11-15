import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/road_models.dart';
import '../road_labels.dart';

/// Map tiles come from the network. Widget tests turn them off (no HTTP there).
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// Where the map opens when the rider's position is unknown (Bangkok).
const defaultMapCenter = RoadPoint(lat: 13.7563, lng: 100.5018);
const defaultMapZoom = 14.0;

/// OpenStreetMap standard tiles (Phase 7, HANDOFF §4.15 decision 7). The OSM
/// tile policy allows light use like this when the app identifies itself
/// (flutter_map sends `flutter_map (<package>)` as User-Agent), shows the
/// attribution, caches tiles (flutter_map's built-in cache) and does not
/// bulk-download. Heavier use needs another provider.
const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const mapUserAgentPackage = 'com.rideros.rideros_ai';

LatLng toLatLng(RoadPoint p) => LatLng(p.lat, p.lng);
RoadPoint toRoadPoint(LatLng p) => RoadPoint(lat: p.latitude, lng: p.longitude);

/// Tiles (when enabled). In dark mode the same OSM tiles are colour-inverted
/// on the device (flutter_map's [darkModeTileBuilder]): no dark tile
/// service was free to use (CARTO's hosted basemaps are for enterprise
/// customers only).
class RoadBaseLayers extends ConsumerWidget {
  const RoadBaseLayers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mapTilesEnabledProvider)) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: osmTileUrl,
      userAgentPackageName: mapUserAgentPackage,
      maxNativeZoom: 19,
      tileBuilder: dark ? darkModeTileBuilder : null,
    );
  }
}

/// "© OpenStreetMap contributors" in the bottom-left corner (the OSM licence
/// asks for it on every map). One line that shrinks instead of overflowing.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  static const text = '© OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.black87,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// Round category marker. Open incidents reported by several riders get a
/// filled ring; the shape never carries meaning alone (the detail says it).
class IncidentMarkerIcon extends StatelessWidget {
  const IncidentMarkerIcon({required this.incident, super.key});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strong = incident.status == IncidentStatus.corroborated;
    return Semantics(
      button: true,
      label: categoryLabel(AppLocalizations.of(context), incident.category),
      child: Container(
        decoration: BoxDecoration(
          color: strong ? scheme.error : scheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.error, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x33000000))],
        ),
        alignment: Alignment.center,
        child: Icon(
          categoryIcon(incident.category),
          size: 20,
          color: strong ? scheme.onError : scheme.error,
        ),
      ),
    );
  }
}

/// The rider's own position: a blue dot.
class MyLocationDot extends StatelessWidget {
  const MyLocationDot({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A73E8),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(blurRadius: 4, color: Color(0x33000000))],
    ),
  );
}

/// A pin whose tip sits on the point (place it with `alignment: topCenter`).
class LocationPin extends StatelessWidget {
  const LocationPin({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.location_on,
    size: size,
    color: Theme.of(context).colorScheme.error,
    shadows: const [Shadow(blurRadius: 4, color: Color(0x55000000))],
  );
}

/// A small map that cannot be moved, with a pin on [point].
class StaticPinMap extends StatelessWidget {
  const StaticPinMap({
    required this.point,
    this.height = 180,
    this.zoom = 16,
    super.key,
  });

  final RoadPoint point;
  final double height;
  final double zoom;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      child: FlutterMap(
        // A new point recreates the map so it re-centres.
        key: ValueKey(point),
        options: MapOptions(
          initialCenter: toLatLng(point),
          initialZoom: zoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          const RoadBaseLayers(),
          MarkerLayer(
            markers: [
              Marker(
                point: toLatLng(point),
                width: 44,
                height: 44,
                alignment: Alignment.topCenter,
                child: const LocationPin(),
              ),
            ],
          ),
          const OsmAttribution(),
        ],
      ),
    ),
  );
}
