import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/utils/clock.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/device_services.dart';
import '../domain/road_models.dart';
import 'road_labels.dart';
import 'road_providers.dart';
import 'widgets/road_map.dart';

/// `/road`: incidents on a map and the list of those near the rider, plus
/// "report an incident" and the rider's own reports.
class RoadScreen extends ConsumerStatefulWidget {
  const RoadScreen({super.key});

  @override
  ConsumerState<RoadScreen> createState() => _RoadScreenState();
}

class _RoadScreenState extends ConsumerState<RoadScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the settings app: ask for the position again. Only for the
    // problems fixed outside the app: the permission dialog also pauses and
    // resumes the app, so re-asking after a plain "denied" would pop the
    // dialog a second time. That case has its own "allow" button.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (ref.read(currentLocationProvider).value case LocationMissing(
          problem: LocationProblem.deniedForever ||
              LocationProblem.serviceDisabled,
        )) {
          ref.invalidate(currentLocationProvider);
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Own messenger: the "sent" SnackBar stays on this screen instead of
  /// following the user onto the incident detail opened from a marker.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  Future<void> _report() async {
    final l10n = AppLocalizations.of(context);
    final created = await context.push<ReportCreated>(Routes.roadReportNew);
    final messenger = _messenger.currentState;
    if (created == null || !mounted || messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            created.merged ? l10n.roadReportMerged : l10n.roadReportSent,
          ),
          action: SnackBarAction(
            key: const Key('road.viewReported'),
            label: l10n.roadReportView,
            onPressed: () => context.push(Routes.incident(created.incidentId)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: ScaffoldMessenger(
        key: _messenger,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.roadTitle),
            actions: [
              IconButton(
                key: const Key('road.myReports'),
                tooltip: l10n.roadMyReports,
                icon: const Icon(Icons.history_rounded),
                onPressed: () => context.push(Routes.roadMyReports),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(key: const Key('road.tabMap'), text: l10n.roadTabMap),
                Tab(key: const Key('road.tabNearby'), text: l10n.roadTabNearby),
              ],
            ),
          ),
          body: const TabBarView(
            // Horizontal drags belong to the map.
            physics: NeverScrollableScrollPhysics(),
            children: [_MapTab(), _NearbyTab()],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('road.report'),
            onPressed: _report,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text(l10n.roadReportAction),
          ),
        ),
      ),
    );
  }
}

// ---- map ----

class _MapTab extends ConsumerStatefulWidget {
  const _MapTab();

  @override
  ConsumerState<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<_MapTab>
    with AutomaticKeepAliveClientMixin {
  final _map = MapController();
  Timer? _debounce;
  RoadBounds? _bounds;
  IncidentList? _last;
  bool _ready = false;

  /// The rider moved the map: a late position fix must not pull it away.
  bool _userMoved = false;

  static const _boundsDelay = Duration(milliseconds: 400);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _map.dispose();
    super.dispose();
  }

  void _onReady() {
    _ready = true;
    if (ref.read(currentLocationProvider).value case LocationFound(:final point)
        when !_userMoved) {
      _map.move(toLatLng(point), defaultMapZoom);
    }
    _readBounds();
  }

  void _onMoved(MapCamera camera, bool hasGesture) {
    if (hasGesture) _userMoved = true;
    _debounce?.cancel();
    _debounce = Timer(_boundsDelay, _readBounds);
  }

  void _readBounds() {
    if (!mounted || !_ready) return;
    final b = _map.camera.visibleBounds;
    final next = RoadBounds(
      west: b.west,
      south: b.south,
      east: b.east,
      north: b.north,
    );
    if (next != _bounds) setState(() => _bounds = next);
  }

  void _goToMe() {
    _userMoved = false;
    switch (ref.read(currentLocationProvider).value) {
      case LocationFound(:final point):
        _map.move(toLatLng(point), defaultMapZoom);
      default:
        // Asks again; the listener below moves the map once a fix arrives.
        ref.invalidate(currentLocationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    ref.listen(currentLocationProvider, (_, next) {
      if (next.value case LocationFound(:final point)
          when _ready && !_userMoved) {
        _map.move(toLatLng(point), defaultMapZoom);
      }
    });
    final me = switch (ref.watch(currentLocationProvider).value) {
      LocationFound(:final point) => point,
      _ => null,
    };

    final bounds = _bounds;
    final tooLarge = bounds?.tooLarge ?? false;
    final result = bounds == null || tooLarge
        ? null
        : ref.watch(incidentsInBoundsProvider(bounds));
    if (result?.value case final value?) _last = value;
    // Zoomed out too far: show nothing rather than a misleading part.
    final shown = tooLarge ? null : (result?.value ?? _last);

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: toLatLng(me ?? defaultMapCenter),
            initialZoom: defaultMapZoom,
            minZoom: 4,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: _onReady,
            onPositionChanged: _onMoved,
          ),
          children: [
            const RoadBaseLayers(),
            MarkerLayer(
              markers: [
                if (me != null)
                  Marker(
                    point: toLatLng(me),
                    width: 22,
                    height: 22,
                    child: const MyLocationDot(key: Key('road.me')),
                  ),
                for (final incident in shown?.items ?? const <Incident>[])
                  Marker(
                    point: toLatLng(incident.location),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      key: Key('marker.${incident.id}'),
                      onTap: () => context.push(Routes.incident(incident.id)),
                      child: IncidentMarkerIcon(incident: incident),
                    ),
                  ),
              ],
            ),
            const OsmAttribution(),
          ],
        ),
        if (result?.isLoading ?? false)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(key: Key('road.mapLoading')),
          ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          right: AppSpacing.md + 48 + AppSpacing.sm,
          child: _MapStatus(
            tooLarge: tooLarge,
            result: result,
            shown: shown,
            onRetry: bounds == null
                ? null
                : () => ref.invalidate(incidentsInBoundsProvider(bounds)),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          right: AppSpacing.md,
          child: FloatingActionButton.small(
            key: const Key('road.goToMe'),
            heroTag: null,
            tooltip: l10n.roadMapMyLocation,
            onPressed: _goToMe,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
}

/// One line over the map: zoom in / error / truncated / incident count.
class _MapStatus extends StatelessWidget {
  const _MapStatus({
    required this.tooLarge,
    required this.result,
    required this.shown,
    required this.onRetry,
  });

  final bool tooLarge;
  final AsyncValue<IncidentList>? result;
  final IncidentList? shown;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (String text, bool warn, bool retry) = switch (result) {
      _ when tooLarge => (l10n.roadMapZoomIn, true, false),
      AsyncError(:final error) => (
        '${l10n.roadMapLoadFailed} · ${failureMessage(l10n, error is AppFailure ? error : UnknownFailure(error))}',
        true,
        true,
      ),
      _ when shown?.truncated ?? false => (l10n.roadMapTruncated, true, false),
      _ when shown != null => (
        l10n.roadMapIncidentCount(shown!.items.length),
        false,
        false,
      ),
      _ => ('', false, false),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        key: const Key('road.mapStatus'),
        color: warn
            ? context.semanticColors.warningContainer
            : theme.colorScheme.surface,
        elevation: 2,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: warn ? context.semanticColors.warning : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (retry && onRetry != null)
                TextButton(
                  key: const Key('road.mapRetry'),
                  onPressed: onRetry,
                  child: Text(l10n.commonRetry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- nearby ----

class _NearbyTab extends ConsumerWidget {
  const _NearbyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final location = ref.watch(currentLocationProvider);
    return switch (location) {
      AsyncData(value: LocationFound(:final point)) => _NearbyList(
        point: point,
      ),
      AsyncData(value: LocationMissing(:final problem)) => LocationProblemView(
        problem: problem,
      ),
      AsyncError() => const LocationProblemView(
        problem: LocationProblem.unavailable,
      ),
      _ => LoadingView(message: l10n.roadLocationFinding),
    };
  }
}

/// Why the position is unknown and the one action that can fix it.
class LocationProblemView extends ConsumerWidget {
  const LocationProblemView({required this.problem, super.key});

  final LocationProblem problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final service = ref.read(locationServiceProvider);
    void askAgain() => ref.invalidate(currentLocationProvider);
    final (
      String title,
      String message,
      String action,
      VoidCallback onAction,
    ) = switch (problem) {
      LocationProblem.denied => (
        l10n.roadLocationDeniedTitle,
        l10n.roadLocationDeniedMessage,
        l10n.roadLocationAllow,
        askAgain,
      ),
      LocationProblem.deniedForever => (
        l10n.roadLocationDeniedTitle,
        l10n.roadLocationDeniedForeverMessage,
        l10n.roadLocationOpenSettings,
        service.openAppSettings,
      ),
      LocationProblem.serviceDisabled => (
        l10n.roadLocationServiceOffTitle,
        l10n.roadLocationServiceOffMessage,
        l10n.roadLocationOpenSettings,
        service.openLocationSettings,
      ),
      LocationProblem.unavailable => (
        l10n.roadLocationUnavailableTitle,
        l10n.roadLocationUnavailableMessage,
        l10n.commonRetry,
        askAgain,
      ),
    };
    return StatusView(
      key: Key('road.location.${problem.name}'),
      icon: Icons.location_off_outlined,
      title: title,
      message: message,
      actionLabel: action,
      onAction: onAction,
    );
  }
}

class _NearbyList extends ConsumerWidget {
  const _NearbyList({required this.point});

  final RoadPoint point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = ref.watch(clockProvider)();
    final km = RoadLimits.nearbyRadiusM ~/ 1000;
    final provider = nearbyIncidentsProvider(point);
    return AsyncValueView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      loading: const Padding(padding: AppSpacing.screen, child: ListSkeleton()),
      isEmpty: (list) => list.items.isEmpty,
      empty: StatusView(
        key: const Key('road.nearbyEmpty'),
        icon: Icons.check_circle_outline_rounded,
        title: l10n.roadNearbyEmptyTitle,
        message: '${l10n.roadNearbyEmptyMessage(km)}\n\n${l10n.roadNotice}',
      ),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: ListView(
          key: const Key('road.nearbyList'),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.roadNearbyHeader(km),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const RoadNotice(),
                  if (list.truncated) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppBanner(
                      message: l10n.roadMapTruncated,
                      tone: BannerTone.warning,
                    ),
                  ],
                ],
              ),
            ),
            for (final (i, incident) in list.items.indexed) ...[
              if (i > 0) const Divider(height: 1),
              IncidentRow(incident: incident, now: now),
            ],
          ],
        ),
      ),
    );
  }
}
