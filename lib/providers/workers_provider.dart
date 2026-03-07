import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/worker_service.dart';

final workersProvider =
    StateNotifierProvider<WorkersNotifier, AsyncValue<List<UserModel>>>((ref) {
  return WorkersNotifier();
});

class WorkersNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final WorkerService _workerService = WorkerService();

  WorkersNotifier() : super(const AsyncValue.loading());

  // Load all workers
  Future<void> loadAllWorkers() async {
    state = const AsyncValue.loading();
    try {
      final workers = await _workerService.getAllWorkers();
      state = AsyncValue.data(workers);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Load active workers only
  Future<void> loadActiveWorkers() async {
    state = const AsyncValue.loading();
    try {
      final workers = await _workerService.getActiveWorkers();
      state = AsyncValue.data(workers);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Add worker
  Future<UserModel?> addWorker({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final newWorker = await _workerService.addWorker(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      // Update state with new worker
      final currentWorkers = state.maybeWhen(
        data: (workers) => [...workers],
        orElse: () => <UserModel>[],
      );

      state = AsyncValue.data([newWorker, ...currentWorkers]);
      return newWorker;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Update worker
  Future<UserModel?> updateWorker({
    required String workerId,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? isActive,
  }) async {
    try {
      final updatedWorker = await _workerService.updateWorker(
        workerId: workerId,
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
        avatarUrl: avatarUrl,
        isActive: isActive,
      );

      // Update state
      final currentWorkers = state.maybeWhen(
        data: (workers) => [...workers],
        orElse: () => <UserModel>[],
      );

      final updatedList = currentWorkers
          .map((w) => w.id == workerId ? updatedWorker : w)
          .toList();

      state = AsyncValue.data(updatedList);
      return updatedWorker;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Delete worker
  Future<void> deleteWorker(String workerId) async {
    try {
      await _workerService.deleteWorker(workerId);

      // Update state
      final currentWorkers = state.maybeWhen(
        data: (workers) => [...workers],
        orElse: () => <UserModel>[],
      );

      final updatedList = currentWorkers.where((w) => w.id != workerId).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Toggle worker status
  Future<UserModel?> toggleWorkerStatus(
      String workerId, bool newStatus) async {
    try {
      final updatedWorker =
          await _workerService.toggleWorkerStatus(workerId, newStatus);

      // Update state
      final currentWorkers = state.maybeWhen(
        data: (workers) => [...workers],
        orElse: () => <UserModel>[],
      );

      final updatedList = currentWorkers
          .map((w) => w.id == workerId ? updatedWorker : w)
          .toList();

      state = AsyncValue.data(updatedList);
      return updatedWorker;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  // Search workers
  Future<void> searchWorkers(String query) async {
    state = const AsyncValue.loading();
    try {
      final workers = await _workerService.searchWorkers(query);
      state = AsyncValue.data(workers);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}





