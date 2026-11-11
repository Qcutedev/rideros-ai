import 'dart:io';

import 'package:flutter/services.dart';

/// Serves assets straight from disk as plain futures, so they resolve inside a
/// widget test's fake time (wrap the app in a `DefaultAssetBundle`).
class FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}
