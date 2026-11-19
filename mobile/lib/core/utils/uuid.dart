import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// New random record ids. Overridden in tests so ids are predictable.
final uuidProvider = Provider<String Function()>((ref) => newUuidV4);

final _random = Random.secure();

/// RFC 4122 version 4 UUID, e.g. `0b7d4f7e-3c1a-4f7e-9a3b-2c6d8e1f0a5b`.
String newUuidV4([Random? random]) {
  final source = random ?? _random;
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return [
    hex.sublist(0, 4).join(),
    hex.sublist(4, 6).join(),
    hex.sublist(6, 8).join(),
    hex.sublist(8, 10).join(),
    hex.sublist(10).join(),
  ].join('-');
}
