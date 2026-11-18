import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideros_ai/app/routes.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/widgets/status_views.dart';
import 'package:rideros_ai/features/dashboard/presentation/home_screen.dart';
import 'package:rideros_ai/features/road/data/device_services.dart';
import 'package:rideros_ai/features/road/domain/road_models.dart';
import 'package:rideros_ai/features/road/presentation/incident_detail_screen.dart';
import 'package:rideros_ai/features/road/presentation/location_picker_screen.dart';
import 'package:rideros_ai/features/road/presentation/my_reports_screen.dart';
import 'package:rideros_ai/features/road/presentation/report_form_screen.dart';
import 'package:rideros_ai/features/road/presentation/road_providers.dart';
import 'package:rideros_ai/features/road/presentation/road_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';
import '../helpers/road_fakes.dart';

void main() {
  late RoadFakes road;

  setUp(() => road = RoadFakes());

  List<Override> overrides() =>
      fakeRepositories(FakeAuthRepository(), null, null, null, null, road);

  /// Lets the map's bounds debounce fire and the incidents load.
  Future<void> settleMap(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  /// Never "verified" anywhere (decision 10, §4.11).
  /// Taps a button over the map. Not `tapKey`: its `ensureVisible` would
  /// scroll the tab view that holds the map.
  Future<void> tapOnMap(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  void expectNeverVerified() =>
      expect(find.textContaining('ยืนยันแล้ว'), findsNothing);

  testWidgets('home card opens RoadContext without asking for location', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      path: Routes.home,
      screen: const HomeScreen(),
      overrides: overrides(),
    );
    await scrollIntoView(tester, find.byKey(const Key('home.road')));
    expect(find.text(t.homeRoadTitle), findsOneWidget);
    await tapKey(tester, 'home.road');
    expect(find.text('route:${Routes.road}'), findsOneWidget);
    expect(road.location.calls, 0);
  });

  group('map', () {
    Future<GoRouter> open(WidgetTester tester) async {
      final router = await pumpScreen(
        tester,
        path: Routes.road,
        screen: const RoadScreen(),
        overrides: overrides(),
      );
      await settleMap(tester);
      return router;
    }

    testWidgets('incidents in view as markers; the rider as a dot', (
      tester,
    ) async {
      road.repo.incidents.add(
        testIncident(
          id: 'i-2',
          category: 'road_damage',
          status: 'corroborated',
          lat: 13.7663, // ~1.1 km north: apart on screen, so not clustered
        ),
      );
      await open(tester);
      final bounds = road.repo.lastBounds!;
      expect(bounds.tooLarge, isFalse);
      expect(bounds.west, lessThan(testPoint.lng));
      expect(bounds.east, greaterThan(testPoint.lng));
      expect(bounds.south, lessThan(testPoint.lat));
      expect(bounds.north, greaterThan(testPoint.lat));
      expect(find.byKey(const Key('marker.i-1')), findsOneWidget);
      expect(find.byKey(const Key('marker.i-2')), findsOneWidget);
      expect(find.byKey(const Key('road.me')), findsOneWidget);
      expect(find.text(t.roadMapIncidentCount(2)), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      expectNeverVerified();
    });

    testWidgets('a marker opens its incident', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('marker.i-1')));
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.incident('i-1')}'), findsOneWidget);
    });

    testWidgets('truncated answer asks to zoom in', (tester) async {
      road.repo.truncated = true;
      await open(tester);
      expect(find.text(t.roadMapTruncated), findsOneWidget);
    });

    testWidgets('load error: message and retry', (tester) async {
      road.repo.listError = const NetworkFailure();
      await open(tester);
      expect(find.textContaining(t.roadMapLoadFailed), findsOneWidget);
      road.repo.listError = null;
      await tapOnMap(tester, 'road.mapRetry');
      expect(find.byKey(const Key('marker.i-1')), findsOneWidget);
      expect(road.repo.calls.where((c) => c == 'bbox'), hasLength(2));
    });

    testWidgets('without location the map still loads; go-to-me asks again', (
      tester,
    ) async {
      road.location.result = const LocationMissing(LocationProblem.denied);
      await open(tester);
      expect(find.byKey(const Key('marker.i-1')), findsOneWidget);
      expect(find.byKey(const Key('road.me')), findsNothing);
      road.location.result = const LocationFound(testPoint);
      await tapOnMap(tester, 'road.goToMe');
      await settleMap(tester);
      expect(road.location.calls, 2);
      expect(find.byKey(const Key('road.me')), findsOneWidget);
    });

    testWidgets('report: snackbar from the result, "view" opens it', (
      tester,
    ) async {
      final router = await open(tester);
      await tapKey(tester, 'road.report');
      expect(find.text('route:${Routes.roadReportNew}'), findsOneWidget);
      router.pop(
        ReportCreated(
          reportId: 'rep-9',
          incidentId: 'i-9',
          merged: true,
          status: IncidentStatus.corroborated,
          incident: testIncident(id: 'i-9'),
        ),
      );
      await settleMap(tester);
      expect(find.text(t.roadReportMerged), findsOneWidget);
      await tester.tap(find.byKey(const Key('road.viewReported')));
      await tester.pumpAndSettle();
      expect(find.text('route:${Routes.incident('i-9')}'), findsOneWidget);
    });

    testWidgets('my reports button', (tester) async {
      await open(tester);
      await tapKey(tester, 'road.myReports');
      expect(find.text('route:${Routes.roadMyReports}'), findsOneWidget);
    });

    group('clusters', () {
      testWidgets('incidents on one spot: a count bubble that lists them', (
        tester,
      ) async {
        // i-1 (flooding) and i-2 (accident) at the same point: before Phase 7
        // only the top marker could be tapped.
        road.repo.incidents.add(
          testIncident(id: 'i-2', category: 'traffic_incident'),
        );
        await open(tester);
        expect(find.byKey(const Key('marker.i-1')), findsNothing);
        expect(find.byKey(const Key('cluster.i-1')), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.bySemanticsLabel(t.roadClusterLabel(2)), findsOneWidget);

        await tester.tap(find.byKey(const Key('cluster.i-1')));
        await tester.pumpAndSettle();
        expect(find.text(t.roadClusterSheetTitle(2)), findsOneWidget);
        expect(find.byKey(const Key('clusterItem.i-1')), findsOneWidget);
        expect(find.text(t.roadCategoryTrafficIncident), findsOneWidget);

        await tester.tap(find.byKey(const Key('clusterItem.i-2')));
        await tester.pumpAndSettle();
        expect(find.text('route:${Routes.incident('i-2')}'), findsOneWidget);
      });

      testWidgets('nearby incidents: tapping the bubble zooms in to them', (
        tester,
      ) async {
        // ~150 m apart: about 16 px at the opening zoom (14), so one bubble.
        road.repo.incidents.add(testIncident(id: 'i-2', lat: 13.7577));
        await open(tester);
        expect(find.byKey(const Key('cluster.i-1')), findsOneWidget);

        await tester.tap(find.byKey(const Key('cluster.i-1')));
        await settleMap(tester);
        expect(find.byKey(const Key('road.clusterSheet')), findsNothing);
        expect(find.byKey(const Key('cluster.i-1')), findsNothing);
        expect(find.byKey(const Key('marker.i-1')), findsOneWidget);
        expect(find.byKey(const Key('marker.i-2')), findsOneWidget);
      });
    });
  });

  group('nearby', () {
    Future<void> open(WidgetTester tester) async {
      await pumpScreen(
        tester,
        path: Routes.road,
        screen: const RoadScreen(),
        overrides: overrides(),
      );
      await settleMap(tester);
      await tapKey(tester, 'road.tabNearby');
    }

    testWidgets('closest first with distance, status and notice', (
      tester,
    ) async {
      road.repo.incidents
        ..clear()
        ..addAll([
          testIncident(distance: 348),
          testIncident(
            id: 'i-2',
            category: 'road_closure',
            status: 'corroborated',
            distance: 1260,
            reporters: 3,
          ),
        ]);
      await open(tester);
      expect(
        road.repo.calls,
        contains('nearby:${testPoint.lat},${testPoint.lng}:2000'),
      );
      expect(find.text(t.roadNearbyHeader(2)), findsOneWidget);
      expect(find.byKey(const Key('road.notice')), findsOneWidget);
      expect(find.text('350 ม.'), findsOneWidget);
      expect(find.text('1.3 กม.'), findsOneWidget);
      expect(find.text(t.roadStatusUnverified), findsOneWidget);
      expect(find.text(t.roadStatusCorroborated), findsOneWidget);
      expect(
        find.text(t.roadReportedByUsers(t.roadAgoMinutes(5))),
        findsNWidgets(2),
      );
      expectNeverVerified();
      await tapKey(tester, 'incident.i-2');
      expect(find.text('route:${Routes.incident('i-2')}'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      road.repo.incidents.clear();
      await open(tester);
      expect(find.byKey(const Key('road.nearbyEmpty')), findsOneWidget);
      expect(find.textContaining(t.roadNearbyEmptyMessage(2)), findsOneWidget);
    });

    testWidgets('error with retry', (tester) async {
      road.repo.listError = const NetworkFailure();
      await open(tester);
      expect(find.text(t.failureNetwork), findsOneWidget);
    });

    testWidgets('denied: "allow" asks again', (tester) async {
      road.location.result = const LocationMissing(LocationProblem.denied);
      await open(tester);
      expect(find.byKey(const Key('road.location.denied')), findsOneWidget);
      expect(find.text(t.roadLocationDeniedMessage), findsOneWidget);
      road.location.result = const LocationFound(testPoint);
      await tester.tap(find.text(t.roadLocationAllow));
      await tester.pumpAndSettle();
      expect(road.location.calls, 2);
      expect(find.byKey(const Key('incident.i-1')), findsOneWidget);
    });

    Future<void> pauseAndResume(WidgetTester tester) async {
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }

    testWidgets('denied: resuming does not ask a second time', (tester) async {
      // The permission dialog itself pauses and resumes the app.
      road.location.result = const LocationMissing(LocationProblem.denied);
      await open(tester);
      expect(road.location.calls, 1);
      await pauseAndResume(tester);
      expect(road.location.calls, 1);
      expect(find.byKey(const Key('road.location.denied')), findsOneWidget);
    });

    testWidgets('denied forever: back from settings checks again', (
      tester,
    ) async {
      road.location.result = const LocationMissing(
        LocationProblem.deniedForever,
      );
      await open(tester);
      road.location.result = const LocationFound(testPoint);
      await pauseAndResume(tester);
      expect(road.location.calls, 2);
      expect(find.byKey(const Key('incident.i-1')), findsOneWidget);
    });

    testWidgets('denied forever opens the app settings', (tester) async {
      road.location.result = const LocationMissing(
        LocationProblem.deniedForever,
      );
      await open(tester);
      expect(find.text(t.roadLocationDeniedForeverMessage), findsOneWidget);
      await tester.tap(find.text(t.roadLocationOpenSettings));
      await tester.pump();
      expect(road.location.appSettings, 1);
    });

    testWidgets('location off opens the location settings', (tester) async {
      road.location.result = const LocationMissing(
        LocationProblem.serviceDisabled,
      );
      await open(tester);
      expect(find.text(t.roadLocationServiceOffTitle), findsOneWidget);
      await tester.tap(find.text(t.roadLocationOpenSettings));
      await tester.pump();
      expect(road.location.locationSettings, 1);
    });
  });

  group('report form', () {
    Future<GoRouter> open(WidgetTester tester) => pushScreen(
      tester,
      pattern: Routes.roadReportNew,
      location: Routes.roadReportNew,
      screen: const ReportFormScreen(),
      overrides: overrides(),
    );

    testWidgets('category is required; nothing is sent', (tester) async {
      await open(tester);
      await tapKey(tester, 'reportForm.submit');
      expect(find.text(t.roadReportCategoryRequired), findsOneWidget);
      expect(road.repo.calls, isEmpty);
    });

    testWidgets('GPS location, photo and description are sent; pops', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('reportForm.map')), findsOneWidget);
      expect(
        find.text('${t.roadReportLocationGps} · 13.75630, 100.50180'),
        findsOneWidget,
      );
      await tapKey(tester, 'reportForm.category.flooding');
      await tapKey(tester, 'reportForm.gallery');
      expect(road.photos.sources, [PhotoSource.gallery]);
      expect(find.byKey(const Key('reportForm.photo')), findsOneWidget);
      await enter(tester, 'reportForm.description', '  น้ำท่วมถึงเข่า  ');
      await tapKey(tester, 'reportForm.submit');
      final sent = road.repo.lastReport!;
      expect(sent.category, RoadCategory.flooding);
      expect(sent.location, testPoint);
      expect(sent.description, 'น้ำท่วมถึงเข่า');
      expect(sent.photo!.name, 'flood.jpg');
      expect(find.text('route:${Routes.home}'), findsOneWidget);
    });

    testWidgets('photo can be removed; picker failure and size are shown', (
      tester,
    ) async {
      await open(tester);
      await tapKey(tester, 'reportForm.camera');
      expect(road.photos.sources, [PhotoSource.camera]);
      await tapKey(tester, 'reportForm.removePhoto');
      expect(find.byKey(const Key('reportForm.photo')), findsNothing);

      road.photos.error = const PhotoPickFailure('camera_access_denied');
      await tapKey(tester, 'reportForm.camera');
      expect(find.text(t.roadReportPhotoFailed), findsOneWidget);

      road.photos
        ..error = null
        ..next = ReportPhoto(
          bytes: Uint8List(RoadLimits.maxImageBytes + 1),
          name: 'big.jpg',
        );
      await tapKey(tester, 'reportForm.gallery');
      expect(find.text(t.roadReportPhotoTooLarge), findsOneWidget);
      expect(find.byKey(const Key('reportForm.photo')), findsNothing);
    });

    testWidgets('without location: pin on the map first', (tester) async {
      road.location.result = const LocationMissing(LocationProblem.denied);
      final router = await open(tester);
      expect(find.byKey(const Key('reportForm.noGps')), findsOneWidget);
      await tapKey(tester, 'reportForm.category.road_damage');
      await tapKey(tester, 'reportForm.submit');
      expect(find.byKey(const Key('reportForm.locationError')), findsOneWidget);
      expect(road.repo.calls, isEmpty);

      await tapKey(tester, 'reportForm.chooseLocation');
      expect(find.text('route:${Routes.roadPickLocation}'), findsOneWidget);
      router.pop(const RoadPoint(lat: 13.7, lng: 100.6));
      await tester.pumpAndSettle();
      expect(
        find.text('${t.roadReportLocationManual} · 13.70000, 100.60000'),
        findsOneWidget,
      );
      await tapKey(tester, 'reportForm.submit');
      expect(
        road.repo.lastReport!.location,
        const RoadPoint(lat: 13.7, lng: 100.6),
      );
      expect(road.repo.lastReport!.photo, isNull);
      expect(road.repo.lastReport!.description, isNull);
    });

    testWidgets('already reported: opens that incident instead', (
      tester,
    ) async {
      road.repo.createError = const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.alreadyReported,
        details: [
          {'incident_id': 'i-7'},
        ],
      );
      await open(tester);
      await tapKey(tester, 'reportForm.category.flooding');
      await tapKey(tester, 'reportForm.submit');
      expect(find.text(t.roadAlreadyReported), findsOneWidget);
      await tapKey(tester, 'reportForm.openIncident');
      expect(find.text('route:${Routes.incident('i-7')}'), findsOneWidget);
    });

    testWidgets('server refuses the photo: says why, form stays', (
      tester,
    ) async {
      road.repo.createError = const ApiFailure(
        statusCode: 415,
        code: ApiErrorCode.unsupportedImage,
      );
      await open(tester);
      await tapKey(tester, 'reportForm.category.flooding');
      await tapKey(tester, 'reportForm.submit');
      expect(find.text(t.failureUnsupportedImage), findsOneWidget);
      expect(find.byKey(const Key('reportForm.submit')), findsOneWidget);
    });

    testWidgets('sending twice is not possible', (tester) async {
      road.repo.createGate = Completer<void>();
      await open(tester);
      await tapKey(tester, 'reportForm.category.flooding');
      await tapKey(tester, 'reportForm.submit', settle: false);
      await tapKey(tester, 'reportForm.submit', settle: false);
      expect(road.repo.calls, ['create']);
      road.repo.createGate!.complete();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('location picker pops the map centre', (tester) async {
    final router = await pumpScreen(
      tester,
      path: Routes.roadPickLocation,
      screen: const LocationPickerScreen(initial: testPoint),
      overrides: overrides(),
      initialLocation: Routes.home,
    );
    final result = router.push<RoadPoint>(Routes.roadPickLocation);
    await tester.pumpAndSettle();
    expect(find.text('13.75630, 100.50180'), findsOneWidget);
    expect(find.byKey(const Key('picker.pin')), findsOneWidget);
    await tapKey(tester, 'picker.use');
    final picked = await result;
    expect(picked!.lat, closeTo(testPoint.lat, 1e-9));
    expect(picked.lng, closeTo(testPoint.lng, 1e-9));
  });

  group('detail', () {
    Future<void> open(WidgetTester tester, {String id = 'i-1'}) => pushScreen(
      tester,
      pattern: Routes.incidentPattern,
      location: Routes.incident(id),
      screen: IncidentDetailScreen(id: id),
      overrides: overrides(),
    );

    testWidgets('aggregate figures, never "verified"', (tester) async {
      road.repo.incidents
        ..clear()
        ..add(
          Incident.fromJson(
            incidentJson(
              status: 'corroborated',
              reports: 4,
              reporters: 3,
              cleared: 1,
            ),
          ),
        );
      await open(tester);
      expect(find.text(t.roadCategoryFlooding), findsOneWidget);
      expect(find.text(t.roadStatusCorroborated), findsOneWidget);
      expect(
        find.text(t.roadReportedByUsers(t.roadAgoMinutes(5))),
        findsOneWidget,
      );
      expect(find.text(t.roadPeople(3)), findsOneWidget);
      expect(find.text(t.roadTimes(4)), findsOneWidget);
      expect(find.text(t.roadPeople(1)), findsOneWidget);
      expect(find.byKey(const Key('detail.map')), findsOneWidget);
      expect(find.byKey(const Key('detail.expires')), findsOneWidget);
      expect(find.byKey(const Key('detail.myReport')), findsNothing);
      await scrollIntoView(tester, find.byKey(const Key('road.notice')));
      expectNeverVerified();
    });

    testWidgets('"still there": sent, snackbar, my answer shown', (
      tester,
    ) async {
      await open(tester);
      await scrollAndTap(tester, 'detail.still');
      expect(road.repo.lastConfirm, (id: 'i-1', stillPresent: true));
      expect(find.text(t.roadConfirmSaved), findsOneWidget);
      expect(
        find.text(t.roadConfirmMineStill(t.roadAgoJustNow)),
        findsOneWidget,
      );
      // The detail reloads with the server's figures.
      expect(road.repo.calls.where((c) => c == 'detail:i-1'), hasLength(2));
    });

    testWidgets('reload after an answer keeps the detail on screen', (
      tester,
    ) async {
      await open(tester);
      await scrollIntoView(tester, find.byKey(const Key('detail.gone')));
      final before = tester.getTopLeft(find.byKey(const Key('detail.gone')));
      road.repo.detailGate = Completer<void>();
      await tester.tap(find.byKey(const Key('detail.gone')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(road.repo.calls.where((c) => c == 'detail:i-1'), hasLength(2));
      expect(find.byType(SummarySkeleton), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('detail.gone'))).dy,
        before.dy,
      );
      road.repo.detailGate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text(t.roadConfirmMineCleared(t.roadAgoJustNow)),
        findsOneWidget,
      );
    });

    testWidgets('"gone" on a closed incident: says why', (tester) async {
      road.repo.confirmError = const ApiFailure(
        statusCode: 409,
        code: ApiErrorCode.incidentClosed,
      );
      await open(tester);
      await scrollAndTap(tester, 'detail.gone');
      expect(road.repo.lastConfirm, (id: 'i-1', stillPresent: false));
      expect(find.text(t.failureIncidentClosed), findsOneWidget);
    });

    testWidgets('closed incident: no answer buttons', (tester) async {
      road.repo.incidents
        ..clear()
        ..add(testIncident(status: 'resolved'));
      await open(tester);
      expect(
        find.text(t.roadClosedMessage(t.roadStatusResolved)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('detail.still')), findsNothing);
      expect(find.byKey(const Key('detail.expires')), findsNothing);
    });

    testWidgets('my report: description, private photo, AI suggestion', (
      tester,
    ) async {
      road.repo.details['i-1'] = IncidentDetail(
        // "Gone" 30 minutes ago counts: the last report is older.
        incident: Incident.fromJson(
          incidentJson(lastAgo: const Duration(hours: 1)),
        ),
        myReport: ownReport(
          image: true,
          aiStatus: 'done',
          aiLabel: 'flooding',
          aiConfidence: '0.8200',
        ),
        myConfirmation: MyConfirmation(
          stillPresent: false,
          createdAt: testNowUtc(const Duration(minutes: 30)),
        ),
      );
      await open(tester);
      expect(
        find.text(t.roadConfirmMineCleared(t.roadAgoMinutes(30))),
        findsOneWidget,
      );
      await scrollIntoView(tester, find.byKey(const Key('detail.myReport')));
      expect(find.text('น้ำสูงครึ่งล้อ'), findsOneWidget);
      expect(road.repo.calls, contains('image:rep-1'));
      expect(find.byKey(const Key('detail.photo')), findsOneWidget);
      expect(
        find.text(t.roadAiSuggestion(t.roadCategoryFlooding, 82)),
        findsOneWidget,
      );
      expect(find.text(t.badgeEstimate), findsOneWidget);
      expectNeverVerified();
    });

    testWidgets('"gone" older than the latest report: asks to answer again', (
      tester,
    ) async {
      road.repo.details['i-1'] = IncidentDetail(
        incident: testIncident(), // last report 5 minutes ago
        myConfirmation: MyConfirmation(
          stillPresent: false,
          createdAt: testNowUtc(const Duration(minutes: 30)),
        ),
      );
      await open(tester);
      expect(
        find.text(t.roadConfirmMineClearedStale(t.roadAgoMinutes(30))),
        findsOneWidget,
      );
      expect(find.byKey(const Key('detail.mine')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('detail.gone')),
          matching: find.byType(FilledButton),
        ),
        findsNothing,
      );

      await scrollAndTap(tester, 'detail.gone');
      expect(road.repo.lastConfirm, (id: 'i-1', stillPresent: false));
      expect(find.byKey(const Key('detail.mineStale')), findsNothing);
      expect(
        find.text(t.roadConfirmMineCleared(t.roadAgoJustNow)),
        findsOneWidget,
      );
    });

    group('photo suggestion pending', () {
      // The "AI working" pulse is decorative: with reduced motion it holds
      // still, so pumpAndSettle measures only the polling under test.
      setUp(() {
        final dispatcher =
            TestWidgetsFlutterBinding.instance.platformDispatcher;
        dispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      });

      IncidentDetail withReport(
        String aiStatus, {
        Duration createdAgo = const Duration(seconds: 20),
      }) => IncidentDetail(
        incident: testIncident(),
        myReport: ownReport(
          image: true,
          aiStatus: aiStatus,
          aiLabel: aiStatus == 'done' ? 'flooding' : null,
          aiConfidence: aiStatus == 'done' ? '0.9100' : null,
          createdAgo: createdAgo,
        ),
      );

      int detailCalls() =>
          road.repo.calls.where((c) => c == 'detail:i-1').length;

      testWidgets('asks again until the suggestion arrives, then stops', (
        tester,
      ) async {
        road.repo.details['i-1'] = withReport('pending');
        await open(tester);
        await scrollIntoView(tester, find.byKey(const Key('detail.ai')));
        expect(find.text(t.roadAiPending), findsOneWidget);
        expect(detailCalls(), 1);

        await tester.pump(aiPollInterval);
        await tester.pumpAndSettle();
        expect(detailCalls(), 2);
        expect(find.text(t.roadAiPending), findsOneWidget);

        road.repo.details['i-1'] = withReport('done');
        await tester.pump(aiPollInterval);
        await tester.pumpAndSettle();
        expect(detailCalls(), 3);
        expect(
          find.text(t.roadAiSuggestion(t.roadCategoryFlooding, 91)),
          findsOneWidget,
        );
        expect(find.byType(SummarySkeleton), findsNothing);

        await tester.pump(aiPollInterval * 5);
        expect(detailCalls(), 3);
      });

      testWidgets('a failed poll keeps the screen and tries again', (
        tester,
      ) async {
        road.repo.details['i-1'] = withReport('pending');
        await open(tester);
        road.repo.detailError = const NetworkFailure();
        await tester.pump(aiPollInterval);
        await tester.pumpAndSettle();
        expect(detailCalls(), 2);
        expect(find.text(t.commonRetry), findsNothing);
        expect(find.byKey(const Key('detail.category')), findsOneWidget);

        road.repo
          ..detailError = null
          ..details['i-1'] = withReport('failed');
        await tester.pump(aiPollInterval);
        await tester.pumpAndSettle();
        expect(detailCalls(), 3);
        expect(find.text(t.roadAiPending), findsNothing);
        expect(find.byKey(const Key('detail.ai')), findsNothing);
      });

      testWidgets('no polling once the window after the report has passed', (
        tester,
      ) async {
        road.repo.details['i-1'] = withReport(
          'pending',
          createdAgo: aiPollWindow + const Duration(seconds: 1),
        );
        await open(tester);
        await tester.pump(aiPollInterval * 3);
        expect(detailCalls(), 1);
      });
    });

    testWidgets('photo error: retry', (tester) async {
      road.repo
        ..imageError = const NetworkFailure()
        ..details['i-1'] = IncidentDetail(
          incident: testIncident(),
          myReport: ownReport(image: true),
        );
      await open(tester);
      await scrollIntoView(tester, find.byKey(const Key('detail.photoRetry')));
      road.repo.imageError = null;
      await tapKey(tester, 'detail.photoRetry');
      expect(find.byKey(const Key('detail.photo')), findsOneWidget);
    });

    testWidgets('not found: error with retry', (tester) async {
      await open(tester, id: 'missing');
      expect(find.text(t.failureNotFound), findsOneWidget);
      expect(find.text(t.commonRetry), findsOneWidget);
    });
  });

  group('my reports', () {
    Future<void> open(WidgetTester tester) => pushScreen(
      tester,
      pattern: Routes.roadMyReports,
      location: Routes.roadMyReports,
      screen: const MyReportsScreen(),
      overrides: overrides(),
    );

    testWidgets('rows open the incident', (tester) async {
      road.repo.reports.addAll([
        ownReport(image: true),
        ownReport(id: 'rep-2', incidentId: 'i-2', description: null),
      ]);
      await open(tester);
      expect(find.byKey(const Key('myReport.rep-1')), findsOneWidget);
      expect(find.text(t.roadHasPhoto), findsOneWidget);
      expect(find.text(t.roadStatusUnverified), findsNWidgets(2));
      await tapKey(tester, 'myReport.rep-2');
      expect(find.text('route:${Routes.incident('i-2')}'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      await open(tester);
      expect(find.byKey(const Key('myReports.empty')), findsOneWidget);
    });
  });
}

/// [testNow] minus [ago] as a UTC instant.
DateTime testNowUtc(Duration ago) => DateTime.parse(isoAgo(ago));
