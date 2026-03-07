import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../../../widgets/add_worker_form.dart';

class AddWorkerDialog extends ConsumerStatefulWidget {
  const AddWorkerDialog({super.key});

  @override
  ConsumerState<AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends ConsumerState<AddWorkerDialog> {
  bool _isLoading = false;

  void _handleAddWorker(Map<String, dynamic> workerData) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(workersProvider.notifier).addWorker(
            email: workerData['email'],
            password: workerData['password'],
            fullName: workerData['full_name'],
            role: workerData['role'],
            phone: workerData['phone'],
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: AddWorkerForm(
        onSubmit: _handleAddWorker,
        isLoading: _isLoading,
      ),
    );
  }
}

