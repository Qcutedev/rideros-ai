import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/session_state.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/profit/presentation/pending_sync_controller.dart';
import '../l10n/app_localizations.dart';
import 'intro/brand_intro.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class RiderOsApp extends ConsumerStatefulWidget {
  const RiderOsApp({super.key});

  @override
  ConsumerState<RiderOsApp> createState() => _RiderOsAppState();
}

class _RiderOsAppState extends ConsumerState<RiderOsApp> {
  /// Back in the foreground: the connection may be back too.
  late final _lifecycle = AppLifecycleListener(
    onResume: () => ref.read(pendingSyncProvider.notifier).flushIfWaiting(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle; // created now so the first resume is not missed
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The brand intro holds its last frame until the stored session is resumed.
    final restoring = ref.watch(
      sessionControllerProvider.select((s) => s is SessionRestoring),
    );
    // Keeps the offline queue alive for the whole app, so it sends on start,
    // on resume and on its retry timer whatever screen is open.
    ref.listen(pendingSyncProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('th'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
      builder: ref.watch(brandIntroEnabledProvider)
          ? (context, child) =>
                BrandIntro(waiting: restoring, child: child ?? const SizedBox())
          : null,
    );
  }
}

/// Whether the animated brand intro plays at start. Overridden in tests that
/// drive the app's screens rather than the intro.
final brandIntroEnabledProvider = Provider<bool>((ref) => true);
