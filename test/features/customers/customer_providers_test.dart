import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_os_erp/features/auth/presentation/auth_providers.dart';
import 'package:fleet_os_erp/features/auth/domain/user_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_entity.dart';
import 'package:fleet_os_erp/features/customers/domain/customer_repository.dart';
import 'package:fleet_os_erp/features/customers/presentation/customer_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_repository.dart';
import 'package:fleet_os_erp/features/trips/presentation/trip_providers.dart';
import 'package:fleet_os_erp/features/trips/domain/trip_entity.dart';
import 'package:fleet_os_erp/features/trips/domain/audit_log_entity.dart';

class MockCustomerRepository implements CustomerRepository {
  final List<CustomerEntity> customers;
  MockCustomerRepository({required this.customers});

  @override
  Stream<List<CustomerEntity>> watchCustomers(String companyId) =>
      Stream.value(customers);

  @override
  Future<List<CustomerEntity>> getCustomers(String companyId) async =>
      customers;

  @override
  Future<CustomerEntity?> getCustomerById(
      String companyId, String customerId) async {
    try {
      return customers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CustomerEntity> createCustomer(
      String companyId, CustomerEntity customer) async {
    customers.add(customer);
    return customer;
  }

  @override
  Future<void> updateCustomer(String companyId, CustomerEntity customer) async {
    final idx = customers.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      customers[idx] = customer;
    }
  }

  @override
  Future<void> deleteCustomer(String companyId, String customerId) async {
    final idx = customers.indexWhere((c) => c.id == customerId);
    if (idx != -1) {
      customers[idx] = customers[idx].copyWith(deletedAt: DateTime.now());
    }
  }
}

class MockTripRepository implements TripRepository {
  final List<AuditLogEntity> auditLogs = [];

  @override
  Stream<List<TripEntity>> watchTrips(String companyId) => Stream.value([]);

  @override
  Future<List<TripEntity>> getTrips(String companyId) async => [];

  @override
  Future<TripEntity?> getTripById(String companyId, String tripId) async =>
      null;

  @override
  Future<TripEntity> createTrip(
      String companyId, TripEntity trip, AuditLogEntity initialAuditLog) async {
    auditLogs.add(initialAuditLog);
    return trip;
  }

  @override
  Future<void> updateTripStatus(String companyId, String tripId,
      String newStatus, String cbId, String cbName,
      {String? notes}) async {}

  @override
  Future<void> deleteTrip(
      String companyId, String tripId, AuditLogEntity deleteAuditLog) async {}

  @override
  Stream<List<AuditLogEntity>> watchAuditLogsForTrip(
          String companyId, String tripId) =>
      Stream.value([]);

  @override
  Stream<List<AuditLogEntity>> watchAuditLogs(String companyId) =>
      Stream.value(auditLogs);
}

void main() {
  group('Customer Providers Business Logic Tests', () {
    final now = DateTime.now();
    final tCustomers = [
      CustomerEntity(
        id: 'cust_1',
        name: 'Walmart Fulfillment',
        contactName: 'Alice',
        phone: '1234567890',
        email: 'alice@walmart.com',
        address: 'Bentonville',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('should save customer and write audit logs successfully', () async {
      final customerRepo =
          MockCustomerRepository(customers: List.from(tCustomers));
      final tripRepo = MockTripRepository();

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
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller =
          container.read(customerFormControllerProvider.notifier);
      final newCustomer = CustomerEntity(
        id: '',
        name: 'Amazon Retail Inc.',
        contactName: 'Bob',
        phone: '0987654321',
        email: 'bob@amazon.com',
        address: 'Seattle',
        createdAt: now,
        updatedAt: now,
      );

      final result = await controller.saveCustomer(newCustomer);

      expect(result, true);
      expect(customerRepo.customers.length, 2);
      expect(customerRepo.customers[1].name, 'Amazon Retail Inc.');
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'customer_created');
    });

    test('should soft-delete customer and write delete audit log successfully',
        () async {
      final customerRepo =
          MockCustomerRepository(customers: List.from(tCustomers));
      final tripRepo = MockTripRepository();

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
          customerRepositoryProvider.overrideWithValue(customerRepo),
          tripRepositoryProvider.overrideWithValue(tripRepo),
        ],
      );

      final controller =
          container.read(customerListControllerProvider.notifier);
      final result = await controller.deleteCustomer('cust_1');

      expect(result, true);
      expect(customerRepo.customers[0].deletedAt, isNotNull);
      expect(tripRepo.auditLogs.length, 1);
      expect(tripRepo.auditLogs[0].action, 'customer_deleted');
    });
  });
}
