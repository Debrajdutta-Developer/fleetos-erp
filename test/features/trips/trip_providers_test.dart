import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/vehicles/domain/vehicle_repository.dart';
import 'package:fleet_os_erp/features/vehicles/presentation/vehicle_providers.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_repository.dart';
import 'package:fleet_os_erp/features/finance/presentation/finance_providers.dart';
import 'package:fleet_os_erp/features/finance/domain/finance_transaction_entity.dart';

class MockTripRepository implements TripRepository {
  final List<TripEntity> trips;
  final List<AuditLogEntity> auditLogs = [];

  MockTripRepository({required this.trips});

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) {
    return Stream.value(trips);
  }

  @override
  Future<List<TripEntity>> getTrips(String companyId) async {
    return trips;
  }

  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async {
    try {
      return trips.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TripEntity> createTrip(
    String companyId,
    TripEntity trip,
    AuditLogEntity initialAuditLog,
  ) async {
    trips.add(trip);
    auditLogs.add(initialAuditLog);
    return trip;
  }

  @override
  Future<void> updateTripStatus(
    String companyId,
    String tripId,
    String newStatus,
    String changedByUserId,
    String changedByUserName, {
    String? notes,
  }) async {
    final idx = trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      trips[idx] = trips[idx].copyWith(status: newStatus);
    }
  }

  @override
  Future<void> deleteTrip(
    String companyId,
    String tripId,
    AuditLogEntity deleteAuditLog,
  ) async {
    final idx = trips.indexWhere((t) => t.id == tripId);
    if (idx != -1) {
      trips[idx] = trips[idx].copyWith(deletedAt: DateTime.now());
    }
    auditLogs.add(deleteAuditLog);
  }

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
    String companyId,
    String tripId,
  ) {
    return Stream.value(auditLogs.where((l) => l.entityId == tripId).toList());
  }
}

class MockVehicleRepository implements VehicleRepository {
  final List<VehicleEntity> vehicles;
  MockVehicleRepository({required this.vehicles});

  @override
  Stream<List<VehicleEntity>> watchVehicles(String companyId) =>
      Stream.value(vehicles);

  @override
  Future<List<VehicleEntity>> getVehicles(String companyId) async => vehicles;

  @override
  Future<VehicleEntity> createVehicle(
      String companyId, VehicleEntity vehicle) async {
    vehicles.add(vehicle);
    return vehicle;
  }

  @override
  Future<void> updateVehicle(String companyId, VehicleEntity vehicle) async {
    final idx = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (idx != -1) {
      vehicles[idx] = vehicle;
    }
  }

  @override
  Future<void> deleteVehicle(String companyId, String vehicleId) async {}

  @override
  Future<void> assignDriver(String companyId, String vehicleId,
      String? driverId, String? driverName) async {}

  @override
  Future<String> uploadComplianceDocument(
          String companyId, String vehicleId, String docType, file) async =>
      '';
}

class MockFinanceRepository implements FinanceRepository {
  final List<FinanceTransactionEntity> transactions = [];
  final List<AuditLogEntity> auditLogs = [];

  @override
  Stream<List<FinanceTransactionEntity>> watchTransactions(String companyId) =>
      Stream.value(transactions);

  @override
  Future<List<FinanceTransactionEntity>> getTransactions(
          String companyId) async =>
      transactions;

  @override
  Future<FinanceTransactionEntity?> getTransactionById(
          String companyId, String transactionId) async =>
      null;

  @override
  Future<FinanceTransactionEntity> createTransaction(String companyId,
      FinanceTransactionEntity transaction, AuditLogEntity auditLog) async {
    transactions.add(transaction);
    auditLogs.add(auditLog);
    return transaction;
  }

  @override
  Future<void> deleteTransaction(
      String companyId, String transactionId, AuditLogEntity auditLog) async {}

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForFinance(String companyId) =>
      Stream.value(auditLogs);
}

void main() {
  group('Trip Business Rules Tests', () {
    late VehicleEntity tValidVehicle;
    late VehicleEntity tExpiredInsuranceVehicle;
    late VehicleEntity tExpiredPucVehicle;
    late VehicleEntity tExpiredFitnessVehicle;
    late VehicleEntity tExpiredPermitVehicle;

    final now = DateTime.now();

    setUp(() {
      tValidVehicle = VehicleEntity(
        id: 'v_valid',
        vin: '12345',
        licensePlate: 'NY-884-OK',
        make: 'Volvo',
        model: 'VNL',
        year: 2023,
        status: 'active',
        fuelType: 'diesel',
        odometer: 1000,
        insuranceExpiry: now.add(const Duration(days: 30)),
        pucExpiry: now.add(const Duration(days: 30)),
        fitnessExpiry: now.add(const Duration(days: 30)),
        createdAt: now,
        updatedAt: now,
      );

      tExpiredInsuranceVehicle = tValidVehicle.copyWith(
        id: 'v_exp_ins',
        insuranceExpiry: now.subtract(const Duration(days: 1)),
      );

      tExpiredPucVehicle = tValidVehicle.copyWith(
        id: 'v_exp_puc',
        pucExpiry: now.subtract(const Duration(days: 1)),
      );

      tExpiredFitnessVehicle = tValidVehicle.copyWith(
        id: 'v_exp_fit',
        fitnessExpiry: now.subtract(const Duration(days: 1)),
      );

      tExpiredPermitVehicle = tValidVehicle.copyWith(id: 'v_exp_permit');
      // Explicitly set the mock permit to yesterday
      VehiclePermitValidator.setPermitExpiry(
        'v_exp_permit',
        now.subtract(const Duration(days: 1)),
      );
      // Set valid vehicle permit to next year
      VehiclePermitValidator.setPermitExpiry(
        'v_valid',
        now.add(const Duration(days: 365)),
      );
    });

    test('should block trip creation if insurance is expired', () async {
      final repository = MockTripRepository(trips: []);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          tripRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final controller = container.read(tripFormControllerProvider.notifier);
      final trip = TripEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: tExpiredInsuranceVehicle.id,
        vehicleLicensePlate: tExpiredInsuranceVehicle.licensePlate,
        driverId: 'driver_1',
        driverName: 'Robert Jenkins',
        customerId: 'cust_1',
        customerName: 'Walmart',
        pickupLocation: 'NY',
        deliveryLocation: 'BOS',
        cargoType: 'Coal',
        coalQuantity: 20,
        freightAmount: 1000,
        advancePayment: 200,
        permitExpense: 0,
        status: 'scheduled',
        statusHistory: [],
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveTrip(
        trip,
        selectedVehicle: tExpiredInsuranceVehicle,
      );
      final formState = container.read(tripFormControllerProvider);

      expect(result, false);
      expect(formState.errorMessage, contains('insurance is expired'));
      expect(repository.trips.length, 0);
    });

    test('should block trip creation if PUC is expired', () async {
      final repository = MockTripRepository(trips: []);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          tripRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final controller = container.read(tripFormControllerProvider.notifier);
      final trip = TripEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: tExpiredPucVehicle.id,
        vehicleLicensePlate: tExpiredPucVehicle.licensePlate,
        driverId: 'driver_1',
        driverName: 'Robert Jenkins',
        customerId: 'cust_1',
        customerName: 'Walmart',
        pickupLocation: 'NY',
        deliveryLocation: 'BOS',
        cargoType: 'Coal',
        coalQuantity: 20,
        freightAmount: 1000,
        advancePayment: 200,
        permitExpense: 0,
        status: 'scheduled',
        statusHistory: [],
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveTrip(
        trip,
        selectedVehicle: tExpiredPucVehicle,
      );
      final formState = container.read(tripFormControllerProvider);

      expect(result, false);
      expect(formState.errorMessage, contains('PUC compliance is expired'));
      expect(repository.trips.length, 0);
    });

    test('should block trip creation if fitness is expired', () async {
      final repository = MockTripRepository(trips: []);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          tripRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final controller = container.read(tripFormControllerProvider.notifier);
      final trip = TripEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: tExpiredFitnessVehicle.id,
        vehicleLicensePlate: tExpiredFitnessVehicle.licensePlate,
        driverId: 'driver_1',
        driverName: 'Robert Jenkins',
        customerId: 'cust_1',
        customerName: 'Walmart',
        pickupLocation: 'NY',
        deliveryLocation: 'BOS',
        cargoType: 'Coal',
        coalQuantity: 20,
        freightAmount: 1000,
        advancePayment: 200,
        permitExpense: 0,
        status: 'scheduled',
        statusHistory: [],
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveTrip(
        trip,
        selectedVehicle: tExpiredFitnessVehicle,
      );
      final formState = container.read(tripFormControllerProvider);

      expect(result, false);
      expect(
        formState.errorMessage,
        contains('fitness certificate is expired'),
      );
      expect(repository.trips.length, 0);
    });

    test('should block trip creation if road permit is expired', () async {
      final repository = MockTripRepository(trips: []);
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => UserEntity(
              uid: 'user_1',
              email: 'test@company.com',
              displayName: 'Operator John',
              role: 'admin',
              companyId: 'comp_1',
              createdAt: DateTime.now(),
            ),
          ),
          tripRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final controller = container.read(tripFormControllerProvider.notifier);
      final trip = TripEntity(
        id: '',
        companyId: 'comp_1',
        vehicleId: tExpiredPermitVehicle.id,
        vehicleLicensePlate: tExpiredPermitVehicle.licensePlate,
        driverId: 'driver_1',
        driverName: 'Robert Jenkins',
        customerId: 'cust_1',
        customerName: 'Walmart',
        pickupLocation: 'NY',
        deliveryLocation: 'BOS',
        cargoType: 'Coal',
        coalQuantity: 20,
        freightAmount: 1000,
        advancePayment: 200,
        permitExpense: 0,
        status: 'scheduled',
        statusHistory: [],
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveTrip(
        trip,
        selectedVehicle: tExpiredPermitVehicle,
      );
      final formState = container.read(tripFormControllerProvider);

      expect(result, false);
      expect(formState.errorMessage, contains('permit is expired'));
      expect(repository.trips.length, 0);
    });

    test(
      'should block trip creation if selected vehicle is already on another active trip',
      () async {
        final existingActiveTrip = TripEntity(
          id: 't_active',
          companyId: 'comp_1',
          vehicleId: 'v_valid',
          vehicleLicensePlate: 'NY-884-OK',
          driverId: 'driver_another',
          driverName: 'Sarah Connor',
          customerId: 'cust_2',
          customerName: 'Amazon',
          pickupLocation: 'LA',
          deliveryLocation: 'SFO',
          cargoType: 'Electronics',
          coalQuantity: 0,
          freightAmount: 800,
          advancePayment: 100,
          permitExpense: 0,
          status: 'inTransit', // Active status
          statusHistory: [],
          createdAt: now,
          updatedAt: now,
        );

        final repository = MockTripRepository(trips: [existingActiveTrip]);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => UserEntity(
                uid: 'user_1',
                email: 'test@company.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'comp_1',
                createdAt: DateTime.now(),
              ),
            ),
            tripRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final controller = container.read(tripFormControllerProvider.notifier);
        final trip = TripEntity(
          id: '',
          companyId: 'comp_1',
          vehicleId: 'v_valid',
          vehicleLicensePlate: 'NY-884-OK',
          driverId: 'driver_1',
          driverName: 'Robert Jenkins',
          customerId: 'cust_1',
          customerName: 'Walmart',
          pickupLocation: 'NY',
          deliveryLocation: 'BOS',
          cargoType: 'Coal',
          coalQuantity: 20,
          freightAmount: 1000,
          advancePayment: 200,
          permitExpense: 0,
          status: 'scheduled',
          statusHistory: [],
          createdAt: now,
          updatedAt: now,
        );

        final result = await controller.saveTrip(
          trip,
          selectedVehicle: tValidVehicle,
        );
        final formState = container.read(tripFormControllerProvider);

        expect(result, false);
        expect(
          formState.errorMessage,
          contains('is already assigned to another active trip'),
        );
        expect(repository.trips.length, 1);
      },
    );

    test(
      'should block trip creation if selected driver is already on another active trip',
      () async {
        final existingActiveTrip = TripEntity(
          id: 't_active',
          companyId: 'comp_1',
          vehicleId: 'v_another',
          vehicleLicensePlate: 'NY-884-OTHER',
          driverId: 'driver_1',
          driverName: 'Robert Jenkins',
          customerId: 'cust_2',
          customerName: 'Amazon',
          pickupLocation: 'LA',
          deliveryLocation: 'SFO',
          cargoType: 'Electronics',
          coalQuantity: 0,
          freightAmount: 800,
          advancePayment: 100,
          permitExpense: 0,
          status: 'loading', // Active status
          statusHistory: [],
          createdAt: now,
          updatedAt: now,
        );

        final repository = MockTripRepository(trips: [existingActiveTrip]);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => UserEntity(
                uid: 'user_1',
                email: 'test@company.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'comp_1',
                createdAt: DateTime.now(),
              ),
            ),
            tripRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final controller = container.read(tripFormControllerProvider.notifier);
        final trip = TripEntity(
          id: '',
          companyId: 'comp_1',
          vehicleId: 'v_valid',
          vehicleLicensePlate: 'NY-884-OK',
          driverId: 'driver_1',
          driverName: 'Robert Jenkins',
          customerId: 'cust_1',
          customerName: 'Walmart',
          pickupLocation: 'NY',
          deliveryLocation: 'BOS',
          cargoType: 'Coal',
          coalQuantity: 20,
          freightAmount: 1000,
          advancePayment: 200,
          permitExpense: 0,
          status: 'scheduled',
          statusHistory: [],
          createdAt: now,
          updatedAt: now,
        );

        final result = await controller.saveTrip(
          trip,
          selectedVehicle: tValidVehicle,
        );
        final formState = container.read(tripFormControllerProvider);

        expect(result, false);
        expect(
          formState.errorMessage,
          contains('is already assigned to another active trip'),
        );
        expect(repository.trips.length, 1);
      },
    );

    test(
      'should succeed saving trip if resources are valid and unassigned',
      () async {
        final repository = MockTripRepository(trips: []);
        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => UserEntity(
                uid: 'user_1',
                email: 'test@company.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'comp_1',
                createdAt: DateTime.now(),
              ),
            ),
            tripRepositoryProvider.overrideWithValue(repository),
          ],
        );

        final controller = container.read(tripFormControllerProvider.notifier);
        final trip = TripEntity(
          id: 't_ok',
          companyId: 'comp_1',
          vehicleId: 'v_valid',
          vehicleLicensePlate: 'NY-884-OK',
          driverId: 'driver_1',
          driverName: 'Robert Jenkins',
          customerId: 'cust_1',
          customerName: 'Walmart',
          pickupLocation: 'NY',
          deliveryLocation: 'BOS',
          cargoType: 'Coal',
          coalQuantity: 20,
          freightAmount: 1000,
          advancePayment: 200,
          permitExpense: 0,
          status: 'scheduled',
          statusHistory: [],
          createdAt: now,
          updatedAt: now,
        );

        final result = await controller.saveTrip(
          trip,
          selectedVehicle: tValidVehicle,
        );
        final formState = container.read(tripFormControllerProvider);

        expect(result, true);
        expect(formState.errorMessage, isNull);
        expect(repository.trips.length, 1);
        expect(repository.trips[0].id, 't_ok');
        expect(repository.auditLogs.length, 1);
        expect(repository.auditLogs[0].action, 'trip_created');
        expect(repository.auditLogs[0].userName, 'Operator John');
      },
    );

    test(
      'should update vehicle status and generate finance transactions when trip is completed',
      () async {
        final existingTrip = TripEntity(
          id: 't_completeme',
          companyId: 'comp_1',
          vehicleId: 'v_valid',
          vehicleLicensePlate: 'NY-884-OK',
          driverId: 'driver_1',
          driverName: 'Robert Jenkins',
          customerId: 'cust_1',
          customerName: 'Walmart',
          pickupLocation: 'NY',
          deliveryLocation: 'BOS',
          cargoType: 'Coal',
          coalQuantity: 20,
          freightAmount: 1000.0,
          advancePayment: 200.0,
          permitExpense: 50.0,
          status: 'inTransit',
          statusHistory: [],
          createdAt: now,
          updatedAt: now,
        );

        final tripRepository = MockTripRepository(trips: [existingTrip]);
        final vehicleRepository = MockVehicleRepository(vehicles: [
          tValidVehicle.copyWith(status: 'inTransit'),
        ]);
        final financeRepository = MockFinanceRepository();

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith(
              (ref) => UserEntity(
                uid: 'user_1',
                email: 'test@company.com',
                displayName: 'Operator John',
                role: 'admin',
                companyId: 'comp_1',
                createdAt: DateTime.now(),
              ),
            ),
            tripRepositoryProvider.overrideWithValue(tripRepository),
            vehicleRepositoryProvider.overrideWithValue(vehicleRepository),
            financeRepositoryProvider.overrideWithValue(financeRepository),
          ],
        );

        final controller = container.read(tripListControllerProvider.notifier);

        final result =
            await controller.updateStatus('t_completeme', 'completed');
        expect(result, true);

        // 1. Verify vehicle status became active
        expect(vehicleRepository.vehicles[0].status, 'active');

        // 2. Verify finance transactions generated
        expect(financeRepository.transactions.length, 3);

        // Revenue (income)
        final incomeTx = financeRepository.transactions
            .firstWhere((t) => t.type == 'income');
        expect(incomeTx.amount, 1000.0);
        expect(incomeTx.category, 'income');

        // Advance Payment (expense)
        final advTx = financeRepository.transactions
            .firstWhere((t) => t.category == 'advance_salary');
        expect(advTx.amount, 200.0);
        expect(advTx.type, 'expense');

        // Permit (expense)
        final permitTx = financeRepository.transactions
            .firstWhere((t) => t.category == 'miscellaneous');
        expect(permitTx.amount, 50.0);
        expect(permitTx.type, 'expense');
      },
    );
  });
}
