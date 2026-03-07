import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/providers.dart';
import 'worker/worker_dashboard.dart';
import 'owner/owner_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _usePhoneLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) return;

    // 2. Dismiss the keyboard for a better user experience
    FocusScope.of(context).unfocus();

    try {
      // 3. Trigger the appropriate login method
      if (_usePhoneLogin) {
        await ref.read(authProvider.notifier).signInWithPhone(
          phone: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      // 4. Ensure the widget is still mounted before using context
      if (!mounted) return;

      final authState = ref.read(authProvider);

      // 5. Handle Navigation on Success
      if (authState.isAuthenticated) {
        if (authState.isOwner) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OwnerDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WorkerDashboard()),
          );
        }
      }
    } catch (e) {
      debugPrint('Unexpected Login Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60.h),
                // Logo
                Center(
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      Icons.solar_power,
                      size: 56.w,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                // Title
                Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF263238),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
                SizedBox(height: 48.h),
                // Login method toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Email'),
                      selected: !_usePhoneLogin,
                      onSelected: (selected) {
                        setState(() {
                          _usePhoneLogin = !selected;
                        });
                      },
                    ),
                    SizedBox(width: 16.w),
                    ChoiceChip(
                      label: const Text('Phone'),
                      selected: _usePhoneLogin,
                      onSelected: (selected) {
                        setState(() {
                          _usePhoneLogin = selected;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // Email/Phone field
                TextFormField(
                  controller: _emailController,
                  keyboardType: _usePhoneLogin
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: _usePhoneLogin ? 'Phone Number' : 'Email',
                    hintText: _usePhoneLogin
                        ? 'Enter your phone number'
                        : 'Enter your email',
                    prefixIcon: Icon(
                      _usePhoneLogin ? Icons.phone : Icons.email,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return _usePhoneLogin
                          ? 'Please enter your phone number'
                          : 'Please enter your email';
                    }
                    if (!_usePhoneLogin && !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8.h),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                SizedBox(height: 24.h),
                // Error message from provider state
                if (authState.error != null) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      authState.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                // Login button
                SizedBox(
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                // Demo credentials info
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Credentials:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Owner: owner@example.com / password',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        'Worker: worker@example.com / password',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}