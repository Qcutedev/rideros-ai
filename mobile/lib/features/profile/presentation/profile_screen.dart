import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/session_state.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/rider_profile.dart';
import 'profile_providers.dart';
import 'vehicle_type_label.dart';

/// Profile tab (S-PROFILE): account, vehicle and costs, time zone and currency,
/// about/licences, logout and account deletion.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    // Never fails: the local session ends even when the server is unreachable.
    await ref.read(sessionControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider);
    final user = session is SignedIn ? session.user : null;
    final profile = ref.watch(riderProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(riderProfileProvider.future),
        child: PageColumn(
          child: ListView(
            padding: AppSpacing.screen,
            children: [
              if (user != null) ...[
                _AccountHeader(user: user),
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l10n.profileAccountSection),
                const SizedBox(height: AppSpacing.md),
                TileGroup(
                  children: [
                    ListTile(
                      key: const Key('profile.displayName'),
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(l10n.fieldDisplayName),
                      subtitle: Text(user.displayName),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(Routes.profileDisplayName),
                    ),
                    ListTile(
                      key: const Key('profile.email'),
                      leading: const Icon(Icons.mail_outline_rounded),
                      title: Text(l10n.fieldEmail),
                      subtitle: Text(
                        '${user.email}\n${l10n.profileEmailHelper}',
                      ),
                      isThreeLine: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              SectionHeader(title: l10n.profileVehicleSection),
              const SizedBox(height: AppSpacing.md),
              AsyncValueView(
                value: profile,
                onRetry: () => ref.invalidate(riderProfileProvider),
                loading: const ListSkeleton(rows: 3),
                data: (p) => _RiderProfileTiles(profile: p),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.profileInfoSection),
              const SizedBox(height: AppSpacing.md),
              TileGroup(
                tone: AppTone.teal,
                children: [
                  ListTile(
                    key: const Key('profile.about'),
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(l10n.profileAbout),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.about),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppSecondaryButton(
                key: const Key('profile.logout'),
                label: l10n.logout,
                onPressed: _loggingOut ? null : _logout,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton.icon(
                key: const Key('profile.deleteAccount'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: _loggingOut
                    ? null
                    : () => context.push(Routes.deleteAccount),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l10n.profileDeleteAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = user.displayName.trim();
    return ToneCard(
      key: const Key('profile.header'),
      tone: AppTone.obsidian,
      radius: AppRadius.xl,
      gradient: const RadialGradient(
        center: Alignment(1.1, -1.2),
        radius: 1.3,
        colors: [Color(0x33D5FF83), Color(0x00D5FF83)],
      ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final semantic = context.semanticColors;
          return Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: semantic.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: semantic.onAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.profileMemberSince(
                        Formats.date(user.createdAt.toLocal(), l10n.localeName),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RiderProfileTiles extends StatelessWidget {
  const _RiderProfileTiles({required this.profile});

  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = vehicleSummary(l10n, profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TileGroup(
          tone: AppTone.sage,
          children: [
            ListTile(
              key: const Key('profile.vehicle'),
              leading: const Icon(Icons.two_wheeler_outlined),
              title: Text(l10n.profileVehicleTile),
              subtitle: Text(summary ?? l10n.profileVehicleNotConfigured),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.riderProfile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionHeader(title: l10n.profileRegionSection),
        const SizedBox(height: AppSpacing.md),
        TileGroup(
          tone: AppTone.mist,
          children: [
            ListTile(
              key: const Key('profile.timezone'),
              leading: const Icon(Icons.schedule_outlined),
              title: Text(l10n.profileTimezone),
              subtitle: Text(profile.timezone),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.riderProfile),
            ),
            ListTile(
              key: const Key('profile.currency'),
              leading: const Icon(Icons.payments_outlined),
              title: Text(l10n.profileCurrency),
              subtitle: Text(profile.currency),
            ),
          ],
        ),
      ],
    );
  }
}

/// `มอเตอร์ไซค์ · 45.5 กม./ลิตร · น้ำมัน ฿38.50/ลิตร · ค่าเสื่อม ฿0.25/กม.`;
/// `null` when nothing has been filled in.
String? vehicleSummary(AppLocalizations l10n, RiderProfile profile) {
  final parts = [
    if (profile.vehicleType case final type?) vehicleTypeLabel(l10n, type),
    if (profile.fuelKmPerLiter case final km?)
      l10n.profileFuelEconomyValue(Formats.compact(km)),
    if (profile.fuelPricePerLiter case final price?)
      l10n.profileFuelPriceValue(Formats.currency(price, profile.currency)),
    // Up to four decimals: shown as entered, not rounded to money.
    if (profile.depreciationPerKm case final perKm?)
      l10n.profileDepreciationValue('฿${Formats.decimalInput(perKm)}'),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
