import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/providers.dart';
import 'owner/owner_dashboard.dart';
import 'worker/worker_dashboard.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _usePhoneLogin = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    try {
      final notifier = ref.read(authProvider.notifier);

      if (_usePhoneLogin) {
        await notifier.signInWithPhone(
          phone: _emailOrPhoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await notifier.signInWithEmail(
          email: _emailOrPhoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (authState.isAuthenticated) {
        final target = authState.isOwner
            ? const OwnerDashboard()
            : const WorkerDashboard();

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => target,
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 420),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary; // solar yellow #FFC107
    final secondary = theme.colorScheme.secondary; // deep green
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // light gray / off-white
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),

                  // Logo with subtle glass effect
                  Center(
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: Container(
                        width: 96.w,
                        height: 96.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(28.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.04),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.solar_power_rounded,
                          size: 52.w,
                          color: primary,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  // Title & subtitle
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Sign in to manage solar installations',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 44.h),

                  // Login method toggle (Email / Phone)
                  SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Email'),
                            icon: Icon(Icons.email_outlined),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Phone'),
                            icon: Icon(Icons.phone_outlined),
                          ),
                        ],
                        selected: {_usePhoneLogin},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _usePhoneLogin = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black54,
                          selectedBackgroundColor: primary,
                          selectedForegroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 36.h),

                  // Input fields
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailOrPhoneController,
                          label: _usePhoneLogin ? 'Phone Number' : 'Email',
                          hint: _usePhoneLogin
                              ? '+91 98765 43210'
                              : 'name@company.com',
                          prefixIcon:
                          _usePhoneLogin ? Icons.phone : Icons.email,
                          keyboardType: _usePhoneLogin
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _usePhoneLogin
                                  ? 'Please enter phone number'
                                  : 'Please enter email';
                            }
                            if (!_usePhoneLogin && !value.contains('@')) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20.h),
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock,
                          obscureText: !_isPasswordVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () =>
                                setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Minimum 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Forgot password flow
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                        textStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // Error display
                  if (authState.error != null)
                    SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (authState.error != null) SizedBox(height: 24.h),

                  // Login Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FilledButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.black87,
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 2,
                        shadowColor: primary.withOpacity(0.4),
                      ),
                      child: authState.isLoading
                          ? SizedBox(
                        height: 24.h,
                        width: 24.h,
                        child: CircularProgressIndicator(
                          color: Colors.black87,
                          strokeWidth: 3,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(fontSize: 16.sp, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      ),
      validator: validator,
    );
  }
}