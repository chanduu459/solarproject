import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_completion_model.dart';

class JobCompletionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create job completion record
  Future<JobCompletionModel> createCompletion({
    required String jobId,
    required String workerId,
    bool safetyConfirmed = false,
    String? customerSignatureUrl,
    String? customerName,
    String? notes,
    double? finalLatitude,
    double? finalLongitude,
  }) async {
    try {
      final completionData = {
        'job_id': jobId,
        'worker_id': workerId,
        'safety_confirmed': safetyConfirmed,
        'safety_confirmed_at': safetyConfirmed ? DateTime.now().toIso8601String() : null,
        'customer_signature_url': customerSignatureUrl,
        'customer_name': customerName,
        'signed_at': customerSignatureUrl != null ? DateTime.now().toIso8601String() : null,
        'completed_at': DateTime.now().toIso8601String(),
        'notes': notes,
        'final_latitude': finalLatitude,
        'final_longitude': finalLongitude,
      };

      final response = await _supabase
          .from('job_completion')
          .insert(completionData)
          .select()
          .single();

      return JobCompletionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create job completion: $e');
    }
  }

  // Get completion by ID
  Future<JobCompletionModel?> getCompletionById(String completionId) async {
    try {
      final response = await _supabase
          .from('job_completion')
          .select()
          .eq('id', completionId)
          .single();

      if (response != null) {
        return JobCompletionModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch job completion: $e');
    }
  }

  // Get completion by job ID
  Future<Map<String, dynamic>> getCompletionStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();

      // Run all 4 queries at the same time
      final results = await Future.wait([
        _supabase.from('job_completion').count(),
        _supabase.from('job_completion').count().gte('completed_at', startOfDay),
        _supabase.from('job_completion').count().eq('safety_confirmed', true),
        _supabase.from('job_completion').count().not('customer_signature_url', 'is', null),
      ]);

      return {
        'total_completions': results[0],
        'today_completions': results[1],
        'safety_confirmed': results[2],
        'customer_signed': results[3],
      };
    } catch (e) {
      throw Exception('Failed to get completion statistics: $e');
    }
  }

  // Update safety confirmation
  Future<JobCompletionModel> confirmSafety({
    required String completionId,
    required bool confirmed,
  }) async {
    try {
      final updates = <String, dynamic>{
        'safety_confirmed': confirmed,
        'safety_confirmed_at': confirmed ? DateTime.now().toIso8601String() : null,
      };

      final response = await _supabase
          .from('job_completion')
          .update(updates)
          .eq('id', completionId)
          .select()
          .single();

      return JobCompletionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update safety confirmation: $e');
    }
  }

  // Add customer signature
  Future<JobCompletionModel> addCustomerSignature({
    required String completionId,
    required String signatureUrl,
    required String customerName,
  }) async {
    try {
      final updates = <String, dynamic>{
        'customer_signature_url': signatureUrl,
        'customer_name': customerName,
        'signed_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('job_completion')
          .update(updates)
          .eq('id', completionId)
          .select()
          .single();

      return JobCompletionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add customer signature: $e');
    }
  }

  // Update completion
  Future<JobCompletionModel> updateCompletion({
    required String completionId,
    String? notes,
    double? finalLatitude,
    double? finalLongitude,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (notes != null) updates['notes'] = notes;
      if (finalLatitude != null) updates['final_latitude'] = finalLatitude;
      if (finalLongitude != null) updates['final_longitude'] = finalLongitude;

      final response = await _supabase
          .from('job_completion')
          .update(updates)
          .eq('id', completionId)
          .select()
          .single();

      return JobCompletionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update completion: $e');
    }
  }

  // Get all completions (for owner)
  Future<List<JobCompletionModel>> getAllCompletions() async {
    try {
      final response = await _supabase
          .from('job_completion')
          .select()
          .order('completed_at', ascending: false);

      return response.map((json) => JobCompletionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all completions: $e');
    }
  }

  // Get completions by worker
  Future<List<JobCompletionModel>> getWorkerCompletions(String workerId) async {
    try {
      final response = await _supabase
          .from('job_completion')
          .select()
          .eq('worker_id', workerId)
          .order('completed_at', ascending: false);

      return response.map((json) => JobCompletionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch worker completions: $e');
    }
  }

  // Get today's completions
  Future<List<JobCompletionModel>> getTodayCompletions() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('job_completion')
          .select()
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .order('completed_at', ascending: false);

      return response.map((json) => JobCompletionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch today completions: $e');
    }
  }

  // Delete completion
  Future<void> deleteCompletion(String completionId) async {
    try {
      await _supabase.from('job_completion').delete().eq('id', completionId);
    } catch (e) {
      throw Exception('Failed to delete completion: $e');
    }
  }


  Future<Map<String, dynamic>> getCompletionStatistics1() async {
    try {
      final now = DateTime.now();
      // Using toUtc() is safer for database comparisons
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1))
          .toUtc()
          .toIso8601String();

      // results[0] = total, results[1] = today, etc.
      final results = await Future.wait([
        // 1. Total completions
        _supabase.from('job_completion').count(CountOption.exact),

        // 2. Today's completions
        _supabase.from('job_completion')
            .count(CountOption.exact)
            .gte('completed_at', startOfDay)
            .lt('completed_at', endOfDay),

        // 3. Safety confirmed
        _supabase.from('job_completion')
            .count(CountOption.exact)
            .eq('safety_confirmed', true),

        // 4. Customer signed
        _supabase.from('job_completion')
            .count(CountOption.exact)
            .not('customer_signature_url', 'is', null),
      ]);

      return {
        'total_completions': results[0],
        'today_completions': results[1],
        'safety_confirmed': results[2],
        'customer_signed': results[3],
      };
    } catch (e) {
      throw Exception('Failed to get completion statistics: $e');
    }
  }
}
