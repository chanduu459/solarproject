import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyNameController.text = prefs.getString('company_name') ?? 'SolarPulse Pro';
      _addressController.text = prefs.getString('company_address') ?? '';
      _cityController.text = prefs.getString('company_city') ?? '';
      _stateController.text = prefs.getString('company_state') ?? '';
      _zipController.text = prefs.getString('company_zip') ?? '';
      _phoneController.text = prefs.getString('company_phone') ?? '';
      _emailController.text = prefs.getString('company_email') ?? '';
      _websiteController.text = prefs.getString('company_website') ?? '';
      _gstController.text = prefs.getString('company_gst') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveCompanyProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('company_name', _companyNameController.text.trim());
      await prefs.setString('company_address', _addressController.text.trim());
      await prefs.setString('company_city', _cityController.text.trim());
      await prefs.setString('company_state', _stateController.text.trim());
      await prefs.setString('company_zip', _zipController.text.trim());
      await prefs.setString('company_phone', _phoneController.text.trim());
      await prefs.setString('company_email', _emailController.text.trim());
      await prefs.setString('company_website', _websiteController.text.trim());
      await prefs.setString('company_gst', _gstController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Company profile saved'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Company Profile',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCompanyProfile,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Company Logo Section
                    Center(
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(Icons.business, size: 50.w, color: const Color(0xFF1A237E)),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    _buildSectionTitle('BASIC INFORMATION'),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _companyNameController,
                      label: 'Company Name',
                      icon: Icons.business_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter company name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _gstController,
                      label: 'GST Number',
                      icon: Icons.receipt_long_outlined,
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('CONTACT DETAILS'),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'Website',
                      icon: Icons.language_outlined,
                      keyboardType: TextInputType.url,
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('ADDRESS'),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Street Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State',
                            icon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _zipController,
                      label: 'ZIP Code',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(fontSize: 15.sp, color: const Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }
}

