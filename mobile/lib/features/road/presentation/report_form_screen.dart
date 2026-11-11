import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_layout.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../data/device_services.dart';
import '../domain/road_models.dart';
import 'road_labels.dart';
import 'road_providers.dart';
import 'widgets/road_map.dart';

/// `/road/report`: category, location (GPS or a pin), optional photo and
/// description. Pops the server's [ReportCreated] on success.
class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  RoadCategory? _category;
  ReportPhoto? _photo;
  String? _photoError;

  /// Chosen on the map; overrides the GPS position.
  RoadPoint? _pinned;

  /// Errors appear after the first send attempt.
  bool _submitted = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  RoadPoint? get _gps => switch (ref.read(currentLocationProvider).value) {
    LocationFound(:final point) => point,
    _ => null,
  };

  Future<void> _chooseLocation(RoadPoint? start) async {
    final picked = await context.push<RoadPoint>(
      Routes.roadPickLocation,
      extra: start,
    );
    if (picked != null && mounted) setState(() => _pinned = picked);
  }

  Future<void> _pickPhoto(PhotoSource source) async {
    final l10n = AppLocalizations.of(context);
    try {
      final photo = await ref.read(photoPickerProvider).pick(source);
      if (photo == null || !mounted) return;
      setState(() {
        if (photo.bytes.length > RoadLimits.maxImageBytes) {
          _photoError = l10n.roadReportPhotoTooLarge;
        } else {
          _photo = photo;
          _photoError = null;
        }
      });
    } on PhotoPickFailure {
      if (mounted) setState(() => _photoError = l10n.roadReportPhotoFailed);
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    final fieldsValid = _formKey.currentState!.validate();
    final category = _category;
    final location = _pinned ?? _gps;
    if (!fieldsValid || category == null || location == null) return;
    final controller = ref.read(reportFormProvider.notifier);
    final ok = await controller.submit(
      NewReport(
        category: category,
        location: location,
        description: optionalTextOf(_description),
        photo: _photo,
      ),
    );
    if (ok && mounted) context.pop(controller.created);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = Validators(l10n);
    final submit = ref.watch(reportFormProvider);
    final busy = submit.isLoading;
    final gps = ref.watch(currentLocationProvider);
    final gpsPoint = switch (gps.value) {
      LocationFound(:final point) => point,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.roadReportTitle)),
      body: FormLayout(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategoryField(
                  value: _category,
                  enabled: !busy,
                  errorText: _submitted && _category == null
                      ? l10n.roadReportCategoryRequired
                      : null,
                  onChanged: (c) => setState(() => _category = c),
                ),
                formGap,
                _LocationField(
                  pinned: _pinned,
                  gps: gpsPoint,
                  finding: gps.isLoading,
                  enabled: !busy,
                  errorText:
                      _submitted &&
                          _pinned == null &&
                          gpsPoint == null &&
                          !gps.isLoading
                      ? l10n.roadReportLocationRequired
                      : null,
                  onChoose: () =>
                      _chooseLocation(_pinned ?? gpsPoint ?? defaultMapCenter),
                ),
                formGap,
                _PhotoField(
                  photo: _photo,
                  errorText: _photoError,
                  enabled: !busy,
                  onPick: _pickPhoto,
                  onRemove: () => setState(() => _photo = null),
                ),
                formGap,
                AppTextField(
                  key: const Key('reportForm.description'),
                  controller: _description,
                  label: l10n.roadReportDescription,
                  helperText: l10n.commonOptional,
                  maxLength: RoadLimits.descriptionMaxLength,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  enabled: !busy,
                  validator: (value) => v.optionalText(
                    value,
                    max: RoadLimits.descriptionMaxLength,
                  ),
                ),
              ],
            ),
          ),
          formGap,
          if (submit case AsyncError(:final AppFailure error)) ...[
            _SubmitError(failure: error),
            formGap,
          ],
          AppPrimaryButton(
            key: const Key('reportForm.submit'),
            label: l10n.roadReportSubmit,
            icon: Icons.send_rounded,
            isLoading: busy,
            onPressed: _send,
          ),
          const SizedBox(height: AppSpacing.lg),
          const RoadNotice(),
        ],
      ),
    );
  }
}

/// `already_reported` links to the incident the rider reported before.
class _SubmitError extends StatelessWidget {
  const _SubmitError({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = this.failure;
    if (failure is ApiFailure &&
        failure.code == ApiErrorCode.alreadyReported &&
        failure.detail('incident_id') != null) {
      final id = failure.detail('incident_id')!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBanner(
            key: const Key('reportForm.alreadyReported'),
            message: l10n.roadAlreadyReported,
            tone: BannerTone.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            key: const Key('reportForm.openIncident'),
            label: l10n.roadOpenIncident,
            onPressed: () => context.pushReplacement(Routes.incident(id)),
          ),
        ],
      );
    }
    return AppBanner.failure(context, failure);
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.value,
    required this.enabled,
    required this.errorText,
    required this.onChanged,
  });

  final RoadCategory? value;
  final bool enabled;
  final String? errorText;
  final ValueChanged<RoadCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final errorText = this.errorText;
    return LabeledField(
      label: l10n.roadReportCategory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in RoadCategory.values)
                ChoiceChip(
                  key: Key('reportForm.category.${category.apiValue}'),
                  avatar: Icon(categoryIcon(category), size: 18),
                  label: Text(categoryLabel(l10n, category)),
                  selected: value == category,
                  showCheckmark: false,
                  onSelected: enabled ? (_) => onChanged(category) : null,
                ),
            ],
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: AppSpacing.md,
              ),
              child: Text(
                errorText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.pinned,
    required this.gps,
    required this.finding,
    required this.enabled,
    required this.errorText,
    required this.onChoose,
  });

  final RoadPoint? pinned;
  final RoadPoint? gps;
  final bool finding;
  final bool enabled;
  final String? errorText;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final point = pinned ?? gps;
    final errorText = this.errorText;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return LabeledField(
      label: l10n.roadReportLocation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (point != null) ...[
            StaticPinMap(key: const Key('reportForm.map'), point: point),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${pinned != null ? l10n.roadReportLocationManual : l10n.roadReportLocationGps}'
              ' · ${point.lat.toStringAsFixed(5)}, ${point.lng.toStringAsFixed(5)}',
              key: const Key('reportForm.locationText'),
              style: theme.textTheme.bodyMedium,
            ),
          ] else if (finding)
            Row(
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(l10n.roadLocationFinding, style: muted),
              ],
            )
          else
            AppBanner(
              key: const Key('reportForm.noGps'),
              message: l10n.roadReportLocationNoGps,
              tone: BannerTone.warning,
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('reportForm.chooseLocation'),
              onPressed: enabled && !(finding && point == null)
                  ? onChoose
                  : null,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(
                point == null
                    ? l10n.roadReportChooseLocation
                    : l10n.roadReportChangeLocation,
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                errorText,
                key: const Key('reportForm.locationError'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.roadReportLocationHelp, style: muted),
        ],
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  const _PhotoField({
    required this.photo,
    required this.errorText,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final ReportPhoto? photo;
  final String? errorText;
  final bool enabled;
  final ValueChanged<PhotoSource> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photo = this.photo;
    final errorText = this.errorText;
    return LabeledField(
      label: '${l10n.roadReportPhoto} (${l10n.commonOptional})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.memory(
                    photo.bytes,
                    key: const Key('reportForm.photo'),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 180,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: IconButton.filledTonal(
                    key: const Key('reportForm.removePhoto'),
                    tooltip: l10n.roadReportRemovePhoto,
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  key: const Key('reportForm.camera'),
                  onPressed: enabled ? () => onPick(PhotoSource.camera) : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.roadReportTakePhoto),
                ),
                OutlinedButton.icon(
                  key: const Key('reportForm.gallery'),
                  onPressed: enabled ? () => onPick(PhotoSource.gallery) : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.roadReportPickPhoto),
                ),
              ],
            ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                errorText,
                key: const Key('reportForm.photoError'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.roadReportPhotoHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
