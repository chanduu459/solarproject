import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.shield_outlined, size: 48.w, color: const Color(0xFF1A237E)),
                  SizedBox(height: 12.h),
                  Text(
                    'SolarPulse Pro',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Last Updated: March 10, 2026',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            _buildSection(
              title: '1. Information We Collect',
              content: '''We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support.

Types of information we collect include:
• Personal information (name, email, phone number)
• Location data for tracking and job management
• Device information and usage statistics
• Photos and documents uploaded through the app''',
            ),

            _buildSection(
              title: '2. How We Use Your Information',
              content: '''We use the information we collect to:
• Provide, maintain, and improve our services
• Process transactions and send related information
• Send technical notices and support messages
• Respond to your comments and questions
• Track worker locations for job management purposes
• Generate reports and analytics for your business''',
            ),

            _buildSection(
              title: '3. Information Sharing',
              content: '''We do not sell, trade, or rent your personal information to third parties. We may share information:
• With your consent
• With service providers who assist in our operations
• To comply with legal obligations
• To protect our rights and safety
• In connection with a business transfer or merger''',
            ),

            _buildSection(
              title: '4. Data Security',
              content: '''We implement appropriate security measures to protect your personal information, including:
• Encryption of data in transit and at rest
• Secure server infrastructure
• Regular security audits
• Access controls and authentication
• Employee training on data protection''',
            ),

            _buildSection(
              title: '5. Location Data',
              content: '''Our app collects location data to enable features such as:
• Worker tracking and attendance management
• Job location verification
• Route optimization
• Real-time status updates

You can disable location services in your device settings, but some features may not function properly.''',
            ),

            _buildSection(
              title: '6. Data Retention',
              content: '''We retain your information for as long as your account is active or as needed to provide services. We may retain certain information as required by law or for legitimate business purposes.''',
            ),

            _buildSection(
              title: '7. Your Rights',
              content: '''You have the right to:
• Access your personal information
• Correct inaccurate data
• Request deletion of your data
• Export your data
• Opt-out of marketing communications
• Withdraw consent where applicable''',
            ),

            _buildSection(
              title: '8. Contact Us',
              content: '''If you have questions about this Privacy Policy, please contact us at:

Email: privacy@solarpulsepro.com
Phone: +91 1800-123-4567
Address: Solar Tower, Tech Park, Bangalore - 560001''',
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              content,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

