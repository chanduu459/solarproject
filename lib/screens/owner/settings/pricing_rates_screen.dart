import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PricingRatesScreen extends ConsumerStatefulWidget {
  const PricingRatesScreen({super.key});

  @override
  ConsumerState<PricingRatesScreen> createState() => _PricingRatesScreenState();
}

class _PricingRatesScreenState extends ConsumerState<PricingRatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _laborRateController = TextEditingController();
  final _installationRateController = TextEditingController();
  final _maintenanceRateController = TextEditingController();
  final _emergencyRateController = TextEditingController();
  final _travelRateController = TextEditingController();
  final _taxRateController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPricing();
  }

  @override
  void dispose() {
    _laborRateController.dispose();
    _installationRateController.dispose();
    _maintenanceRateController.dispose();
    _emergencyRateController.dispose();
    _travelRateController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _laborRateController.text = prefs.getString('labor_rate') ?? '500';
      _installationRateController.text = prefs.getString('installation_rate') ?? '5000';
      _maintenanceRateController.text = prefs.getString('maintenance_rate') ?? '1000';
      _emergencyRateController.text = prefs.getString('emergency_rate') ?? '2000';
      _travelRateController.text = prefs.getString('travel_rate') ?? '10';
      _taxRateController.text = prefs.getString('tax_rate') ?? '18';
      _isLoading = false;
    });
  }

  Future<void> _savePricing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('labor_rate', _laborRateController.text.trim());
      await prefs.setString('installation_rate', _installationRateController.text.trim());
      await prefs.setString('maintenance_rate', _maintenanceRateController.text.trim());
      await prefs.setString('emergency_rate', _emergencyRateController.text.trim());
      await prefs.setString('travel_rate', _travelRateController.text.trim());
      await prefs.setString('tax_rate', _taxRateController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pricing saved successfully'),
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
          'Pricing & Rates',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePricing,
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

                    // Info Card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: const Color(0xFFFF8F00), size: 24.w),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Set your standard rates. These will be used for quotations and invoices.',
                              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF5D4037)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('SERVICE RATES (₹)'),
                    SizedBox(height: 12.h),

                    _buildRateCard(
                      controller: _laborRateController,
                      title: 'Labor Rate',
                      subtitle: 'Per hour',
                      icon: Icons.engineering_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _buildRateCard(
                      controller: _installationRateController,
                      title: 'Installation Rate',
                      subtitle: 'Per panel',
                      icon: Icons.solar_power_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _buildRateCard(
                      controller: _maintenanceRateController,
                      title: 'Maintenance Rate',
                      subtitle: 'Per visit',
                      icon: Icons.build_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _buildRateCard(
                      controller: _emergencyRateController,
                      title: 'Emergency Rate',
                      subtitle: 'Per call-out',
                      icon: Icons.emergency_outlined,
                    ),

                    SizedBox(height: 24.h),
                    _buildSectionTitle('OTHER CHARGES'),
                    SizedBox(height: 12.h),

                    _buildRateCard(
                      controller: _travelRateController,
                      title: 'Travel Rate',
                      subtitle: 'Per km',
                      icon: Icons.directions_car_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _buildRateCard(
                      controller: _taxRateController,
                      title: 'Tax Rate',
                      subtitle: 'GST %',
                      icon: Icons.receipt_outlined,
                      suffix: '%',
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

  Widget _buildRateCard({
    required TextEditingController controller,
    required String title,
    required String subtitle,
    required IconData icon,
    String? suffix,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 24.w, color: const Color(0xFF1A237E)),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100.w,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
              decoration: InputDecoration(
                prefixText: suffix == null ? '₹ ' : '',
                suffixText: suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

