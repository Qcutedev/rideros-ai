// Host side of the Phase 4 E2E journey (`integration_test/app_journey_test.dart`).
//
// After the journey passes on the emulator, this checks every number the app
// showed against PostgreSQL (`docker compose exec db psql`), then deletes the
// throwaway account through `DELETE /me` and checks that none of its rows are
// left. Set `E2E_KEEP=1` to keep the account for a look in the database.
//
// Needs the compose stack from the repository root (`docker compose up -d`).

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

const _apiBase = 'http://127.0.0.1:8000/api/v1';

Future<void> main() => integrationDriver(responseDataCallback: _verify);

Future<void> _verify(Map<String, dynamic>? data) async {
  if (data == null) _fail('the journey sent no report');
  final checks = _Checks();
  final email = data['email'] as String;
  // The address is interpolated into SQL, so it must be the generated shape.
  if (!RegExp(r'^e2e\+\d+@example\.com$').hasMatch(email)) {
    _fail('unexpected e-mail $email');
  }

  final user = await _row(
    "select id, display_name from users where email = '$email'",
  );
  final userId = user[0];
  checks.equal('users.display_name', user[1], 'E2E Rider');

  final profile = await _row(
    'select vehicle_type, fuel_km_per_liter, fuel_price_per_liter, '
    "depreciation_per_km from rider_profiles where user_id = '$userId'",
  );
  checks.equal('rider_profiles', profile, [
    'motorcycle',
    '40.00',
    '38.50',
    '0.6000',
  ]);

  // Pickup: the app widens the interval to whole minutes and rounds the
  // midpoint to one decimal without trailing zeros.
  final prediction = data['prediction'] as Map<String, dynamic>;
  final p = await _row(
    'select floor(p.interval_low)::int, ceil(p.interval_high)::int, '
    'trim_scale(round(p.predicted_minutes, 1)), r.name, count(*) over () '
    'from pickup_predictions p join restaurants r on r.id = p.restaurant_id '
    "where p.user_id = '$userId'",
  );
  checks
    ..equal('pickup_predictions rows', p[4], '1')
    ..equal('prediction restaurant', p[3], prediction['restaurant'])
    ..equal('prediction range', prediction['range'], '${p[0]}–${p[1]} นาที')
    ..equal(
      'prediction midpoint',
      prediction['midpoint'],
      'ค่ากลางประมาณ ${p[2]} นาที',
    );

  // TrueProfit day view and the home card: today in the rider's timezone.
  const today = "(now() at time zone 'Asia/Bangkok')::date";
  final money = await _row(
    'select i.revenue, e.expenses, i.revenue - e.expenses, '
    'trim_scale(i.hours), round((i.revenue - e.expenses) / i.hours, 2) from '
    '(select coalesce(sum(amount), 0) revenue, sum(working_hours) hours '
    "from income_records where user_id = '$userId' and occurred_on = $today) i, "
    '(select coalesce(sum(amount), 0) expenses from expense_records '
    "where user_id = '$userId' and occurred_on = $today) e",
  );
  final day = data['profit_day'] as Map<String, dynamic>;
  checks
    ..equal('profit revenue', _money(day['revenue']), money[0])
    ..equal('profit expenses', _money(day['expenses']), money[1])
    ..equal('profit net', _money(day['net']), money[2])
    ..equal('profit hours', day['hours'], '${money[3]} ชม.')
    ..equal('profit net/hour', _money(day['net_per_hour']), money[4])
    ..equal('home today net', _money(data['home_today_net']), money[2]);

  // Shift comparison: every card against its stored estimate.
  final compare = data['compare'] as Map<String, dynamic>;
  final cards = compare['scenarios'] as Map<String, dynamic>;
  final names = <String, (String, String)>{};
  for (final MapEntry(key: id, value: card) in cards.entries) {
    if (!RegExp(r'^[0-9a-f-]{36}$').hasMatch(id)) _fail('bad scenario id $id');
    final s = await _row(
      'select estimated_revenue, estimated_expenses, estimated_net_profit, '
      'round(estimated_net_profit * 60 / duration_minutes, 2), name '
      "from shift_scenarios where id = '$id' and user_id = '$userId'",
    );
    final shown = card as Map<String, dynamic>;
    checks
      ..equal('scenario ${s[4]} revenue', _money(shown['revenue']), s[0])
      ..equal('scenario ${s[4]} expenses', _money(shown['expenses']), s[1])
      ..equal('scenario ${s[4]} net', _money(shown['net']), s[2])
      ..equal(
        'scenario ${s[4]} net/hour',
        _money((shown['per_hour'] as String).replaceAll('/ชม.', '')),
        s[3],
      );
    names[id] = (s[4], s[2]);
  }
  final best = names.values.reduce(
    (a, b) => double.parse(a.$2) >= double.parse(b.$2) ? a : b,
  );
  checks.equal(
    'best net',
    (compare['best_net'] as String).split('\n').first,
    best.$1,
  );

  stdout.writeln('E2E: ${checks.passed} DB checks passed.');
  if (checks.failures.isNotEmpty) {
    checks.failures.forEach(stderr.writeln);
    _fail('${checks.failures.length} DB check(s) failed (account kept)');
  }

  if (Platform.environment['E2E_KEEP'] == '1') {
    stdout.writeln('E2E: kept $email');
    return;
  }
  await _deleteAccount(email, data['password'] as String);
  final left = await _row(
    "select (select count(*) from users where id = '$userId') + "
    "(select count(*) from rider_profiles where user_id = '$userId') + "
    "(select count(*) from income_records where user_id = '$userId') + "
    "(select count(*) from expense_records where user_id = '$userId') + "
    "(select count(*) from work_sessions where user_id = '$userId') + "
    "(select count(*) from pickup_predictions where user_id = '$userId') + "
    "(select count(*) from pickup_logs where user_id = '$userId') + "
    "(select count(*) from shift_scenarios where user_id = '$userId') + "
    "(select count(*) from refresh_tokens where user_id = '$userId') + "
    "(select count(*) from restaurants where owner_user_id = '$userId')",
  );
  if (left[0] != '0') _fail('${left[0]} rows left after DELETE /me');
  stdout.writeln('E2E: deleted $email, no rows left.');
}

/// `฿1,234.50` → `1234.50`; `฿-80.00` → `-80.00`.
String _money(Object? shown) =>
    (shown as String).replaceAll('฿', '').replaceAll(',', '').trim();

class _Checks {
  int passed = 0;
  final failures = <String>[];

  void equal(String what, Object? actual, Object? expected) {
    if (jsonEncode(actual) == jsonEncode(expected)) {
      passed++;
      stdout.writeln('  ok  $what: $actual');
    } else {
      failures.add('MISMATCH $what: app=$actual db=$expected');
    }
  }
}

/// The single row of [sql] as text columns.
Future<List<String>> _row(String sql) async {
  final result = await Process.run(
    'docker',
    [
      'compose',
      'exec',
      '-T',
      'db',
      'psql',
      '-U',
      'rideros',
      '-d',
      'rideros',
      '-At',
      '-F',
      '|',
      '-v',
      'ON_ERROR_STOP=1',
      '-c',
      sql,
    ],
    workingDirectory: '..',
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) _fail('psql: ${result.stderr}\n$sql');
  final lines = (result.stdout as String)
      .split('\n')
      .map((l) => l.trimRight())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) _fail('no row for: $sql');
  return lines.first.split('|');
}

Future<void> _deleteAccount(String email, String password) async {
  final client = HttpClient();
  try {
    Future<HttpClientResponse> send(
      String method,
      String path,
      Map<String, String> body, [
      String? token,
    ]) async {
      final request = await client.openUrl(method, Uri.parse('$_apiBase$path'));
      request.headers.contentType = ContentType.json;
      if (token != null) request.headers.set('authorization', 'Bearer $token');
      request.write(jsonEncode(body));
      return request.close();
    }

    final login = await send('POST', '/auth/login', {
      'email': email,
      'password': password,
    });
    final tokens = jsonDecode(
      await login.transform(utf8.decoder).join(),
    ) as Map<String, dynamic>;
    if (login.statusCode != 200) _fail('login for delete: $tokens');
    final delete = await send('DELETE', '/me', {
      'password': password,
    }, tokens['access_token'] as String);
    await delete.drain<void>();
    if (delete.statusCode != 204) _fail('DELETE /me: ${delete.statusCode}');
  } finally {
    client.close();
  }
}

Never _fail(String message) {
  stderr.writeln('E2E FAILED: $message');
  exit(1);
}
