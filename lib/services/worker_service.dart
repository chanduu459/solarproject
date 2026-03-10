import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class WorkerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all workers (excluding owners)
  Future<List<UserModel>> getAllWorkers() async {
    try {
      final response = await _supabase
          .from('workers')
          .select()
          .eq('role', 'worker')
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get workers: $e');
    }
  }

  // Get active workers only (excluding owners)
  Future<List<UserModel>> getActiveWorkers() async {
    try {
      final response = await _supabase
          .from('workers')
          .select()
          .eq('role', 'worker')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active workers: $e');
    }
  }

  // Get workers by role
  Future<List<UserModel>> getWorkersByRole(String role) async {
    try {
      final response = await _supabase
          .from('workers')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get workers by role: $e');
    }
  }

  // Add new worker (requires authentication and owner role)
  Future<UserModel> addWorker({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
    String? avatarUrl,
  }) async {
    // Store the current owner's session before creating new user
    final currentSession = _supabase.auth.currentSession;

    if (currentSession == null) {
      throw Exception('No active session. Please login again.');
    }

    final ownerRefreshToken = currentSession.refreshToken;
    String? newUserId;

    try {
      // Create the auth user for the new worker
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create authentication user');
      }

      newUserId = authResponse.user!.id;

      // Restore the owner's session immediately
      if (ownerRefreshToken != null) {
        await _supabase.auth.setSession(ownerRefreshToken);
      }

      // Now create the worker record as the owner
      // Note: role is always 'worker' for new workers (database constraint)
      await _supabase.from('workers').insert({
        'id': newUserId,
        'email': email,
        'full_name': fullName,
        'role': 'worker', // Always 'worker' - job title is stored elsewhere or in notes
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      // Fetch and return the created worker
      final response = await _supabase
          .from('workers')
          .select()
          .eq('id', newUserId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      // Try to restore owner session if something went wrong
      if (ownerRefreshToken != null) {
        try {
          await _supabase.auth.setSession(ownerRefreshToken);
        } catch (_) {
          // Ignore session restoration errors in error handler
        }
      }
      throw Exception('Failed to add worker: $e');
    }
  }

  // Update worker
  Future<UserModel> updateWorker({
    required String workerId,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    String? avatarUrl,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (email != null) updates['email'] = email;
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (role != null) updates['role'] = role;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase.from('workers').update(updates).eq('id', workerId);

      // Fetch and return the updated worker
      final response = await _supabase
          .from('workers')
          .select()
          .eq('id', workerId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update worker: $e');
    }
  }

  // Delete worker
  Future<void> deleteWorker(String workerId) async {
    try {
      // Delete the worker record (cascade will handle auth user)
      await _supabase.from('workers').delete().eq('id', workerId);
    } catch (e) {
      throw Exception('Failed to delete worker: $e');
    }
  }

  // Toggle worker active status
  Future<UserModel> toggleWorkerStatus(String workerId, bool newStatus) async {
    try {
      await _supabase.from('workers').update({
        'is_active': newStatus,
      }).eq('id', workerId);

      // Fetch and return the updated worker
      final response = await _supabase
          .from('workers')
          .select()
          .eq('id', workerId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle worker status: $e');
    }
  }

  // Search workers
  Future<List<UserModel>> searchWorkers(String query) async {
    try {
      final response = await _supabase
          .from('workers')
          .select()
          .or('email.ilike.%$query%,full_name.ilike.%$query%,phone.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search workers: $e');
    }
  }
}



