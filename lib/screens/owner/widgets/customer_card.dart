import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24.w,
                  backgroundColor: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF1E88E5),
                    size: 28.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        customer.email,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        customer.phone,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              customer.fullAddress,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade800),
            ),
            if (customer.notes != null && customer.notes!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                customer.notes!,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

