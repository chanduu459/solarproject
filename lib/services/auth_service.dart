import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Login with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Update last login time
      if (response.user != null) {
        await _supabase.from('workers').update({
          'last_login_at': DateTime.now().toIso8601String(),
        }).eq('id', response.user!.id);
      }
      
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Login with phone and password
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      // First, find user by phone
      final userData = await _supabase
          .from('workers')
          .select('email')
          .eq('phone', phone)
          .single();
      
      if (userData == null || userData['email'] == null) {
        throw Exception('User not found with this phone number');
      }
      
      final response = await _supabase.auth.signInWithPassword(
        email: userData['email'],
        password: password,
      );
      
      // Update last login time
      if (response.user != null) {
        await _supabase.from('workers').update({
          'last_login_at': DateTime.now().toIso8601String(),
        }).eq('id', response.user!.id);
      }
      
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Register new user (Owner only)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'phone': phone,
        },
      );

      // Create user record in workers table
      if (response.user != null) {
        await _supabase.from('workers').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'role': role,
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
          'is_active': true,
        });
      }

      return response;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get user details from workers table
  Future<UserModel?> getUserDetails(String userId) async {
    try {
      final response = await _supabase
          .from('workers')
          .select()
          .eq('id', userId)
          .single();
      
      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      
      await _supabase.from('workers').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send reset password email: $e');
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Refresh session
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
    } catch (e) {
      print('Error refreshing session: $e');
    }
  }
}
