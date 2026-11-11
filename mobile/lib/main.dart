import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicense);
  runApp(
    ProviderScope(
      // Failures surface at once with a retry button instead of silent automatic retries.
      retry: (retryCount, error) => null,
      child: const RiderOsApp(),
    ),
  );
}

/// The bundled font is not a package, so its licence is added by hand.
Stream<LicenseEntry> _fontLicense() async* {
  final text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(['IBM Plex Sans Thai'], text);
}
