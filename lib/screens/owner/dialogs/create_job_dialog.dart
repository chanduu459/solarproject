import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../providers/providers.dart';
import '../../../models/customer_model.dart';
import '../../../models/user_model.dart';

// ────────────────────────────────────────────────
//   Reusable Create Job Form
// ────────────────────────────────────────────────
class CreateJobForm extends ConsumerStatefulWidget {
  final List<CustomerModel> customers;
  final List<UserModel> workers;
  final String? preselectedCustomerId;
  final bool isSubmitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const CreateJobForm({
    super.key,
    required this.customers,
    required this.workers,
    this.preselectedCustomerId,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  ConsumerState<CreateJobForm> createState() => _CreateJobFormState();
}

class _CreateJobFormState extends ConsumerState<CreateJobForm> {
  final _formKey = GlobalKey<FormState>();
  final _panelTypeController = TextEditingController();
  final _panelQtyController = TextEditingController(text: '1');

  String? _selectedCustomerId;
  String? _selectedWorkerId;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.preselectedCustomerId;
  }

  @override
  void dispose() {
    _panelTypeController.dispose();
    _panelQtyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.black87,
              surface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _scheduledDate == null) {
      if (_scheduledDate == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white),
                SizedBox(width: 12),
                Text('Please select scheduled date'),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        );
      }
      return;
    }

    final data = {
      'customerId': (_selectedCustomerId ?? widget.preselectedCustomerId)!,
      'workerId': _selectedWorkerId,
      'panelType': _panelTypeController.text.trim(),
      'panelQuantity': int.parse(_panelQtyController.text.trim()),
      'scheduledDate': _scheduledDate!,
    };

    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 32.h),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.work_outline_rounded,
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
                        'Create New Job',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Schedule a solar installation job',
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

            // ─── Customer & Worker ───
            _buildSectionHeader('Assignment'),
            SizedBox(height: 16.h),

            if (widget.preselectedCustomerId != null)
              _buildDisabledField(
                label: 'Customer',
                value: widget.customers
                    .firstWhere((c) => c.id == widget.preselectedCustomerId)
                    .fullName,
                icon: Icons.person_rounded,
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                hint: const Text('Select Customer'),
                items: widget.customers
                    .map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.fullName),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCustomerId = val),
                validator: (val) => val == null ? 'Required' : null,
                decoration: _buildInputDecoration(Icons.person_rounded),
              ),

            SizedBox(height: 16.h),

            DropdownButtonFormField<String>(
              value: _selectedWorkerId,
              hint: const Text('Assign Worker (optional)'),
              items: widget.workers
                  .map((w) => DropdownMenuItem(
                value: w.id,
                child: Text(w.fullName),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedWorkerId = val),
              decoration: _buildInputDecoration(Icons.engineering_rounded),
            ),

            SizedBox(height: 32.h),

            // ─── Job Details ───
            _buildSectionHeader('Job Details'),
            SizedBox(height: 16.h),

            TextFormField(
              controller: _panelTypeController,
              textCapitalization: TextCapitalization.words,
              decoration: _buildInputDecoration(Icons.solar_power_rounded)
                  .copyWith(labelText: 'Panel Type', hintText: 'e.g. Mono PERC 550W'),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
            ),

            SizedBox(height: 16.h),

            TextFormField(
              controller: _panelQtyController,
              keyboardType: TextInputType.number,
              decoration: _buildInputDecoration(Icons.format_list_numbered_rounded)
                  .copyWith(labelText: 'Panel Quantity'),
              validator: (v) {
                final qty = int.tryParse(v?.trim() ?? '');
                if (qty == null || qty < 1) return 'Enter valid quantity ≥ 1';
                return null;
              },
            ),

            SizedBox(height: 16.h),

            InkWell(
              onTap: widget.isSubmitting ? null : _pickDate,
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _scheduledDate == null
                        ? Colors.grey.shade300
                        : primary.withOpacity(0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: _scheduledDate == null ? Colors.grey.shade600 : primary,
                      size: 22.w,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _scheduledDate == null
                            ? 'Select Scheduled Date'
                            : 'Scheduled: ${_formatDate(_scheduledDate!)}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: _scheduledDate == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: FilledButton.icon(
                onPressed: widget.isSubmitting ? null : _submit,
                icon: widget.isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.add_task_rounded),
                label: widget.isSubmitting
                    ? SizedBox(
                  height: 22.h,
                  width: 22.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Create Job',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black87,
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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  InputDecoration _buildInputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: Icon(icon, size: 22.w),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
    );
  }

  Widget _buildDisabledField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22.w, color: Colors.grey.shade600),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.5.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12.8.sp,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
        letterSpacing: 0.7,
      ),
    );
  }
}

// ────────────────────────────────────────────────
//   Dialog Wrapper
// ────────────────────────────────────────────────
class CreateJobDialog extends ConsumerStatefulWidget {
  final List<CustomerModel> customers;
  final List<UserModel> workers;
  final String? preselectedCustomerId;

  const CreateJobDialog({
    super.key,
    required this.customers,
    required this.workers,
    this.preselectedCustomerId,
  });

  @override
  ConsumerState<CreateJobDialog> createState() => _CreateJobDialogState();
}

class _CreateJobDialogState extends ConsumerState<CreateJobDialog> {
  bool _isSubmitting = false;

  Future<void> _handleSubmit(Map<String, dynamic> data) async {
    setState(() => _isSubmitting = true);

    try {
      await ref.read(jobsProvider.notifier).addJob(
        customerId: data['customerId'] as String,
        workerId: data['workerId'] as String?,
        panelType: data['panelType'] as String,
        panelQuantity: data['panelQuantity'] as int,
        scheduledDate: data['scheduledDate'] as DateTime,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12.w),
              const Text('Job created successfully'),
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
              const Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12.w),
              Text('Failed to create job • ${e.toString().split('\n').first}'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      backgroundColor: const Color(0xFFF8FAFC),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520.w,
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: CreateJobForm(
          customers: widget.customers,
          workers: widget.workers,
          preselectedCustomerId: widget.preselectedCustomerId,
          isSubmitting: _isSubmitting,
          onSubmit: _handleSubmit,
        ),
      ),
    );
  }
}