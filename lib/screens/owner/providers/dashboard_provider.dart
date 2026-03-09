import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../services/services.dart';

/// Dashboard state holder
class DashboardState {
  final Map<String, dynamic> statistics;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.statistics = const {},
    this.isLoading = true,
    this.error,
  });

  DashboardState copyWith({
    Map<String, dynamic>? statistics,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Dashboard provider for managing dashboard state and logic
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardNotifier(this.ref) : super(DashboardState());

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _loadStatistics();

      // Load other providers
      await ref.read(jobsProvider.notifier).loadAllJobs();
      await ref.read(attendanceProvider.notifier).loadAllAttendance();
      await ref.read(issuesProvider.notifier).loadAllIssues();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load dashboard data');
    }
  }

  /// Load statistics from services
  Future<void> _loadStatistics() async {
    try {
      final jobService = JobService();
      final attendanceService = AttendanceService();
      final issueService = IssueReportService();

      final jobStats = await jobService.getJobStatistics();
      final attendanceStats = await attendanceService.getAttendanceStatistics();
      final issueStats = await issueService.getIssueStatistics();

      state = state.copyWith(
        statistics: {
          ...jobStats,
          ...attendanceStats,
          ...issueStats,
        },
      );
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    await loadDashboardData();
  }
}

