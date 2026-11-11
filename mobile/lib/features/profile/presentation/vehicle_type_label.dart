import '../../../l10n/app_localizations.dart';
import '../domain/rider_profile.dart';

String vehicleTypeLabel(AppLocalizations l10n, VehicleType type) =>
    switch (type) {
      VehicleType.motorcycle => l10n.vehicleMotorcycle,
      VehicleType.evMotorcycle => l10n.vehicleEvMotorcycle,
      VehicleType.bicycle => l10n.vehicleBicycle,
      VehicleType.car => l10n.vehicleCar,
      VehicleType.other => l10n.vehicleOther,
    };
