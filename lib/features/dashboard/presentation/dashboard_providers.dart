import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../presentation/dashboard_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../drivers/domain/driver_entity.dart';

class DashboardStats {
  final int activeFleetCount;
  final int tripsScheduled;
  final int criticalDiagnosticsCount;
  final double averagePayloadCapacity;
  final int totalDriversCount;
  final int availableDriversCount;
  final int expiredLicenseDriversCount;

  const DashboardStats({
    required this.activeFleetCount,
    required this.tripsScheduled,
    required this.criticalDiagnosticsCount,
    required this.averagePayloadCapacity,
    required this.totalDriversCount,
    required this.availableDriversCount,
    required this.expiredLicenseDriversCount,
  });
}

final dashboardStatsProvider = Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesStreamProvider);
  final tripsAsync = ref.watch(tripsStreamProvider);
  final driversAsync = ref.watch(driversStreamProvider);

  if (vehiclesAsync.isLoading || tripsAsync.isLoading || driversAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (vehiclesAsync.hasError) {
    return AsyncValue.error(vehiclesAsync.error!, vehiclesAsync.stackTrace!);
  }
  if (tripsAsync.hasError) {
    return AsyncValue.error(tripsAsync.error!, tripsAsync.stackTrace!);
  }
  if (driversAsync.hasError) {
    return AsyncValue.error(driversAsync.error!, driversAsync.stackTrace!);
  }

  final vehicles = vehiclesAsync.value ?? [];
  final trips = tripsAsync.value ?? [];
  final drivers = driversAsync.value ?? [];

  // 1. Active Fleet Count
  final activeFleetCount = vehicles.where((v) => v.status == 'active').length;

  // 2. Trips Scheduled
  final tripsScheduled = trips.where((t) => t.status == 'scheduled' || t.status == 'planned').length;

  // 3. Critical Diagnostics (Vehicles with expired compliance)
  final criticalDiagnosticsCount = vehicles.where((v) {
    return VehicleComplianceHelper.isInsuranceExpired(v) ||
        VehicleComplianceHelper.isPucExpired(v) ||
        VehicleComplianceHelper.isFitnessExpired(v);
  }).length;

  // 4. Active Cargo Volume / Average payload capacity
  final activeTrips = trips.where((t) => t.status != 'completed' && t.status != 'cancelled');
  double averagePayloadCapacity = 0.0;
  if (activeTrips.isNotEmpty) {
    final totalCoal = activeTrips.map((t) => t.coalQuantity).fold<double>(0.0, (sum, val) => sum + val);
    averagePayloadCapacity = (totalCoal / (activeTrips.length * 25.0)) * 100;
    if (averagePayloadCapacity > 100.0) averagePayloadCapacity = 100.0;
  }

  // 5. Driver Statistics
  final totalDriversCount = drivers.length;
  final availableDriversCount = drivers.where((d) => d.status == 'available').length;
  final expiredLicenseDriversCount = drivers.where((d) => d.licenseExpiry.isBefore(DateTime.now())).length;

  return AsyncValue.data(DashboardStats(
    activeFleetCount: activeFleetCount,
    tripsScheduled: tripsScheduled,
    criticalDiagnosticsCount: criticalDiagnosticsCount,
    averagePayloadCapacity: averagePayloadCapacity,
    totalDriversCount: totalDriversCount,
    availableDriversCount: availableDriversCount,
    expiredLicenseDriversCount: expiredLicenseDriversCount,
  ));
});
