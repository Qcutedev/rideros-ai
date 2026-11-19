import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_guard.dart';
import '../domain/pending_record.dart';

/// The offline queue on the device, one list per account (like the Home timer):
/// another rider who logs in on the same phone never sends someone else's records.
abstract interface class PendingRecordStore {
  Future<List<PendingRecord>> read(String userId);
  Future<void> write(String userId, List<PendingRecord> items);
}

final pendingRecordStoreProvider = Provider<PendingRecordStore>(
  (ref) => SharedPreferencesPendingRecordStore(SharedPreferencesAsync()),
);

class SharedPreferencesPendingRecordStore implements PendingRecordStore {
  SharedPreferencesPendingRecordStore(this._prefs);

  final SharedPreferencesAsync _prefs;

  static String _key(String userId) => 'pending_records.$userId';

  @override
  Future<List<PendingRecord>> read(String userId) async =>
      decodePendingRecords(await _prefs.getString(_key(userId)));

  @override
  Future<void> write(String userId, List<PendingRecord> items) {
    final value = encodePendingRecords(items);
    return value == null
        ? _prefs.remove(_key(userId))
        : _prefs.setString(_key(userId), value);
  }
}

/// Sends one queued create. Throws an `AppFailure`.
abstract interface class PendingRecordSender {
  Future<void> send(PendingRecord item);
}

final pendingRecordSenderProvider = Provider<PendingRecordSender>(
  (ref) => ApiPendingRecordSender(ref.watch(apiClientProvider)),
);

class ApiPendingRecordSender implements PendingRecordSender {
  ApiPendingRecordSender(this._dio);

  final Dio _dio;

  /// 201 (stored now) and 200 (stored by an earlier attempt) both count as sent.
  @override
  Future<void> send(PendingRecord item) => guardApi(() async {
    await _dio.post<Map<String, dynamic>>(
      item.kind.path,
      data: item.requestBody,
    );
  });
}
