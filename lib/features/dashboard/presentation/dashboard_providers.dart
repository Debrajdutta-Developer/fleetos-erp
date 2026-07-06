import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/presentation/vehicle_providers.dart';
import '../../trips/presentation/trip_providers.dart';
import '../../vehicles/domain/vehicle_entity.dart';
import '../../trips/domain/trip_entity.dart';

class DashboardStats {
  final int activeFleetCount;
  final int tripsScheduled;
  final int criticalDiagnosticsCount;
  final double averagePayloadCapacity;

  const DashboardStats({
    required this.activeFleetCount,
    required this.tripsScheduled,
    required this.criticalDiagnosticsCount,
    required this.averagePayloadCapacity,
  });
}

final dashboardStatsProvider =
    Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesStreamProvider);
  final tripsAsync = ref.watch(tripsStreamProvider);

  if (vehiclesAsync.isLoading || tripsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (vehiclesAsync.hasError) {
    return AsyncValue.error(vehiclesAsync.error!, vehiclesAsync.stackTrace!);
  }
  if (tripsAsync.hasError) {
    return AsyncValue.error(tripsAsync.error!, tripsAsync.stackTrace!);
  }

  final vehicles = vehiclesAsync.value ?? [];
  final trips = tripsAsync.value ?? [];

  // 1. Active Fleet Count
  final activeFleetCount = vehicles.where((v) => v.status == 'active').length;

  // 2. Trips Scheduled
  final tripsScheduled = trips
      .where((t) => t.status == 'scheduled' || t.status == 'planned')
      .length;

  // 3. Critical Diagnostics (Vehicles with expired compliance)
  final criticalDiagnosticsCount = vehicles.where((v) {
    return VehicleComplianceHelper.isInsuranceExpired(v) ||
        VehicleComplianceHelper.isPucExpired(v) ||
        VehicleComplianceHelper.isFitnessExpired(v);
  }).length;

  // 4. Active Cargo Volume / Average payload capacity
  final activeTrips =
      trips.where((t) => t.status != 'completed' && t.status != 'cancelled');
  double averagePayloadCapacity = 0.0;
  if (activeTrips.isNotEmpty) {
    final totalCoal = activeTrips
        .map((t) => t.coalQuantity)
        .fold<double>(0.0, (sum, val) => sum + val);
    // Assume standard payload capacity of 25.0 tons per vehicle
    averagePayloadCapacity = (totalCoal / (activeTrips.length * 25.0)) * 100;
    if (averagePayloadCapacity > 100.0) averagePayloadCapacity = 100.0;
  }

  return AsyncValue.data(DashboardStats(
    activeFleetCount: activeFleetCount,
    tripsScheduled: tripsScheduled,
    criticalDiagnosticsCount: criticalDiagnosticsCount,
    averagePayloadCapacity: averagePayloadCapacity,
  ));
});
