import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// Jobs state
class JobsState {
  final List<JobModel> jobs;
  final List<JobModel> todayJobs;
  final JobModel? selectedJob;
  final bool isLoading;
  final String? error;

  JobsState({
    this.jobs = const [],
    this.todayJobs = const [],
    this.selectedJob,
    this.isLoading = false,
    this.error,
  });

  JobsState copyWith({
    List<JobModel>? jobs,
    List<JobModel>? todayJobs,
    JobModel? selectedJob,
    bool? isLoading,
    String? error,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      todayJobs: todayJobs ?? this.todayJobs,
      selectedJob: selectedJob ?? this.selectedJob,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<JobModel> get pendingJobs => jobs.where((j) => j.status == 'pending').toList();
  List<JobModel> get inProgressJobs => jobs.where((j) => j.status == 'in_progress').toList();
  List<JobModel> get completedJobs => jobs.where((j) => j.status == 'completed').toList();
}

// Jobs notifier
class JobsNotifier extends StateNotifier<JobsState> {
  final JobService _jobService = JobService();

  JobsNotifier() : super(JobsState());

  Future<void> loadAllJobs() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final jobs = await _jobService.getAllJobs();
      state = state.copyWith(jobs: jobs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load jobs: $e');
    }
  }

  Future<void> loadWorkerJobs(String workerId) async {
    try {
      // Small delay to prevent setState during build errors
      await Future.delayed(Duration.zero);
      if (!state.isLoading) state = state.copyWith(isLoading: true, error: null);

      final jobs = await _jobService.getWorkerJobs(workerId);
      state = state.copyWith(jobs: jobs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load worker jobs: $e');
    }
  }

  Future<void> loadTodayJobs(String workerId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final jobs = await _jobService.getTodayJobs(workerId);
      state = state.copyWith(todayJobs: jobs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load today jobs: $e');
    }
  }

  Future<void> loadJobById(String jobId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final job = await _jobService.getJobById(jobId);
      state = state.copyWith(selectedJob: job, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load job: $e');
    }
  }

  /// RESTORED: Directly updates the progress of a job
  /// Used by JobDetailScreen and post-completion logic
  Future<void> updateProgress({
    required String jobId,
    required int progressPercentage,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updatedJob = await _jobService.updateProgress(
        jobId: jobId,
        progressPercentage: progressPercentage,
      );

      final updatedJobs = state.jobs.map((j) => j.id == jobId ? updatedJob : j).toList();
      final updatedTodayJobs = state.todayJobs.map((j) => j.id == jobId ? updatedJob : j).toList();

      state = state.copyWith(
        jobs: updatedJobs,
        todayJobs: updatedTodayJobs,
        selectedJob: state.selectedJob?.id == jobId ? updatedJob : state.selectedJob,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to update progress: $e');
    }
  }

  /// SUBMIT WORK UPDATE: Handles the new work_updates table with Lat/Long support
  Future<void> submitWorkUpdate({
    required String jobId,
    required String workerId,
    required int progressPercentage,
    String? notes,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? location,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 1. Send everything to the service (Upserts the work_updates table)
      await _jobService.submitWorkUpdate(
        jobId: jobId,
        workerId: workerId,
        progressPercentage: progressPercentage,
        notes: notes,
        imageUrls: imageUrls,
        latitude: latitude,
        longitude: longitude,
        location: location,
      );

      // 2. Fetch updated job (Since DB trigger updated the jobs table)
      final updatedJob = await _jobService.getJobById(jobId);

      if (updatedJob != null) {
        final updatedJobs = state.jobs.map((j) => j.id == jobId ? updatedJob : j).toList();
        final updatedTodayJobs = state.todayJobs.map((j) => j.id == jobId ? updatedJob : j).toList();

        state = state.copyWith(
          jobs: updatedJobs,
          todayJobs: updatedTodayJobs,
          selectedJob: state.selectedJob?.id == jobId ? updatedJob : state.selectedJob,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to submit update: $e');
      rethrow;
    }
  }

  Future<void> assignWorkerToJob({
    required String jobId,
    required String workerId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updatedJob = await _jobService.assignWorker(jobId: jobId, workerId: workerId);

      final updatedJobs = state.jobs.map((j) => j.id == jobId ? updatedJob : j).toList();
      final updatedToday = state.todayJobs.map((j) => j.id == jobId ? updatedJob : j).toList();

      state = state.copyWith(
        jobs: updatedJobs,
        todayJobs: updatedToday,
        selectedJob: state.selectedJob?.id == jobId ? updatedJob : state.selectedJob,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to assign worker: $e');
      rethrow;
    }
  }

  Future<void> addJob({
    required String customerId,
    String? workerId,
    required String panelType,
    required int panelQuantity,
    required DateTime scheduledDate,
    String? status,
    String? priority,
    String? notes,
    double? estimatedCost,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final newJob = await _jobService.addJob(
        customerId: customerId,
        workerId: workerId,
        panelType: panelType,
        panelQuantity: panelQuantity,
        scheduledDate: scheduledDate,
        status: status,
        priority: priority,
        notes: notes,
        estimatedCost: estimatedCost,
      );

      state = state.copyWith(
        jobs: [newJob, ...state.jobs],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to create job: $e');
      rethrow;
    }
  }

  void selectJob(JobModel? job) {
    state = state.copyWith(selectedJob: job);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) => JobsNotifier());
final selectedJobProvider = Provider<JobModel?>((ref) => ref.watch(jobsProvider).selectedJob);
final todayJobsProvider = Provider<List<JobModel>>((ref) => ref.watch(jobsProvider).todayJobs);

