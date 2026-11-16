import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'theme/tokens.dart';

/// Messenger of the tab pages. Their snackbars belong to the page's own Scaffold,
/// which knows its FAB and bottom bar; the shell's Scaffold (an outer one) would
/// float them over those. Forms on the root navigator show their "saved" message
/// here after closing (`closeForm`).
final shellMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(debugLabel: 'shell messenger'),
);

/// Bottom navigation of the signed-in app. Each tab keeps its own navigation stack.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ScaffoldMessenger(
        key: ref.watch(shellMessengerKeyProvider),
        // Every tab page shows the snackbar inside this one route; as heroes
        // their copies would share a tag when a form over the tabs closes.
        child: HeroMode(enabled: false, child: shell),
      ),
      // RoadContext (Phase 5) gets no tab until the feature works (§3).
      // Floating Obsidian bar: a lime pill slides to the selected tab.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? AppShadows.floating
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              animationDuration: AppDurations.slow,
              // Tapping the current tab again returns to its first screen.
              onDestinationSelected: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
              destinations: [
                NavigationDestination(
                  key: const Key('nav.home'),
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  key: const Key('nav.pickup'),
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront_rounded),
                  label: l10n.navPickup,
                ),
                NavigationDestination(
                  key: const Key('nav.profit'),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: const Icon(
                    Icons.account_balance_wallet_rounded,
                  ),
                  label: l10n.navProfit,
                ),
                NavigationDestination(
                  key: const Key('nav.shifts'),
                  icon: const Icon(Icons.event_note_outlined),
                  selectedIcon: const Icon(Icons.event_note_rounded),
                  label: l10n.navShifts,
                ),
                NavigationDestination(
                  key: const Key('nav.profile'),
                  icon: const Icon(Icons.person_outline_rounded),
                  selectedIcon: const Icon(Icons.person_rounded),
                  label: l10n.navProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
