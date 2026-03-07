import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// Attendance state
class AttendanceState {
  final List<AttendanceModel> attendanceRecords;
  final AttendanceModel? activeAttendance;
  final bool isLoading;
  final String? error;

  AttendanceState({
    this.attendanceRecords = const [],
    this.activeAttendance,
    this.isLoading = false,
    this.error,
  });

  AttendanceState copyWith({
    List<AttendanceModel>? attendanceRecords,
    AttendanceModel? activeAttendance,
    bool? isLoading,
    String? error,
  }) {
    return AttendanceState(
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      activeAttendance: activeAttendance ?? this.activeAttendance,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isCheckedIn => activeAttendance != null && activeAttendance!.isCheckedIn;
}

// Attendance notifier
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceService _attendanceService = AttendanceService();

  AttendanceNotifier() : super(AttendanceState());

  Future<void> loadWorkerAttendance(String workerId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final records = await _attendanceService.getWorkerAttendance(workerId);
      state = state.copyWith(
        attendanceRecords: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load attendance: $e',
      );
    }
  }

  Future<void> loadTodayAttendance(String workerId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final records = await _attendanceService.getTodayAttendance(workerId);
      state = state.copyWith(
        attendanceRecords: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load today attendance: $e',
      );
    }
  }

  Future<void> loadActiveAttendance(String workerId) async {
    try {
      final activeAttendance = await _attendanceService.getActiveAttendance(workerId);
      state = state.copyWith(activeAttendance: activeAttendance);
    } catch (e) {
      print('Error loading active attendance: $e');
    }
  }

  Future<void> checkIn({
    required String workerId,
    required String jobId,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final attendance = await _attendanceService.checkIn(
        workerId: workerId,
        jobId: jobId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        notes: notes,
      );

      state = state.copyWith(
        activeAttendance: attendance,
        attendanceRecords: [attendance, ...state.attendanceRecords],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check in: $e',
      );
    }
  }

  Future<void> checkOut({
    required String attendanceId,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final attendance = await _attendanceService.checkOut(
        attendanceId: attendanceId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        notes: notes,
      );

      final updatedRecords = state.attendanceRecords.map((a) {
        return a.id == attendanceId ? attendance : a;
      }).toList();

      state = state.copyWith(
        activeAttendance: null,
        attendanceRecords: updatedRecords,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check out: $e',
      );
    }
  }

  Future<void> loadAllAttendance() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final records = await _attendanceService.getAllAttendance();
      state = state.copyWith(
        attendanceRecords: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load attendance: $e',
      );
    }
  }

  Future<void> loadAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? workerId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final records = await _attendanceService.getAttendanceByDateRange(
        startDate: startDate,
        endDate: endDate,
        workerId: workerId,
      );
      state = state.copyWith(
        attendanceRecords: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load attendance: $e',
      );
    }
  }

  Future<void> updateNotes({
    required String attendanceId,
    required String notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final attendance = await _attendanceService.updateNotes(
        attendanceId: attendanceId,
        notes: notes,
      );

      final updatedRecords = state.attendanceRecords.map((a) {
        return a.id == attendanceId ? attendance : a;
      }).toList();

      state = state.copyWith(
        attendanceRecords: updatedRecords,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update notes: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearActiveAttendance() {
    state = state.copyWith(activeAttendance: null);
  }
}

// Provider
final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});

// Is checked in provider
final isCheckedInProvider = Provider<bool>((ref) {
  return ref.watch(attendanceProvider).isCheckedIn;
});

// Active attendance provider
final activeAttendanceProvider = Provider<AttendanceModel?>((ref) {
  return ref.watch(attendanceProvider).activeAttendance;
});
