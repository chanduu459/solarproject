import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../../../models/customer_model.dart';
import '../../../models/user_model.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _panelTypeController = TextEditingController();
  final _panelQtyController = TextEditingController(text: '1');

  String? _selectedCustomerId;
  String? _selectedWorkerId;
  DateTime? _scheduledDate;
  bool _isSubmitting = false;

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

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.4),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _scheduledDate == null) {
      if (_scheduledDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a scheduled date'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(jobsProvider.notifier).addJob(
            customerId: (_selectedCustomerId ?? widget.preselectedCustomerId)!,
            workerId: _selectedWorkerId,
            panelType: _panelTypeController.text.trim(),
            panelQuantity: int.parse(_panelQtyController.text.trim()),
            scheduledDate: _scheduledDate!,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create job: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Job',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                if (widget.preselectedCustomerId != null)
                  TextFormField(
                    initialValue: widget.customers
                        .firstWhere((c) => c.id == widget.preselectedCustomerId)
                        .fullName,
                    decoration: _inputDecoration('Customer'),
                    enabled: false,
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: _inputDecoration('Customer'),
                    items: widget.customers
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.fullName),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCustomerId = val),
                    validator: (val) => val == null ? 'Select a customer' : null,
                  ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: _selectedWorkerId,
                  decoration: _inputDecoration('Assign worker (optional)'),
                  items: widget.workers
                      .map((w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.fullName),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedWorkerId = val),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _panelTypeController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Panel type'),
                  validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _panelQtyController,
                  decoration: _inputDecoration('Panel quantity'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final parsed = int.tryParse(val ?? '');
                    if (parsed == null || parsed < 1) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _scheduledDate == null
                                ? 'Select scheduled date'
                                : 'Scheduled: ${_scheduledDate!.toLocal().toString().split(' ').first}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: _scheduledDate == null ? Colors.grey.shade600 : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 20.w, color: const Color(0xFF1E88E5)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      backgroundColor: const Color(0xFF1E88E5),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Create Job',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                          ),
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

