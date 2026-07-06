import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';

void main() {
  group('VehicleComplianceHelper Tests', () {
    final tActiveVehicle = VehicleEntity(
      id: 'v_1',
      vin: '12345678901234567',
      licensePlate: 'NY-884-AB',
      make: 'Volvo',
      model: 'VNL 860',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 100.0,
      lastServiceDate: DateTime.now().subtract(const Duration(days: 30)),
      insuranceExpiry: DateTime.now().add(const Duration(days: 45)), // Valid
      pucExpiry: DateTime.now().add(const Duration(days: 20)),      // Valid
      fitnessExpiry: DateTime.now().add(const Duration(days: 60)),  // Valid
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final tExpiredVehicle = VehicleEntity(
      id: 'v_2',
      vin: '12345678901234567',
      licensePlate: 'NY-884-AC',
      make: 'Volvo',
      model: 'VNL 860',
      year: 2023,
      status: 'active',
      fuelType: 'diesel',
      odometer: 200.0,
      lastServiceDate: DateTime.now().subtract(const Duration(days: 200)), // Overdue
      insuranceExpiry: DateTime.now().subtract(const Duration(days: 2)),  // Expired
      pucExpiry: DateTime.now().subtract(const Duration(days: 5)),       // Expired
      fitnessExpiry: DateTime.now().subtract(const Duration(days: 10)),   // Expired
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should validate active non-expired documents correctly', () {
      expect(VehicleComplianceHelper.isInsuranceExpired(tActiveVehicle), false);
      expect(VehicleComplianceHelper.isPucExpired(tActiveVehicle), false);
      expect(VehicleComplianceHelper.isFitnessExpired(tActiveVehicle), false);
      expect(VehicleComplianceHelper.isServiceOverdue(tActiveVehicle), false);
    });

    test('should detect expired compliance documents correctly', () {
      expect(VehicleComplianceHelper.isInsuranceExpired(tExpiredVehicle), true);
      expect(VehicleComplianceHelper.isPucExpired(tExpiredVehicle), true);
      expect(VehicleComplianceHelper.isFitnessExpired(tExpiredVehicle), true);
      expect(VehicleComplianceHelper.isServiceOverdue(tExpiredVehicle), true);
    });

    test('should identify document warning thresholds correctly', () {
      final warningVehicle = tActiveVehicle.copyWith(
        insuranceExpiry: DateTime.now().add(const Duration(days: 10)), // Warning (0-30 days)
        pucExpiry: DateTime.now().add(const Duration(days: 5)),        // Warning (0-15 days)
      );
      expect(VehicleComplianceHelper.isInsuranceWarning(warningVehicle), true);
      expect(VehicleComplianceHelper.isPucWarning(warningVehicle), true);
    });
  });
}
