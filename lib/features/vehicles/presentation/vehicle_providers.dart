import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/vehicle_repository_impl.dart';
import '../domain/vehicle_entity.dart';
import '../domain/vehicle_repository.dart';

/// Provider for VehicleRepository.
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl();
});

/// StreamProvider listening to real-time active fleet changes.
final vehiclesStreamProvider = StreamProvider.autoDispose<List<VehicleEntity>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user?.companyId == null) return Stream.value([]);
  return ref.watch(vehicleRepositoryProvider).watchVehicles(user!.companyId!);
});

/// UI State for Vehicle Form operations.
class VehicleFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;

  const VehicleFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  VehicleFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return VehicleFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Controller overseeing Vehicle Add/Edit actions and compliance document uploads.
class VehicleFormController extends StateNotifier<VehicleFormState> {
  final VehicleRepository _repository;
  final Ref _ref;

  VehicleFormController({
    required VehicleRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const VehicleFormState());

  /// Create new vehicle asset
  Future<bool> saveVehicle(VehicleEntity vehicle) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      if (vehicle.id.isEmpty) {
        await _repository.createVehicle(user!.companyId!, vehicle);
      } else {
        await _repository.updateVehicle(user!.companyId!, vehicle);
      }

      state = const VehicleFormState(isCompleted: true);
      return true;
    } catch (e) {
      state = VehicleFormState(errorMessage: e.toString());
      return false;
    }
  }

  /// Upload compliance document
  Future<String?> uploadDocument({
    required String vehicleId,
    required String docType, // insurance, puc, fitness
    required File file,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      final downloadUrl = await _repository.uploadComplianceDocument(
        user!.companyId!,
        vehicleId,
        docType,
        file,
      );

      state = const VehicleFormState();
      return downloadUrl;
    } catch (e) {
      state = VehicleFormState(errorMessage: e.toString());
      return null;
    }
  }
}

/// Provider for VehicleFormController.
final vehicleFormControllerProvider =
    StateNotifierProvider.autoDispose<VehicleFormController, VehicleFormState>((
  ref,
) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleFormController(repository: repository, ref: ref);
});

/// Controller overseeing Vehicle List actions, searches, filters, and deletes.
class VehicleListController extends StateNotifier<AsyncValue<void>> {
  final VehicleRepository _repository;
  final Ref _ref;

  VehicleListController({
    required VehicleRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  /// Soft deletes vehicle record by setting deletedAt
  Future<bool> deleteVehicle(String vehicleId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      await _repository.deleteVehicle(user!.companyId!, vehicleId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Link or unlink primary driver to vehicle
  Future<bool> assignDriver(
    String vehicleId,
    String? driverId,
    String? driverName,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user?.companyId == null) throw Exception('No company authenticated.');

      await _repository.assignDriver(
        user!.companyId!,
        vehicleId,
        driverId,
        driverName,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Provider for VehicleListController.
final vehicleListControllerProvider =
    StateNotifierProvider.autoDispose<VehicleListController, AsyncValue<void>>((
  ref,
) {
  final repository = ref.watch(vehicleRepositoryProvider);
  return VehicleListController(repository: repository, ref: ref);
});

/// Compliance Helper utility functions to check expiry states.
class VehicleComplianceHelper {
  /// Checks if insurance is expired
  static bool isInsuranceExpired(VehicleEntity vehicle) {
    return vehicle.insuranceExpiry.isBefore(DateTime.now());
  }

  /// Checks if insurance requires renewal warning (30 days prior)
  static bool isInsuranceWarning(VehicleEntity vehicle) {
    final diff = vehicle.insuranceExpiry.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  /// Checks if PUC is expired
  static bool isPucExpired(VehicleEntity vehicle) {
    return vehicle.pucExpiry.isBefore(DateTime.now());
  }

  /// Checks if PUC requires renewal warning
  static bool isPucWarning(VehicleEntity vehicle) {
    final diff = vehicle.pucExpiry.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 15;
  }

  /// Checks if Fitness Certificate is expired
  static bool isFitnessExpired(VehicleEntity vehicle) {
    return vehicle.fitnessExpiry.isBefore(DateTime.now());
  }

  /// Checks if Fitness requires renewal warning
  static bool isFitnessWarning(VehicleEntity vehicle) {
    final diff = vehicle.fitnessExpiry.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 30;
  }

  /// Checks if preventative service is overdue (e.g. last service was >180 days ago)
  static bool isServiceOverdue(VehicleEntity vehicle) {
    if (vehicle.lastServiceDate == null) return true;
    final diff = DateTime.now().difference(vehicle.lastServiceDate!).inDays;
    return diff > 180;
  }
}
