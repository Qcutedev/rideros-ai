import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Failures surface at once with a retry button instead of silent automatic retries.
      retry: (retryCount, error) => null,
      child: const RiderOsApp(),
    ),
  );
}
