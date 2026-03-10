import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/services.dart';

// Issues state
class IssuesState {
  final List<IssueReportModel> issues;
  final IssueReportModel? selectedIssue;
  final bool isLoading;
  final String? error;

  IssuesState({
    this.issues = const [],
    this.selectedIssue,
    this.isLoading = false,
    this.error,
  });

  IssuesState copyWith({
    List<IssueReportModel>? issues,
    IssueReportModel? selectedIssue,
    bool? isLoading,
    String? error,
  }) {
    return IssuesState(
      issues: issues ?? this.issues,
      selectedIssue: selectedIssue ?? this.selectedIssue,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<IssueReportModel> get openIssues =>
      issues.where((i) => i.isOpen).toList();

  List<IssueReportModel> get inProgressIssues =>
      issues.where((i) => i.isInProgress).toList();

  List<IssueReportModel> get resolvedIssues =>
      issues.where((i) => i.isResolved).toList();
}

// Issues notifier
class IssuesNotifier extends StateNotifier<IssuesState> {
  final IssueReportService _issueService = IssueReportService();

  IssuesNotifier() : super(IssuesState());

  Future<void> loadAllIssues() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final issues = await _issueService.getAllIssues();
      debugPrint('IssuesProvider: Loaded ${issues.length} issues');
      state = state.copyWith(issues: issues, isLoading: false);
    } catch (e) {
      debugPrint('IssuesProvider: Error loading issues: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load issues: $e',
      );
    }
  }

  Future<void> loadWorkerIssues(String workerId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final issues = await _issueService.getWorkerIssues(workerId);
      state = state.copyWith(issues: issues, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load issues: $e',
      );
    }
  }

  Future<void> loadJobIssues(String jobId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final issues = await _issueService.getJobIssues(jobId);
      state = state.copyWith(issues: issues, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load issues: $e',
      );
    }
  }

  Future<void> loadIssuesByStatus(String status) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final issues = await _issueService.getIssuesByStatus(status);
      state = state.copyWith(issues: issues, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load issues: $e',
      );
    }
  }

  Future<void> createIssueReport({
    required String jobId,
    required String workerId,
    required String issueType,
    required String description,
    String priority = 'medium',
    String? reportedBy,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final issue = await _issueService.createIssueReport(
        jobId: jobId,
        workerId: workerId,
        issueType: issueType,
        description: description,
        priority: priority,
        reportedBy: reportedBy,
        imageUrls: imageUrls,
        latitude: latitude,
        longitude: longitude,
      );

      state = state.copyWith(
        issues: [issue, ...state.issues],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create issue report: $e',
      );
      rethrow;
    }
  }

  Future<void> updateIssueStatus({
    required String issueId,
    required String status,
    String? resolvedBy,
    String? resolutionNotes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedIssue = await _issueService.updateIssueStatus(
        issueId: issueId,
        status: status,
        resolvedBy: resolvedBy,
        resolutionNotes: resolutionNotes,
      );

      final updatedIssues = state.issues.map((i) {
        return i.id == issueId ? updatedIssue : i;
      }).toList();

      state = state.copyWith(
        issues: updatedIssues,
        selectedIssue: updatedIssue,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update issue status: $e',
      );
    }
  }

  Future<void> updateIssue({
    required String issueId,
    String? issueType,
    String? description,
    String? priority,
    List<String>? imageUrls,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final updatedIssue = await _issueService.updateIssue(
        issueId: issueId,
        issueType: issueType,
        description: description,
        priority: priority,
        imageUrls: imageUrls,
      );

      final updatedIssues = state.issues.map((i) {
        return i.id == issueId ? updatedIssue : i;
      }).toList();

      state = state.copyWith(
        issues: updatedIssues,
        selectedIssue: updatedIssue,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update issue: $e',
      );
    }
  }

  Future<void> deleteIssue(String issueId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _issueService.deleteIssue(issueId);
      
      final updatedIssues = state.issues.where((i) => i.id != issueId).toList();
      
      state = state.copyWith(
        issues: updatedIssues,
        selectedIssue: state.selectedIssue?.id == issueId ? null : state.selectedIssue,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete issue: $e',
      );
    }
  }

  void selectIssue(IssueReportModel? issue) {
    state = state.copyWith(selectedIssue: issue);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final issuesProvider = StateNotifierProvider<IssuesNotifier, IssuesState>((ref) {
  return IssuesNotifier();
});

// Selected issue provider
final selectedIssueProvider = Provider<IssueReportModel?>((ref) {
  return ref.watch(issuesProvider).selectedIssue;
});

// Open issues count provider
final openIssuesCountProvider = Provider<int>((ref) {
  return ref.watch(issuesProvider).openIssues.length;
});
