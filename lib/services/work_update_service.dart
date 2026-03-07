import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_update_model.dart';

class WorkUpdateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create work update
  Future<WorkUpdateModel> createWorkUpdate({
    required String jobId,
    required String workerId,
    required int progressPercentage,
    String? notes,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updateData = {
        'job_id': jobId,
        'worker_id': workerId,
        'progress_percentage': progressPercentage,
        'notes': notes,
        'image_urls': imageUrls,
        'created_at': DateTime.now().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await _supabase
          .from('work_updates')
          .insert(updateData)
          .select()
          .single();

      return WorkUpdateModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create work update: $e');
    }
  }

  // Get work update by ID
  Future<WorkUpdateModel?> getWorkUpdateById(String updateId) async {
    try {
      final response = await _supabase
          .from('work_updates')
          .select()
          .eq('id', updateId)
          .single();

      if (response != null) {
        return WorkUpdateModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch work update: $e');
    }
  }

  // Get work updates for a job
  Future<List<WorkUpdateModel>> getJobWorkUpdates(String jobId) async {
    try {
      final response = await _supabase
          .from('work_updates')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false);

      return response.map((json) => WorkUpdateModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch job work updates: $e');
    }
  }

  // Get work updates by worker
  Future<List<WorkUpdateModel>> getWorkerWorkUpdates(String workerId) async {
    try {
      final response = await _supabase
          .from('work_updates')
          .select()
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);

      return response.map((json) => WorkUpdateModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch worker work updates: $e');
    }
  }

  // Get all work updates (for owner)
  Future<List<WorkUpdateModel>> getAllWorkUpdates() async {
    try {
      final response = await _supabase
          .from('work_updates')
          .select('*, workers (full_name)')
          .order('created_at', ascending: false);

      return response.map((json) => WorkUpdateModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all work updates: $e');
    }
  }

  // Get today's work updates
  Future<List<WorkUpdateModel>> getTodayWorkUpdates() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('work_updates')
          .select('*, workers (full_name)')
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return response.map((json) => WorkUpdateModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch today work updates: $e');
    }
  }

  // Update work update
  Future<WorkUpdateModel> updateWorkUpdate({
    required String updateId,
    int? progressPercentage,
    String? notes,
    List<String>? imageUrls,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (progressPercentage != null) {
        updates['progress_percentage'] = progressPercentage;
      }
      if (notes != null) updates['notes'] = notes;
      if (imageUrls != null) updates['image_urls'] = imageUrls;

      final response = await _supabase
          .from('work_updates')
          .update(updates)
          .eq('id', updateId)
          .select()
          .single();

      return WorkUpdateModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update work update: $e');
    }
  }

  // Delete work update
  Future<void> deleteWorkUpdate(String updateId) async {
    try {
      await _supabase.from('work_updates').delete().eq('id', updateId);
    } catch (e) {
      throw Exception('Failed to delete work update: $e');
    }
  }

  // Get latest work update for a job
  Future<WorkUpdateModel?> getLatestWorkUpdate(String jobId) async {
    try {
      final response = await _supabase
          .from('work_updates')
          .select()
          .eq('job_id', jobId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return WorkUpdateModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch latest work update: $e');
    }
  }
}
