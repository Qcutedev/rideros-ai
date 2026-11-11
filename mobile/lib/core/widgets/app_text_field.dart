import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Label above an input (§5.2). The visible text is hidden from screen readers
/// and the same label is attached to the field itself, so TalkBack reads it
/// together with the field instead of as a separate item.
class LabeledField extends StatelessWidget {
  const LabeledField({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs + AppSpacing.xxs),
        Semantics(label: label, child: child),
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.helperText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.enabled = true,
    this.maxLength,
    this.prefixIcon,
    this.suffixText,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final int? maxLength;
  final IconData? prefixIcon;
  final String? suffixText;

  /// More than one line makes a multi-line notes field.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: TextFormField(
        controller: controller,
        validator: validator,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        inputFormatters: inputFormatters,
        onFieldSubmitted: onFieldSubmitted,
        maxLength: maxLength,
        maxLines: maxLines,
        minLines: 1,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          helperText: helperText,
          helperMaxLines: 2,
          errorMaxLines: 3,
          counterText: '',
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          suffixText: suffixText,
        ),
      ),
    );
  }
}

/// Password input with a show/hide toggle. Never autocorrected or suggested.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    this.validator,
    this.helperText,
    this.textInputAction = TextInputAction.next,
    this.autofillHints = const [AutofillHints.password],
    this.onFieldSubmitted,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LabeledField(
      label: widget.label,
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        enabled: widget.enabled,
        obscureText: _obscured,
        enableSuggestions: false,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onFieldSubmitted,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          helperText: widget.helperText,
          helperMaxLines: 2,
          errorMaxLines: 3,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
            icon: Icon(
              _obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
        ),
      ),
    );
  }
}
