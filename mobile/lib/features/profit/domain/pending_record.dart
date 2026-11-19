import 'dart:convert';

/// Record types the offline queue can create, with their `POST` path.
enum PendingKind {
  workSession('/work-sessions'),
  income('/income'),
  expense('/expenses');

  const PendingKind(this.path);

  final String path;
}

/// Local code of an item whose linked work session was refused by the server,
/// so sending it would only fail with `invalid_work_session`.
const linkedSessionFailedCode = 'linked_session_failed';

/// A create the app could not send yet (no connection). It is sent later with the
/// same client [id], so a resend after a lost response returns the stored record.
class PendingRecord {
  const PendingRecord({
    required this.id,
    required this.kind,
    required this.body,
    required this.queuedAt,
    this.failureStatus,
    this.failureCode,
  });

  final String id;
  final PendingKind kind;

  /// The `POST` body as the API takes it, without `id`.
  final Map<String, Object?> body;
  final DateTime queuedAt;

  /// Set once the server refused the record for good (a 4xx such as an overlap).
  final int? failureStatus;
  final String? failureCode;

  bool get isFailed => failureCode != null;

  /// The work session an income or expense links to.
  String? get workSessionId => switch (body['work_session_id']) {
    final String id => id,
    _ => null,
  };

  Map<String, Object?> get requestBody => {...body, 'id': id};

  /// The record as the API would return it, for showing it before it is sent.
  Map<String, dynamic> get asStoredJson {
    final at = queuedAt.toUtc().toIso8601String();
    return {
      ...body,
      'id': id,
      'is_demo': false,
      'created_at': at,
      'updated_at': at,
    };
  }

  PendingRecord failed(int status, String code) => PendingRecord(
    id: id,
    kind: kind,
    body: body,
    queuedAt: queuedAt,
    failureStatus: status,
    failureCode: code,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'body': body,
    'queued_at': queuedAt.toUtc().toIso8601String(),
    'failure_status': ?failureStatus,
    'failure_code': ?failureCode,
  };

  /// `null` for anything that is not a well-formed item.
  static PendingRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final kind = PendingKind.values.asNameMap()[json['kind']];
    final body = json['body'];
    final queuedAt = switch (json['queued_at']) {
      final String at => DateTime.tryParse(at),
      _ => null,
    };
    if (id is! String || kind == null || body is! Map || queuedAt == null) {
      return null;
    }
    final status = json['failure_status'];
    final code = json['failure_code'];
    return PendingRecord(
      id: id,
      kind: kind,
      body: Map<String, Object?>.from(body),
      queuedAt: queuedAt,
      failureStatus: status is int ? status : null,
      failureCode: code is String ? code : null,
    );
  }
}

/// `null` when the queue is empty.
String? encodePendingRecords(List<PendingRecord> items) => items.isEmpty
    ? null
    : jsonEncode([for (final item in items) item.toJson()]);

/// Unreadable items are dropped rather than blocking the rest of the queue.
List<PendingRecord> decodePendingRecords(String? value) {
  if (value == null) return const [];
  try {
    final list = jsonDecode(value);
    if (list is! List) return const [];
    return [for (final json in list) ?PendingRecord.fromJson(json)];
  } on FormatException {
    return const [];
  }
}
