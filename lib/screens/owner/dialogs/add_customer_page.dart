import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../providers/providers.dart';

// ────────────────────────────────────────────────
//   Modern Add Customer Form Widget
// ────────────────────────────────────────────────
class AddCustomerForm extends ConsumerStatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final bool isLoading;

  const AddCustomerForm({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  ConsumerState<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends ConsumerState<AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      'zip_code': _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
      'latitude': double.tryParse(_latController.text.trim()),
      'longitude': double.tryParse(_lngController.text.trim()),
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;     // solar yellow
    final onPrimary = theme.colorScheme.onPrimary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-like header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    color: primary,
                    size: 28.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Customer',
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Enter customer details for solar project',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // ─── Personal Information Group ───
            _buildSectionHeader('Personal Information'),
            SizedBox(height: 12.h),

            _buildField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'John Doe',
              prefixIcon: Icons.person_rounded,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              textCapitalization: TextCapitalization.words,
            ),

            SizedBox(height: 16.h),

            _buildField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'customer@company.com',
              prefixIcon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                return null;
              },
            ),

            SizedBox(height: 16.h),

            _buildField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '+91 98765 43210',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),

            SizedBox(height: 32.h),

            // ─── Location Group ───
            _buildSectionHeader('Installation Location'),
            SizedBox(height: 12.h),

            _buildField(
              controller: _addressController,
              label: 'Street Address',
              hint: '123 Solar Street, Green Colony',
              prefixIcon: Icons.home_rounded,
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              maxLines: 2,
            ),

            SizedBox(height: 16.h),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Hyderabad',
                    prefixIcon: Icons.location_city_rounded,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'Telangana',
                    prefixIcon: Icons.map_rounded,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            _buildField(
              controller: _zipController,
              label: 'ZIP / Postal Code',
              hint: '500081',
              prefixIcon: Icons.pin_rounded,
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 24.h),

            // Optional coordinates (collapsible feel but kept visible)
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _latController,
                    label: 'Latitude',
                    hint: '17.3850',
                    prefixIcon: Icons.location_on_rounded,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildField(
                    controller: _lngController,
                    label: 'Longitude',
                    hint: '78.4867',
                    prefixIcon: Icons.location_on_rounded,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // ─── Notes ───
            _buildSectionHeader('Additional Notes'),
            SizedBox(height: 12.h),

            _buildField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'Prefers morning installation, has 3-phase connection...',
              prefixIcon: Icons.notes_rounded,
              maxLines: 4,
              minLines: 3,
            ),

            SizedBox(height: 48.h),

            // ─── Action Button ───
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: FilledButton.icon(
                onPressed: widget.isLoading ? null : _submit,
                icon: widget.isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.add_rounded),
                label: widget.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Add Customer',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 2,
                  shadowColor: primary.withOpacity(0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int minLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      minLines: minLines,
      validator: validator,
      style: TextStyle(fontSize: 15.5.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: Icon(prefixIcon, size: 22.w),
        )
            : null,
        prefixIconConstraints: BoxConstraints(minWidth: 48.w),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: maxLines > 1 ? 16.h : 18.h,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
//   Page Wrapper (keeps your original logic)
// ────────────────────────────────────────────────
class AddCustomerPage extends ConsumerStatefulWidget {
  const AddCustomerPage({super.key});

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  bool _isLoading = false;

  Future<void> _handleAddCustomer(Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(customersProvider.notifier).addCustomer(
        fullName: data['full_name'] as String,
        email: data['email'] as String,
        phone: data['phone'] as String,
        address: data['address'] as String,
        city: data['city'] as String?,
        stateName: data['state'] as String?,
        zipCode: data['zip_code'] as String?,
        latitude: data['latitude'] as double?,
        longitude: data['longitude'] as double?,
        notes: data['notes'] as String?,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              const Text('Customer added successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF00C853),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              Text('Failed to add customer • ${e.toString().split('\n')[0]}'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Customer'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 19.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      body: AddCustomerForm(
        onSubmit: _handleAddCustomer,
        isLoading: _isLoading,
      ),
    );
  }
}