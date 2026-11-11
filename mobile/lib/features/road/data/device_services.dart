import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/road_models.dart';

// ---- location ----

/// Why the rider's position is not known.
enum LocationProblem {
  /// Location is switched off on the device.
  serviceDisabled,

  /// The rider said no; the app may ask again.
  denied,

  /// The rider said "don't ask again": only the app settings can change it.
  deniedForever,

  /// No fix in time or a platform error.
  unavailable,
}

sealed class LocationResult {
  const LocationResult();
}

final class LocationFound extends LocationResult {
  const LocationFound(this.point);

  final RoadPoint point;
}

final class LocationMissing extends LocationResult {
  const LocationMissing(this.problem);

  final LocationProblem problem;
}

/// The device position, "while in use" only (no background tracking).
abstract interface class LocationService {
  /// Asks for permission when it has not been decided yet.
  Future<LocationResult> current();

  /// Opens the app's settings page ([LocationProblem.deniedForever]).
  Future<void> openAppSettings();

  /// Opens the device location settings ([LocationProblem.serviceDisabled]).
  Future<void> openLocationSettings();
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static const _timeLimit = Duration(seconds: 15);

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationMissing(LocationProblem.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const LocationMissing(LocationProblem.denied);
        case LocationPermission.deniedForever:
          return const LocationMissing(LocationProblem.deniedForever);
        case LocationPermission.whileInUse ||
            LocationPermission.always ||
            LocationPermission.unableToDetermine:
          break;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _timeLimit),
      );
      return LocationFound(
        RoadPoint(lat: position.latitude, lng: position.longitude),
      );
    } on Exception {
      // Timeout, permission request already running, platform errors.
      return const LocationMissing(LocationProblem.unavailable);
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}

// ---- photos ----

enum PhotoSource { camera, gallery }

/// The camera or gallery could not be opened (e.g. camera permission refused).
class PhotoPickFailure implements Exception {
  const PhotoPickFailure(this.cause);

  final Object cause;

  @override
  String toString() => 'PhotoPickFailure($cause)';
}

/// Picks one photo, shrunk to [RoadLimits.photoMaxEdge] as JPEG. `null` when
/// the rider cancels; [PhotoPickFailure] when the picker cannot open.
abstract interface class PhotoPicker {
  Future<ReportPhoto?> pick(PhotoSource source);
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(ImagePicker()),
);

class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<ReportPhoto?> pick(PhotoSource source) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: switch (source) {
          PhotoSource.camera => ImageSource.camera,
          PhotoSource.gallery => ImageSource.gallery,
        },
        maxWidth: RoadLimits.photoMaxEdge,
        maxHeight: RoadLimits.photoMaxEdge,
        imageQuality: RoadLimits.photoQuality,
        requestFullMetadata: false,
      );
    } on PlatformException catch (e) {
      throw PhotoPickFailure(e);
    }
    if (file == null) return null;
    return ReportPhoto(bytes: await file.readAsBytes(), name: file.name);
  }
}
