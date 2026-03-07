import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_report_model.dart';

class DailyReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Generate daily report for a worker
  Future<DailyReportModel> generateDailyReport({
    required String workerId,
    required DateTime reportDate,
  }) async {
    try {
      final startOfDay = DateTime(reportDate.year, reportDate.month, reportDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get jobs for the day
      final jobsResponse = await _supabase
          .from('jobs')
          .select('id, status')
          .eq('worker_id', workerId)
          .gte('scheduled_date', startOfDay.toIso8601String())
          .lt('scheduled_date', endOfDay.toIso8601String());

      final jobIds = jobsResponse.map((j) => j['id'] as String).toList();
      final totalJobs = jobIds.length;
      final completedJobs = jobsResponse
          .where((j) => j['status'] == 'completed')
          .length;
      final pendingJobs = totalJobs - completedJobs;

      // Get attendance for the day
      final attendanceResponse = await _supabase
          .from('attendance')
          .select('working_hours')
          .eq('worker_id', workerId)
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String());

      final totalHoursWorked = attendanceResponse
          .fold<int>(0, (sum, a) => sum + (a['working_hours'] as int? ?? 0));

      // Get issues reported for the day
      final issuesResponse = await _supabase
          .from('issue_reports')
          .select('id')
          .eq('worker_id', workerId)
          .gte('reported_at', startOfDay.toIso8601String())
          .lt('reported_at', endOfDay.toIso8601String());

      final issuesReported = issuesResponse.length;

      // Create or update daily report
      final reportData = {
        'worker_id': workerId,
        'report_date': startOfDay.toIso8601String(),
        'total_jobs': totalJobs,
        'completed_jobs': completedJobs,
        'pending_jobs': pendingJobs,
        'issues_reported': issuesReported,
        'total_hours_worked': totalHoursWorked,
        'job_ids': jobIds,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Check if report already exists
      final existingReport = await _supabase
          .from('daily_reports')
          .select()
          .eq('worker_id', workerId)
          .eq('report_date', startOfDay.toIso8601String())
          .maybeSingle();

      if (existingReport != null) {
        // Update existing report
        final response = await _supabase
            .from('daily_reports')
            .update(reportData)
            .eq('id', existingReport['id'])
            .select('*, workers (full_name)')
            .single();

        final transformedJson = Map<String, dynamic>.from(response);
        if (response['workers'] != null) {
          transformedJson['worker_name'] = response['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      } else {
        // Create new report
        final response = await _supabase
            .from('daily_reports')
            .insert(reportData)
            .select('*, workers (full_name)')
            .single();

        final transformedJson = Map<String, dynamic>.from(response);
        if (response['workers'] != null) {
          transformedJson['worker_name'] = response['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      }
    } catch (e) {
      throw Exception('Failed to generate daily report: $e');
    }
  }

  // Get daily report by ID
  Future<DailyReportModel?> getDailyReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('daily_reports')
          .select('*, workers (full_name)')
          .eq('id', reportId)
          .single();

      if (response != null) {
        final transformedJson = Map<String, dynamic>.from(response);
        if (response['workers'] != null) {
          transformedJson['worker_name'] = response['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch daily report: $e');
    }
  }

  // Get daily report for worker and date
  Future<DailyReportModel?> getWorkerDailyReport({
    required String workerId,
    required DateTime reportDate,
  }) async {
    try {
      final startOfDay = DateTime(reportDate.year, reportDate.month, reportDate.day);

      final response = await _supabase
          .from('daily_reports')
          .select('*, workers (full_name)')
          .eq('worker_id', workerId)
          .eq('report_date', startOfDay.toIso8601String())
          .maybeSingle();

      if (response != null) {
        final transformedJson = Map<String, dynamic>.from(response);
        if (response['workers'] != null) {
          transformedJson['worker_name'] = response['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch worker daily report: $e');
    }
  }

  // Get all daily reports (for owner)
  Future<List<DailyReportModel>> getAllDailyReports() async {
    try {
      final response = await _supabase
          .from('daily_reports')
          .select('*, workers (full_name)')
          .order('report_date', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers'] != null) {
          transformedJson['worker_name'] = json['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch all daily reports: $e');
    }
  }

  // Get worker's daily reports
  Future<List<DailyReportModel>> getWorkerDailyReports(String workerId) async {
    try {
      final response = await _supabase
          .from('daily_reports')
          .select('*, workers (full_name)')
          .eq('worker_id', workerId)
          .order('report_date', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers'] != null) {
          transformedJson['worker_name'] = json['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch worker daily reports: $e');
    }
  }

  // Get today's reports
  Future<List<DailyReportModel>> getTodayReports() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final response = await _supabase
          .from('daily_reports')
          .select('*, workers (full_name)')
          .eq('report_date', startOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((json) {
        final transformedJson = Map<String, dynamic>.from(json);
        if (json['workers'] != null) {
          transformedJson['worker_name'] = json['workers']['full_name'];
        }
        return DailyReportModel.fromJson(transformedJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch today reports: $e');
    }
  }

  // Update daily report notes
  Future<DailyReportModel> updateReportNotes({
    required String reportId,
    required String notes,
  }) async {
    try {
      final response = await _supabase
          .from('daily_reports')
          .update({'notes': notes})
          .eq('id', reportId)
          .select('*, workers (full_name)')
          .single();

      final transformedJson = Map<String, dynamic>.from(response);
      if (response['workers'] != null) {
        transformedJson['worker_name'] = response['workers']['full_name'];
      }
      return DailyReportModel.fromJson(transformedJson);
    } catch (e) {
      throw Exception('Failed to update report notes: $e');
    }
  }

  // Delete daily report
  Future<void> deleteDailyReport(String reportId) async {
    try {
      await _supabase.from('daily_reports').delete().eq('id', reportId);
    } catch (e) {
      throw Exception('Failed to delete daily report: $e');
    }
  }

  // Get daily report statistics
  Future<Map<String, dynamic>> getDailyReportStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's reports
      final todayReportsResponse = await _supabase
          .from('daily_reports')
          .select()
          .eq('report_date', startOfDay.toIso8601String());

      final totalJobsToday = todayReportsResponse.fold<int>(
          0, (sum, r) => sum + (r['total_jobs'] as int));
      final completedJobsToday = todayReportsResponse.fold<int>(
          0, (sum, r) => sum + (r['completed_jobs'] as int));
      final totalHoursToday = todayReportsResponse.fold<int>(
          0, (sum, r) => sum + (r['total_hours_worked'] as int));

      return {
        'total_reports_today': todayReportsResponse.length,
        'total_jobs_today': totalJobsToday,
        'completed_jobs_today': completedJobsToday,
        'pending_jobs_today': totalJobsToday - completedJobsToday,
        'total_hours_today': totalHoursToday,
      };
    } catch (e) {
      throw Exception('Failed to get daily report statistics: $e');
    }
  }
}
