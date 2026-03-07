import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/services.dart';

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isOwner => user?.isOwner ?? false;
  bool get isWorker => user?.isWorker ?? false;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _loadUserDetails(currentUser.id);
    }
  }

  Future<void> _loadUserDetails(String userId) async {
    try {
      state = state.copyWith(isLoading: true);
      final user = await _authService.getUserDetails(userId);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _loadUserDetails(response.user!.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _authService.signInWithPhone(
        phone: phone,
        password: password,
      );
      
      if (response.user != null) {
        await _loadUserDetails(response.user!.id);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);
      await _authService.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      if (state.user == null) return;
      
      await _authService.updateProfile(
        userId: state.user!.id,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      
      // Reload user details
      await _loadUserDetails(state.user!.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.changePassword(newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isOwner;
});

final isWorkerProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isWorker;
});
