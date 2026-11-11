import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Primary action (52 dp, green). While [isLoading] it shows a spinner and
/// ignores taps, so a form cannot be submitted twice.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget child = isLoading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: scheme.onSurfaceVariant,
              semanticsLabel: label,
            ),
          )
        : icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: Text(label)),
            ],
          );
    return FilledButton(onPressed: isLoading ? null : onPressed, child: child);
  }
}

/// Secondary action: transparent with a green outline.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

/// Destructive action (red). Used only for deleting. While [isLoading] it shows a
/// spinner and ignores taps.
class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.onSurfaceVariant,
                semanticsLabel: label,
              ),
            )
          : Text(label),
    );
  }
}
