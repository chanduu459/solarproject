import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/issue_report_model.dart';

class IssueReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create issue report
  Future<IssueReportModel> createIssueReport({
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
      final issueData = <String, dynamic>{
        'job_id': jobId,
        'worker_id': workerId,
        'issue_type': issueType,
        'description': description,
        'priority': priority,
        'status': 'open',
        'reported_at': DateTime.now().toIso8601String(),
        'reported_by': reportedBy,
        'image_urls': imageUrls,
        'latitude': latitude,
        'longitude': longitude,
      };

      debugPrint('Creating issue report with data: $issueData');

      final response = await _supabase
          .from('issue_reports')
          .insert(issueData)
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .single();

      debugPrint('Issue report created successfully: ${response['id']}');

      // Transform the response to include joined data
      final transformedJson = Map<String, dynamic>.from(response);
      if (response['workers!issue_reports_worker_id_fkey'] != null) {
        transformedJson['worker_name'] = response['workers!issue_reports_worker_id_fkey']['full_name'];
      }
      if (response['jobs'] != null && response['jobs']['customers'] != null) {
        transformedJson['customer_name'] = response['jobs']['customers']['full_name'];
      }

      return IssueReportModel.fromJson(transformedJson);
    } catch (e) {
      throw Exception('Failed to create issue report: $e');
    }
  }

  // Get issue by ID
  Future<IssueReportModel?> getIssueById(String issueId) async {
    try {
      final response = await _supabase
          .from('issue_reports')
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .eq('id', issueId)
          .single();

      if (response != null) {
        final transformedJson = Map<String, dynamic>.from(response);
        if (response['workers!issue_reports_worker_id_fkey'] != null) {
          transformedJson['worker_name'] = response['workers!issue_reports_worker_id_fkey']['full_name'];
        }
        if (response['jobs'] != null && response['jobs']['customers'] != null) {
          transformedJson['customer_name'] = response['jobs']['customers']['full_name'];
        }
        return IssueReportModel.fromJson(transformedJson);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch issue: $e');
    }
  }

  // Get all issues (for owner)
  Future<List<IssueReportModel>> getAllIssues() async {
    try {
      final response = await _supabase
          .from('issue_reports')
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .order('reported_at', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers!issue_reports_worker_id_fkey'] != null) {
          transformedJson['worker_name'] = json['workers!issue_reports_worker_id_fkey']['full_name'];
        }
        if (json['jobs'] != null && json['jobs']['customers'] != null) {
          transformedJson['customer_name'] = json['jobs']['customers']['full_name'];
        }
        return IssueReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch all issues: $e');
    }
  }

  // Get issues by worker
  Future<List<IssueReportModel>> getWorkerIssues(String workerId) async {
    try {
      final response = await _supabase
          .from('issue_reports')
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .eq('worker_id', workerId)
          .order('reported_at', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers!issue_reports_worker_id_fkey'] != null) {
          transformedJson['worker_name'] = json['workers!issue_reports_worker_id_fkey']['full_name'];
        }
        if (json['jobs'] != null && json['jobs']['customers'] != null) {
          transformedJson['customer_name'] = json['jobs']['customers']['full_name'];
        }
        return IssueReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch worker issues: $e');
    }
  }

  // Get issues by job
  Future<List<IssueReportModel>> getJobIssues(String jobId) async {
    try {
      final response = await _supabase
          .from('issue_reports')
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .eq('job_id', jobId)
          .order('reported_at', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers!issue_reports_worker_id_fkey'] != null) {
          transformedJson['worker_name'] = json['workers!issue_reports_worker_id_fkey']['full_name'];
        }
        if (json['jobs'] != null && json['jobs']['customers'] != null) {
          transformedJson['customer_name'] = json['jobs']['customers']['full_name'];
        }
        return IssueReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch job issues: $e');
    }
  }

  // Get issues by status
  Future<List<IssueReportModel>> getIssuesByStatus(String status) async {
    try {
      final response = await _supabase
          .from('issue_reports')
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .eq('status', status)
          .order('reported_at', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers!issue_reports_worker_id_fkey'] != null) {
          transformedJson['worker_name'] = json['workers!issue_reports_worker_id_fkey']['full_name'];
        }
        if (json['jobs'] != null && json['jobs']['customers'] != null) {
          transformedJson['customer_name'] = json['jobs']['customers']['full_name'];
        }
        return IssueReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch issues by status: $e');
    }
  }

  // Update issue status
  Future<IssueReportModel> updateIssueStatus({
    required String issueId,
    required String status,
    String? resolvedBy,
    String? resolutionNotes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
      };

      if (status == 'resolved') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
        if (resolvedBy != null) updates['resolved_by'] = resolvedBy;
        if (resolutionNotes != null) {
          updates['resolution_notes'] = resolutionNotes;
        }
      } else if (status == 'in_progress') {
        // Clear resolution fields when moving back to in_progress
        updates['resolved_at'] = null;
        updates['resolved_by'] = null;
        updates['resolution_notes'] = null;
      } else if (status == 'open') {
        // Clear all resolution fields when reopening
        updates['resolved_at'] = null;
        updates['resolved_by'] = null;
        updates['resolution_notes'] = null;
      }

      final response = await _supabase
          .from('issue_reports')
          .update(updates)
          .eq('id', issueId)
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .single();

      final transformedJson = Map<String, dynamic>.from(response);
      if (response['workers!issue_reports_worker_id_fkey'] != null) {
        transformedJson['worker_name'] = response['workers!issue_reports_worker_id_fkey']['full_name'];
      }
      if (response['jobs'] != null && response['jobs']['customers'] != null) {
        transformedJson['customer_name'] = response['jobs']['customers']['full_name'];
      }

      return IssueReportModel.fromJson(transformedJson);
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }

  // Update issue
  Future<IssueReportModel> updateIssue({
    required String issueId,
    String? issueType,
    String? description,
    String? priority,
    List<String>? imageUrls,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (issueType != null) updates['issue_type'] = issueType;
      if (description != null) updates['description'] = description;
      if (priority != null) updates['priority'] = priority;
      if (imageUrls != null) updates['image_urls'] = imageUrls;

      final response = await _supabase
          .from('issue_reports')
          .update(updates)
          .eq('id', issueId)
          .select('*, workers!issue_reports_worker_id_fkey (full_name), jobs (customers (full_name))')
          .single();

      final transformedJson = Map<String, dynamic>.from(response);
      if (response['workers!issue_reports_worker_id_fkey'] != null) {
        transformedJson['worker_name'] = response['workers!issue_reports_worker_id_fkey']['full_name'];
      }
      if (response['jobs'] != null && response['jobs']['customers'] != null) {
        transformedJson['customer_name'] = response['jobs']['customers']['full_name'];
      }

      return IssueReportModel.fromJson(transformedJson);
    } catch (e) {
      throw Exception('Failed to update issue: $e');
    }
  }

  // Delete issue
  Future<void> deleteIssue(String issueId) async {
    try {
      await _supabase.from('issue_reports').delete().eq('id', issueId);
    } catch (e) {
      throw Exception('Failed to delete issue: $e');
    }
  }

  // Get issue statistics
  Future<Map<String, dynamic>> getIssueStatistics() async {
    try {
      // We use Future.wait to fire all 4 requests at once,
      // making your dashboard load much faster.
      final results = await Future.wait([
        _supabase.from('issue_reports').count(CountOption.exact),
        _supabase.from('issue_reports').select('id').eq('status', 'open'),
        _supabase.from('issue_reports').select('id').eq('status', 'in_progress'),
        _supabase.from('issue_reports').select('id').eq('status', 'resolved'),
      ]);

      return {
        'total_issues': results[0] as int,
        'open_issues': (results[1] as List).length,
        'in_progress_issues': (results[2] as List).length,
        'resolved_issues': (results[3] as List).length,
      };
    } catch (e) {
      throw Exception('Failed to get issue statistics: $e');
    }
  }
}
