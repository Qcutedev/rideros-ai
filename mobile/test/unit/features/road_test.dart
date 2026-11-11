import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideros_ai/core/errors/app_failure.dart';
import 'package:rideros_ai/core/network/api_client.dart';
import 'package:rideros_ai/core/network/token_pair.dart';
import 'package:rideros_ai/core/storage/refresh_token_store.dart';
import 'package:rideros_ai/features/road/data/road_repository_impl.dart';
import 'package:rideros_ai/features/road/domain/road_models.dart';
import 'package:rideros_ai/features/road/presentation/road_labels.dart';
import 'package:rideros_ai/features/road/presentation/road_providers.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fakes.dart';
import '../../helpers/profit_fakes.dart';
import '../../helpers/pump.dart';
import '../../helpers/road_fakes.dart';

void main() {
  group('models', () {
    test('incident: enums, location, times as instants', () {
      final i = Incident.fromJson(
        incidentJson(category: 'road_damage', status: 'corroborated'),
      );
      expect(i.category, RoadCategory.roadDamage);
      expect(i.category.apiValue, 'road_damage');
      expect(i.status, IncidentStatus.corroborated);
      expect(i.status.isOpen, isTrue);
      expect(i.location, testPoint);
      expect(i.distanceM, isNull);
      expect(
        testNow().difference(i.lastReportedAt),
        const Duration(minutes: 5),
      );
    });

    test('only unverified and corroborated are open', () {
      expect(IncidentStatus.values.where((s) => s.isOpen), [
        IncidentStatus.unverified,
        IncidentStatus.corroborated,
      ]);
    });

    test('detail: own report and answer are optional', () {
      final bare = IncidentDetail.fromJson(detailJson());
      expect(bare.myReport, isNull);
      expect(bare.myConfirmation, isNull);
      final full = IncidentDetail.fromJson(
        detailJson(
          myReport: ownReportJson(
            image: true,
            aiStatus: 'done',
            aiLabel: 'flooding',
            aiConfidence: '0.8200',
          ),
          myConfirmation: {
            'still_present': true,
            'created_at': isoAgo(Duration.zero),
          },
        ),
      );
      expect(full.myReport!.hasImage, isTrue);
      expect(full.myReport!.aiConfidence, Decimal.parse('0.82'));
      expect(full.myConfirmation!.stillPresent, isTrue);
    });

    test('list: truncated defaults to false; the server notice is ignored', () {
      final list = IncidentList.fromJson({
        'items': [incidentJson(distance: 120.5)],
        'notice': 'server text',
      });
      expect(list.truncated, isFalse);
      expect(list.items.single.distanceM, 120.5);
    });
  });

  group('bounds', () {
    test('rounded outwards to 3 decimals', () {
      final b = RoadBounds(
        west: 100.50189,
        south: 13.75011,
        east: 100.52001,
        north: 13.76999,
      );
      expect(b.query, '100.501,13.75,100.521,13.77');
      expect(
        b,
        RoadBounds(
          west: 100.5012,
          south: 13.7502,
          east: 100.5201,
          north: 13.7695,
        ),
      );
      expect(b.tooLarge, isFalse);
    });

    test('wider or taller than 2° is too large', () {
      expect(
        RoadBounds(west: 100, south: 13, east: 102.01, north: 14).tooLarge,
        isTrue,
      );
      expect(
        RoadBounds(west: 100, south: 13, east: 101, north: 15.5).tooLarge,
        isTrue,
      );
      expect(
        RoadBounds(west: 100, south: 13, east: 102, north: 15).tooLarge,
        isFalse,
      );
    });

    test('clamped to the world', () {
      final b = RoadBounds(west: -200, south: -95, east: 190, north: 91);
      expect(b.query, '-180.0,-90.0,180.0,90.0');
    });
  });

  group('labels', () {
    final now = DateTime.utc(2026, 11, 10, 7);

    test('ago', () {
      String ago(Duration d) => agoLabel(t, now.subtract(d), now);
      expect(ago(const Duration(seconds: 59)), t.roadAgoJustNow);
      expect(ago(const Duration(minutes: 1)), t.roadAgoMinutes(1));
      expect(ago(const Duration(minutes: 59)), t.roadAgoMinutes(59));
      expect(ago(const Duration(hours: 1)), t.roadAgoHours(1));
      expect(ago(const Duration(hours: 23, minutes: 59)), t.roadAgoHours(23));
      expect(ago(const Duration(days: 3)), t.roadAgoDays(3));
    });

    test('distance', () {
      expect(distanceLabel(t, 0), '0 ม.');
      expect(distanceLabel(t, 344), '340 ม.');
      expect(distanceLabel(t, 994), '990 ม.');
      expect(distanceLabel(t, 995), '1 กม.');
      expect(distanceLabel(t, 1260), '1.3 กม.');
      expect(distanceLabel(t, 4999), '5 กม.');
    });

    test('AI suggestion: a suggestion only, unsure below 0.6', () {
      String? ai(String status, [String? label, String? confidence]) =>
          aiSuggestionText(
            t,
            ownReport(
              image: true,
              aiStatus: status,
              aiLabel: label,
              aiConfidence: confidence,
            ),
          );
      expect(ai('none'), isNull);
      expect(ai('failed'), isNull);
      expect(ai('pending'), t.roadAiPending);
      expect(
        ai('done', 'flooding', '0.8250'),
        t.roadAiSuggestion(t.roadCategoryFlooding, 83),
      );
      expect(
        ai('done', 'road_damage', '0.6000'),
        t.roadAiSuggestion(t.roadCategoryRoadDamage, 60),
      );
      expect(
        ai('done', 'other', '0.9000'),
        t.roadAiSuggestion(t.roadAiOther, 90),
      );
      expect(ai('done', 'flooding', '0.5999'), t.roadAiUnsure);
      expect(ai('done'), isNull);
      for (final text in [
        ai('pending'),
        ai('done', 'flooding', '0.99'),
        ai('done', 'flooding', '0.1'),
      ]) {
        expect(text, isNot(contains('ยืนยันแล้ว')));
      }
    });

    test('statuses never say "verified"', () {
      for (final s in IncidentStatus.values) {
        expect(statusLabel(t, s), isNot(contains('ยืนยันแล้ว')));
      }
      expect(statusLabel(t, IncidentStatus.corroborated), 'มีผู้รายงานหลายคน');
    });
  });

  group('repository over HTTP', () {
    late FakeHttpAdapter adapter;
    late ProviderContainer container;

    setUp(() async {
      adapter = FakeHttpAdapter((o) => json(404));
      container = ProviderContainer.test(
        retry: (retryCount, error) => null,
        overrides: [
          refreshTokenStoreProvider.overrideWithValue(
            InMemoryRefreshTokenStore(),
          ),
          baseDioProvider.overrideWith(
            (ref) =>
                Dio(BaseOptions(baseUrl: 'http://test/api/v1'))
                  ..httpClientAdapter = adapter,
          ),
        ],
      );
      await container
          .read(sessionTokenManagerProvider)
          .save(
            TokenPair(
              accessToken: 'access-1',
              refreshToken: 'refresh-1',
              expiresIn: 900,
              refreshExpiresAt: DateTime.utc(2026, 12, 10),
            ),
          );
    });

    test('report: multipart fields and photo', () async {
      adapter.handler = (o) => json(201, {
        'report_id': 'rep-1',
        'incident_id': 'i-1',
        'merged': true,
        'status': 'corroborated',
        'incident': incidentJson(status: 'corroborated'),
      });
      final created = await container
          .read(roadRepositoryProvider)
          .createReport(
            NewReport(
              category: RoadCategory.roadObstacle,
              location: testPoint,
              description: 'กิ่งไม้ล้ม',
              photo: ReportPhoto(
                bytes: Uint8List.fromList([1, 2, 3]),
                name: 'tree.jpg',
              ),
            ),
          );
      expect(created.merged, isTrue);
      expect(created.status, IncidentStatus.corroborated);
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/road/reports');
      expect(request.headers['Authorization'], 'Bearer access-1');
      final form = request.data as FormData;
      expect(Map.fromEntries(form.fields), {
        'category': 'road_obstacle',
        'lat': '13.7563',
        'lng': '100.5018',
        'description': 'กิ่งไม้ล้ม',
      });
      expect(form.files.single.key, 'image');
      expect(form.files.single.value.filename, 'tree.jpg');
      expect(form.files.single.value.length, 3);
    });

    test('report without photo or description sends neither', () async {
      adapter.handler = (o) => json(201, {
        'report_id': 'rep-1',
        'incident_id': 'i-1',
        'merged': false,
        'status': 'unverified',
        'incident': incidentJson(),
      });
      await container
          .read(roadRepositoryProvider)
          .createReport(
            const NewReport(
              category: RoadCategory.flooding,
              location: testPoint,
            ),
          );
      final form = adapter.requests.single.data as FormData;
      expect(form.fields.map((f) => f.key), ['category', 'lat', 'lng']);
      expect(form.files, isEmpty);
    });

    test('already reported: the incident id comes with the failure', () async {
      adapter.handler = (o) => apiError(
        409,
        'already_reported',
        details: [
          {'incident_id': 'i-7'},
        ],
      );
      await expectLater(
        container
            .read(roadRepositoryProvider)
            .createReport(
              const NewReport(
                category: RoadCategory.flooding,
                location: testPoint,
              ),
            ),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', ApiErrorCode.alreadyReported)
              .having((f) => f.detail('incident_id'), 'incident_id', 'i-7')
              .having((f) => f.detail('missing'), 'missing', isNull),
        ),
      );
    });

    test('bbox, nearby, detail, confirm, image', () async {
      adapter.handler = (o) => switch (o.path) {
        '/road/incidents' || '/road/incidents/nearby' => json(200, {
          'items': [incidentJson()],
          'truncated': o.path == '/road/incidents',
          'notice': 'x',
        }),
        '/road/incidents/i-1' ||
        '/road/incidents/i-1/confirmations' => json(200, detailJson()),
        '/road/reports/rep-1/image' => ResponseBody.fromBytes(
          [0xFF, 0xD8, 0xFF],
          200,
          headers: {
            Headers.contentTypeHeader: ['image/jpeg'],
          },
        ),
        _ => json(404),
      };
      final repo = container.read(roadRepositoryProvider);
      final view = await repo.incidentsIn(
        RoadBounds(west: 100.5, south: 13.7, east: 100.6, north: 13.8),
      );
      expect(view.truncated, isTrue);
      expect(adapter.requests.last.queryParameters, {
        'bbox': '100.5,13.7,100.6,13.8',
      });
      final near = await repo.nearby(testPoint);
      expect(near.items, hasLength(1));
      expect(adapter.requests.last.queryParameters, {
        'lat': 13.7563,
        'lng': 100.5018,
        'radius_m': 2000,
      });
      expect((await repo.incident('i-1')).incident.id, 'i-1');
      await repo.confirm('i-1', stillPresent: false);
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.last.data, {'still_present': false});
      expect(await repo.reportImage('rep-1'), [0xFF, 0xD8, 0xFF]);
    });

    test('my reports: page with cursor', () async {
      adapter.handler = (o) => json(200, {
        'items': [ownReportJson()],
        'next_cursor': 'n-2',
      });
      final page = await container
          .read(roadRepositoryProvider)
          .myReports(cursor: 'n-1');
      expect(page.items.single.incidentId, 'i-1');
      expect(page.nextCursor, 'n-2');
      expect(adapter.requests.single.queryParameters, {'cursor': 'n-1'});
    });
  });

  group('providers', () {
    test('a report bumps the revision and keeps the answer', () async {
      final road = RoadFakes();
      final container = ProviderContainer.test(
        overrides: fakeRepositories(
          FakeAuthRepository(),
          null,
          null,
          null,
          null,
          road,
        ),
      );
      final sub = container.listen(reportFormProvider, (_, _) {});
      final ok = await container
          .read(reportFormProvider.notifier)
          .submit(
            const NewReport(
              category: RoadCategory.flooding,
              location: testPoint,
            ),
          );
      expect(ok, isTrue);
      expect(container.read(roadDataRevisionProvider), 1);
      expect(
        container.read(reportFormProvider.notifier).created!.incidentId,
        'i-new',
      );
      sub.close();
    });

    test('a failed answer keeps the revision', () async {
      final road = RoadFakes()
        ..repo.confirmError = const ApiFailure(
          statusCode: 409,
          code: ApiErrorCode.incidentClosed,
        );
      final container = ProviderContainer.test(
        overrides: fakeRepositories(
          FakeAuthRepository(),
          null,
          null,
          null,
          null,
          road,
        ),
      );
      final provider = confirmationProvider('i-1');
      final sub = container.listen(provider, (_, _) {});
      expect(
        await container.read(provider.notifier).answer(stillPresent: true),
        isFalse,
      );
      expect(container.read(roadDataRevisionProvider), 0);
      expect(container.read(provider).error, isA<ApiFailure>());
      sub.close();
    });
  });
}
