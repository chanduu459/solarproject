import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddCustomerForm extends StatefulWidget {
  final Function(Map<String, dynamic> customerData) onSubmit;
  final bool isLoading;

  const AddCustomerForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return null;
    if (double.tryParse(value.trim()) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final latitude = _latitudeController.text.trim().isEmpty
          ? null
          : double.tryParse(_latitudeController.text.trim());
      final longitude = _longitudeController.text.trim().isEmpty
          ? null
          : double.tryParse(_longitudeController.text.trim());

      final customerData = {
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        'zip_code': _zipCodeController.text.trim().isEmpty
            ? null
            : _zipCodeController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      };

      widget.onSubmit(customerData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Customer',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: _fullNameController,
                decoration: _inputDecoration('Full Name', Icons.person),
                validator: (value) => _validateRequired(value, 'Full name'),
                enabled: !widget.isLoading,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email Address', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                enabled: !widget.isLoading,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone Number', Icons.phone),
                keyboardType: TextInputType.phone,
                validator: (value) => _validateRequired(value, 'Phone number'),
                enabled: !widget.isLoading,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Address', Icons.home),
                validator: (value) => _validateRequired(value, 'Address'),
                enabled: !widget.isLoading,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration('City (Optional)', Icons.location_city),
                      enabled: !widget.isLoading,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: _inputDecoration('State (Optional)', Icons.map),
                      enabled: !widget.isLoading,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _zipCodeController,
                decoration: _inputDecoration('Zip Code (Optional)', Icons.pin_drop),
                enabled: !widget.isLoading,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: _inputDecoration('Latitude (Optional)', Icons.place),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) => _validateNumeric(value, 'Latitude'),
                      enabled: !widget.isLoading,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: _inputDecoration('Longitude (Optional)', Icons.place),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) => _validateNumeric(value, 'Longitude'),
                      enabled: !widget.isLoading,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('Notes (Optional)', Icons.notes),
                minLines: 3,
                maxLines: 4,
                enabled: !widget.isLoading,
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: widget.isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Add Customer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    );
  }
}

