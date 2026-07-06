import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../vehicles/domain/vehicle_entity.dart';
import '../data/trip_repository_impl.dart';
import '../domain/trip_entity.dart';
import '../domain/audit_log_entity.dart';
import '../domain/trip_repository.dart';

/// Provider for TripRepository.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl();
});

/// StreamProvider listening to real-time active trips list.
final tripsStreamProvider = StreamProvider.autoDispose<List<TripEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(tripRepositoryProvider).watchTrips(user!.companyId!);
});

/// StreamProvider listening to a specific trip by ID.
final tripDetailsStreamProvider = StreamProvider.family.autoDispose<TripEntity?, String>((ref, tripId) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value(null);
  
  // Return a stream that monitors all trips and filters down to the specified ID.
  // This supports real-time reactivity for status transitions.
  return ref.watch(tripRepositoryProvider).watchTrips(user!.companyId!).map((list) {
    try {
      return list.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return null;
    }
  });
});

/// StreamProvider listening to audit logs for a specific trip.
final tripAuditLogsStreamProvider = StreamProvider.family.autoDispose<List<AuditLogEntity>, String>((ref, tripId) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(tripRepositoryProvider).watchAuditLogsForTrip(user!.companyId!, tripId);
});

/// UI State for Trip Form operations.
class TripFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const TripFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  TripFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return TripFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Helper utility for mock vehicle permits expiry to enforce the rule: "Expired permit blocks trip creation".
class VehiclePermitValidator {
  static final Map<String, DateTime> _mockPermitExpiries = {};

  static DateTime getPermitExpiry(String vehicleId) {
    // If not set, default to a future date so the vehicle is valid.
    return _mockPermitExpiries[vehicleId] ?? DateTime.now().add(const Duration(days: 365));
  }

  static void setPermitExpiry(String vehicleId, DateTime expiry) {
    _mockPermitExpiries[vehicleId] = expiry;
  }

  static bool isPermitExpired(String vehicleId) {
    return getPermitExpiry(vehicleId).isBefore(DateTime.now());
  }
}

/// Controller overseeing Trip Add/Edit actions and business rules validation.
class TripFormController extends StateNotifier<TripFormState> {
  final TripRepository _repository;
  final Ref _ref;

  TripFormController({
    required TripRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const TripFormState());

  /// Create or update a trip with business rules validations
  Future<bool> saveTrip(TripEntity trip, {VehicleEntity? selectedVehicle}) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');
      final companyId = user!.companyId!;

      // 1. Validation Rule: Expired insurance, PUC, fitness, or permit must block trip creation.
      if (selectedVehicle != null) {
        final now = DateTime.now();
        
        if (selectedVehicle.insuranceExpiry.isBefore(now)) {
          throw Exception('Validation Blocked: Assigned vehicle insurance is expired (${selectedVehicle.insuranceExpiry.toLocal().toString().split(' ')[0]}).');
        }
        if (selectedVehicle.pucExpiry.isBefore(now)) {
          throw Exception('Validation Blocked: Assigned vehicle PUC compliance is expired (${selectedVehicle.pucExpiry.toLocal().toString().split(' ')[0]}).');
        }
        if (selectedVehicle.fitnessExpiry.isBefore(now)) {
          throw Exception('Validation Blocked: Assigned vehicle fitness certificate is expired (${selectedVehicle.fitnessExpiry.toLocal().toString().split(' ')[0]}).');
        }
        if (VehiclePermitValidator.isPermitExpired(selectedVehicle.id)) {
          final permitExpiry = VehiclePermitValidator.getPermitExpiry(selectedVehicle.id);
          throw Exception('Validation Blocked: Assigned vehicle permit is expired (${permitExpiry.toLocal().toString().split(' ')[0]}).');
        }
      }

      // 2. Fetch trips list to evaluate active trip concurrency business rules
      final allTrips = await _repository.getTrips(companyId);
      
      // Active trips are those whose status is not completed or cancelled, excluding current trip if editing
      final activeTrips = allTrips.where((t) => 
          t.status != 'completed' && 
          t.status != 'cancelled' && 
          t.id != trip.id);

      // Business Rule: A vehicle cannot have two active trips.
      if (activeTrips.any((t) => t.vehicleId == trip.vehicleId)) {
        throw Exception('Validation Blocked: Vehicle ${trip.vehicleLicensePlate} is already assigned to another active trip.');
      }

      // Business Rule: A driver cannot have two active trips.
      if (activeTrips.any((t) => t.driverId == trip.driverId)) {
        throw Exception('Validation Blocked: Driver ${trip.driverName} is already assigned to another active trip.');
      }

      // Create initial audit log
      final auditLog = AuditLogEntity(
        id: '',
        companyId: companyId,
        entityType: 'trip',
        entityId: trip.id,
        action: trip.id.isEmpty ? 'trip_created' : 'trip_updated',
        description: trip.id.isEmpty
            ? 'Trip created and scheduled for Vehicle ${trip.vehicleLicensePlate} with Driver ${trip.driverName}.'
            : 'Trip information updated.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await _repository.createTrip(companyId, trip, auditLog);

      state = const TripFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = TripFormState(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

/// Provider for TripFormController.
final tripFormControllerProvider =
    StateNotifierProvider.autoDispose<TripFormController, TripFormState>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return TripFormController(repository: repository, ref: ref);
});

/// Controller overseeing Trip actions: status transitions and deletions.
class TripListController extends StateNotifier<AsyncValue<void>> {
  final TripRepository _repository;
  final Ref _ref;

  TripListController({
    required TripRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Transition a trip status, updating status history and recording an audit log
  Future<bool> updateStatus(String tripId, String newStatus, {String? notes}) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      await _repository.updateTripStatus(
        user!.companyId!,
        tripId,
        newStatus,
        user.uid,
        user.displayName.isEmpty ? 'Operator' : user.displayName,
        notes: notes,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Soft deletes a trip, recording a deleted action audit log
  Future<bool> deleteTrip(String tripId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      final deleteAuditLog = AuditLogEntity(
        id: '',
        companyId: user!.companyId!,
        entityType: 'trip',
        entityId: tripId,
        action: 'trip_deleted',
        description: 'Trip $tripId was soft-deleted by user.',
        userId: user.uid,
        userName: user.displayName.isEmpty ? 'Operator' : user.displayName,
        timestamp: DateTime.now(),
      );

      await _repository.deleteTrip(user.companyId!, tripId, deleteAuditLog);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for TripListController.
final tripListControllerProvider =
    StateNotifierProvider.autoDispose<TripListController, AsyncValue<void>>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return TripListController(repository: repository, ref: ref);
});
