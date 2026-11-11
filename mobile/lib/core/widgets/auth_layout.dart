import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import 'form_layout.dart';

/// Layout of the signed-out screens (login, register, forgot/reset password):
/// a Forest Green header with a rounded bottom edge, the form in a white card
/// overlapping it, then optional [footer] links below the card.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.header,
    required this.children,
    this.footer = const [],
    super.key,
  });

  final Widget header;

  /// Card content.
  final List<Widget> children;
  final List<Widget> footer;

  /// How far the card overlaps the header.
  static const _overlap = AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons on the green header.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.xl + AppSpacing.sm),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: _overlap),
                    child: header,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -_overlap),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            child: Padding(
                              padding: AppSpacing.cardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: children,
                              ),
                            ),
                          ),
                          if (footer.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            ...footer,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header content: the full wordmark (login) or a page title with a back button.
class AuthHeader extends StatelessWidget {
  /// Logo, app name and tagline, centred.
  const AuthHeader.brand({
    required this.title,
    required String tagline,
    super.key,
  }) : subtitle = tagline,
       isBrand = true;

  /// Back button (when there is a screen to go back to) at the top left, then
  /// logo, title and an optional description centred like the login header.
  const AuthHeader.page({required this.title, this.subtitle, super.key})
    : isBrand = false;

  final String title;
  final String? subtitle;
  final bool isBrand;

  @override
  Widget build(BuildContext context) {
    if (isBrand) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: AppWordmark(title: title, tagline: subtitle, onDark: true),
      );
    }
    final theme = Theme.of(context);
    final semantic = context.semanticColors;
    final canPop = Navigator.of(context).canPop();
    // Full width up to the max: the back button keeps to the left edge.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.maxContentWidth + AppSpacing.xl,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: AppSizes.minTouch,
                  child: canPop
                      ? const BackButton(color: Colors.white)
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogoMark(size: 56, onDark: true)),
                      const SizedBox(height: AppSpacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: semantic.onHeroMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
