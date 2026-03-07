import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../../../widgets/add_customer_form.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  const AddCustomerPage({super.key});

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  bool _isLoading = false;

  Future<void> _handleAddCustomer(Map<String, dynamic> customerData) async {
    setState(() => _isLoading = true);

    try {
      await ref.read(customersProvider.notifier).addCustomer(
            fullName: customerData['full_name'] as String,
            email: customerData['email'] as String,
            phone: customerData['phone'] as String,
            address: customerData['address'] as String,
            city: customerData['city'] as String?,
            stateName: customerData['state'] as String?,
            zipCode: customerData['zip_code'] as String?,
            latitude: customerData['latitude'] as double?,
            longitude: customerData['longitude'] as double?,
            notes: customerData['notes'] as String?,
          );

      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer'),
      ),
      body: AddCustomerForm(
        onSubmit: _handleAddCustomer,
        isLoading: _isLoading,
      ),
    );
  }
}

