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
  final _panelTypeController = TextEditingController();
  final _panelQuantityController = TextEditingController(text: '1');

  String? _selectedWorkerId;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    // Load workers when form initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workersProvider.notifier).loadActiveWorkers();
    });
  }

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
    _panelTypeController.dispose();
    _panelQuantityController.dispose();
    super.dispose();
  }

  Future<void> _selectScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
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
      // Job assignment fields
      'assigned_worker_id': _selectedWorkerId,
      'panel_type': _panelTypeController.text.trim().isEmpty ? null : _panelTypeController.text.trim(),
      'panel_quantity': int.tryParse(_panelQuantityController.text.trim()) ?? 1,
      'scheduled_date': _scheduledDate,
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

            SizedBox(height: 32.h),

            // ─── Assign Worker ───
            _buildSectionHeader('Job Assignment (Optional)'),
            SizedBox(height: 12.h),
            _buildWorkerDropdown(),

            SizedBox(height: 16.h),

            // Panel Type
            _buildField(
              controller: _panelTypeController,
              label: 'Panel Type',
              hint: 'e.g., Monocrystalline, Polycrystalline',
              prefixIcon: Icons.solar_power_rounded,
            ),

            SizedBox(height: 16.h),

            // Panel Quantity
            _buildField(
              controller: _panelQuantityController,
              label: 'Panel Quantity',
              hint: '1',
              prefixIcon: Icons.format_list_numbered_rounded,
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 16.h),

            // Scheduled Date
            GestureDetector(
              onTap: _selectScheduledDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 22.w, color: Colors.grey.shade600),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _scheduledDate != null
                            ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                            : 'Select Scheduled Date (Optional)',
                        style: TextStyle(
                          fontSize: 15.5.sp,
                          color: _scheduledDate != null ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (_scheduledDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _scheduledDate = null),
                        child: Icon(Icons.clear_rounded, size: 20.w, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
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

  Widget _buildWorkerDropdown() {
    final workersAsync = ref.watch(workersProvider);

    return workersAsync.when(
      data: (workers) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedWorkerId,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 4.w),
                child: Icon(Icons.person_outline_rounded, size: 22.w),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 48.w),
              hintText: 'Select Worker (Optional)',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15.5.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
              ),
            ),
            isExpanded: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'No Worker Assigned',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15.5.sp,
                  ),
                ),
              ),
              ...workers.map((worker) => DropdownMenuItem<String>(
                value: worker.id,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        worker.fullName.isNotEmpty ? worker.fullName[0].toUpperCase() : 'W',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            worker.fullName,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (worker.phone != null && worker.phone!.isNotEmpty)
                            Text(
                              worker.phone!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedWorkerId = value;
              });
            },
          ),
        );
      },
      loading: () => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12.w),
            Text(
              'Loading workers...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 20.w),
            SizedBox(width: 12.w),
            Text(
              'Failed to load workers',
              style: TextStyle(color: Colors.red.shade700, fontSize: 15.sp),
            ),
          ],
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
      // 1. First create the customer
      final newCustomer = await ref.read(customersProvider.notifier).addCustomer(
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

      // 2. If worker is assigned, create a job in jobs table
      final workerId = data['assigned_worker_id'] as String?;
      final panelType = data['panel_type'] as String?;
      final panelQuantity = data['panel_quantity'] as int? ?? 1;
      final scheduledDate = data['scheduled_date'] as DateTime?;

      if (workerId != null && workerId.isNotEmpty) {
        await ref.read(jobsProvider.notifier).addJob(
          customerId: newCustomer.id,
          workerId: workerId,
          panelType: panelType ?? 'Standard Panel',
          panelQuantity: panelQuantity,
          scheduledDate: scheduledDate ?? DateTime.now(),
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              Text(workerId != null
                ? 'Customer added & job assigned successfully'
                : 'Customer added successfully'),
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