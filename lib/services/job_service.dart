import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_model.dart';

class JobService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Get all jobs (for owner)
  Future<List<JobModel>> getAllJobs() async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('''
            *,
            customers (*),
            workers!jobs_worker_id_fkey (full_name)
          ''')
          .order('scheduled_date', ascending: false);

      return response.map((json) {
        final jobJson = Map<String, dynamic>.from(json);
        if (json['workers'] != null) {
          jobJson['worker_name'] = json['workers']['full_name'];
        }
        return JobModel.fromJson(jobJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  // 2. Get jobs assigned to a specific worker
  Future<List<JobModel>> getWorkerJobs(String workerId) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select('*, customers (*)') // Ensure your trigger syncs location data to the jobs table
          .eq('worker_id', workerId)
          .order('scheduled_date', ascending: true);

      return response.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch worker jobs: $e');
    }
  }

  // 3. Get jobs for today for a specific worker
  // 3. Get jobs for today (including unfinished past jobs)
  Future<List<JobModel>> getTodayJobs(String workerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // 1. Fetch all jobs scheduled up to the end of today
      final response = await _supabase
          .from('jobs')
          .select('*, customers (*)')
          .eq('worker_id', workerId)
          .lte('scheduled_date', endOfDay)
          .order('scheduled_date', ascending: true);

      // 2. Filter locally to avoid complex PostgREST date string parsing issues
      final filteredList = response.where((json) {
        final scheduledDate = json['scheduled_date'] as String;
        final status = json['status'] as String?;

        // Job is scheduled for today
        final isToday = scheduledDate.compareTo(startOfDay) >= 0;

        // Job was scheduled in the past, but is not completed yet
        final isUnfinishedPast = scheduledDate.compareTo(startOfDay) < 0 && status != 'completed';

        return isToday || isUnfinishedPast;
      }).toList();

      return filteredList.map((json) => JobModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch today jobs: $e');
    }
  }

  // 4. Owner Dashboard statistics
  Future<Map<String, dynamic>> getJobStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).toUtc().toIso8601String();

      // Get total jobs count
      final totalJobs = await _supabase.from('jobs').count(CountOption.exact);

      // Get filtered counts using select and counting locally
      final pendingResponse = await _supabase.from('jobs').select('id').eq('status', 'pending');
      final inProgressResponse = await _supabase.from('jobs').select('id').eq('status', 'in_progress');

      // Get ALL completed jobs (for pie chart and overall stats)
      final completedResponse = await _supabase.from('jobs').select('id').eq('status', 'completed');

      // Get completed today (for the "Completed Today" metric card)
      final completedTodayResponse = await _supabase
          .from('jobs')
          .select('id')
          .eq('status', 'completed')
          .gte('completed_at', startOfDay)
          .lt('completed_at', endOfDay);

      return {
        'total_jobs': totalJobs,
        'pending_jobs': (pendingResponse as List).length,
        'in_progress_jobs': (inProgressResponse as List).length,
        'completed_jobs': (completedResponse as List).length,  // Total completed jobs
        'completed_today': (completedTodayResponse as List).length,  // Completed today
      };
    } catch (e) {
      throw Exception('Failed to get job statistics: $e');
    }
  }

  // 5. Submit Work Update with Latitude/Longitude support
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
      final Map<String, dynamic> updateData = {
        'job_id': jobId,
        'worker_id': workerId,
        'progress_percentage': progressPercentage,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (notes != null && notes.isNotEmpty) updateData['notes'] = notes;

      final existingUpdate = await _supabase
          .from('work_updates')
          .select('id, image_urls')
          .eq('job_id', jobId)
          .maybeSingle();

      if (existingUpdate != null) {
        List<dynamic> existingImages = existingUpdate['image_urls'] ?? [];
        if (imageUrls != null && imageUrls.isNotEmpty) {
          updateData['image_urls'] = [...existingImages, ...imageUrls];
        }
        await _supabase.from('work_updates').update(updateData).eq('id', existingUpdate['id']);
      } else {
        if (imageUrls != null && imageUrls.isNotEmpty) {
          updateData['image_urls'] = imageUrls;
        }
        await _supabase.from('work_updates').insert(updateData);
      }

      // Update job location directly if provided
      if (location != null && location.isNotEmpty) {
        await _supabase.from('jobs').update({'location': location}).eq('id', jobId);
      }
    } catch (e) {
      throw Exception('Failed to submit work update: $e');
    }
  }

  // 6. Update progress logic
  Future<JobModel> updateProgress({
    required String jobId,
    required int progressPercentage,
  }) async {
    final updates = {
      'progress_percentage': progressPercentage,
      'status': progressPercentage == 100 ? 'completed' : 'in_progress',
      if (progressPercentage == 100) 'completed_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase.from('jobs').update(updates).eq('id', jobId).select('*, customers (*)').single();
    return JobModel.fromJson(response);
  }

  // 7. Get Job by ID
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final response = await _supabase.from('jobs').select('*, customers (*), workers!jobs_worker_id_fkey (full_name)').eq('id', jobId).single();
      final jobJson = Map<String, dynamic>.from(response);
      if (response['workers'] != null) jobJson['worker_name'] = response['workers']['full_name'];
      return JobModel.fromJson(jobJson);
    } catch (e) {
      return null;
    }
  }

  // 8. Assign a worker to a job
  Future<JobModel> assignWorker({
    required String jobId,
    required String workerId,
  }) async {
    try {
      final response = await _supabase
          .from('jobs')
          .update({'worker_id': workerId})
          .eq('id', jobId)
          .select('*, customers (*), workers!jobs_worker_id_fkey (full_name)')
          .single();

      final jobJson = Map<String, dynamic>.from(response);
      if (response['workers'] != null) {
        jobJson['worker_name'] = response['workers']['full_name'];
      }
      return JobModel.fromJson(jobJson);
    } catch (e) {
      throw Exception('Failed to assign worker: $e');
    }
  }

  // 9. Create a new job
  Future<JobModel> addJob({
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
      final payload = <String, dynamic>{
        'customer_id': customerId,
        'worker_id': workerId,
        'panel_type': panelType,
        'panel_quantity': panelQuantity,
        'scheduled_date': scheduledDate.toUtc().toIso8601String(),
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (estimatedCost != null) 'estimated_cost': estimatedCost,
      }..removeWhere((key, value) => value == null);

      final response = await _supabase
          .from('jobs')
          .insert(payload)
          .select('*, customers (*), workers!jobs_worker_id_fkey (full_name)')
          .single();

      final jobJson = Map<String, dynamic>.from(response);
      if (response['workers'] != null) {
        jobJson['worker_name'] = response['workers']['full_name'];
      }
      return JobModel.fromJson(jobJson);
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }
}