import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_cards.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../l10n/app_localizations.dart';

/// `/profile/about`: what the app is, the data behind the Pickup model, licences.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: FormLayout(
        children: [
          AppWordmark(title: l10n.appTitle, tagline: l10n.appTagline),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.aboutDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            key: const Key('about.data'),
            tone: AppTone.sage,
            title: l10n.aboutDataTitle,
            child: Builder(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.aboutDataBody, style: _muted(context)),
                  const SizedBox(height: AppSpacing.md),
                  // Required wording, kept in English (Meituan licence terms).
                  Text(
                    l10n.meituanAcknowledgement,
                    key: const Key('about.acknowledgement'),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          SectionCard(
            tone: AppTone.mist,
            title: l10n.aboutFontTitle,
            child: Builder(
              builder: (context) =>
                  Text(l10n.aboutFontBody, style: _muted(context)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSecondaryButton(
            key: const Key('about.licenses'),
            label: l10n.aboutLicenses,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _muted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium?.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}
