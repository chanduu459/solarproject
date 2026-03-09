import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../providers/providers.dart';

// ────────────────────────────────────────────────
//   Modern Add Worker Form (card-style matching screenshot)
// ────────────────────────────────────────────────
class AddWorkerForm extends ConsumerStatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final bool isLoading;

  const AddWorkerForm({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  ConsumerState<AddWorkerForm> createState() => _AddWorkerFormState();
}

class _AddWorkerFormState extends ConsumerState<AddWorkerForm> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;

  final List<String> _roles = [
    'Field Technician',
    'Installation Specialist',
    'Electrician',
    'Site Supervisor',
    'Quality Inspector',
    'Support Staff',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final data = {
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': _selectedRole ?? 'Field Technician',
    };

    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary; // solar yellow

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card-like header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.engineering_rounded,
                      color: primary,
                      size: 28.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Team Member',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Invite a new worker to your solar crew',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32.h),

              // ─── PERSONAL DETAILS ───
              Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 12.h),

              _buildInputCard(
                child: _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
              ),

              SizedBox(height: 12.h),

              _buildInputCard(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                    return null;
                  },
                ),
              ),

              SizedBox(height: 12.h),

              _buildInputCard(
                child: _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
              ),

              SizedBox(height: 32.h),

              // ─── ROLE & ACCESS ───
              Text(
                'ROLE & ACCESS',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: 12.h),

              _buildInputCard(
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  hint: const Text('Select Role'),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role, style: TextStyle(fontSize: 15.sp)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (v) => v == null ? 'Please select a role' : null,
                ),
              ),

              SizedBox(height: 12.h),

              _buildInputCard(
                child: _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
              ),

              SizedBox(height: 12.h),

              _buildInputCard(
                child: _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ),

              SizedBox(height: 40.h),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton.icon(
                  onPressed: widget.isLoading ? null : _submit,
                  icon: widget.isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.person_add_rounded, size: 20),
                  label: widget.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Add Team Member',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(fontSize: 15.5.sp, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIcon: Icon(icon, size: 22.w, color: Colors.grey.shade700),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//   Dialog Wrapper (card-like appearance)
// ────────────────────────────────────────────────
class AddWorkerDialog extends ConsumerStatefulWidget {
  const AddWorkerDialog({super.key});

  @override
  ConsumerState<AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends ConsumerState<AddWorkerDialog> {
  bool _isLoading = false;

  Future<void> _handleAddWorker(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(workersProvider.notifier).addWorker(
        email: data['email'] as String,
        password: data['password'] as String,
        fullName: data['full_name'] as String,
        role: data['role'] as String,
        phone: data['phone'] as String,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              const Text('Team member added successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              Text('Failed to add • ${e.toString().split('\n').first}'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: 520.w,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: AddWorkerForm(
          onSubmit: _handleAddWorker,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}