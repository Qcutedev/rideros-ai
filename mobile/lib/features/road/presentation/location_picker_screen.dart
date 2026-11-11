import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/road_models.dart';
import 'widgets/road_map.dart';

/// `/road/pick-location`: move the map under a fixed centre pin, then pop the
/// centre. Works without location permission.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({this.initial, super.key});

  final RoadPoint? initial;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  late RoadPoint _center = widget.initial ?? defaultMapCenter;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roadPickLocationTitle)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: toLatLng(_center),
                    initialZoom: 17,
                    minZoom: 4,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (camera, _) =>
                        setState(() => _center = toRoadPoint(camera.center)),
                  ),
                  children: const [RoadBaseLayers(), OsmAttribution()],
                ),
                // The pin's tip marks the map centre.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: LocationPin(key: Key('picker.pin')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.roadPickLocationHelp,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_center.lat.toStringAsFixed(5)}, ${_center.lng.toStringAsFixed(5)}',
                    key: const Key('picker.coordinates'),
                    style: AppTypography.figures(theme.textTheme.bodySmall),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPrimaryButton(
                    key: const Key('picker.use'),
                    label: l10n.roadPickLocationUse,
                    onPressed: () => context.pop(_center),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
