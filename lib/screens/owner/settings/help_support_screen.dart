import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
          'Help & Support',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent_rounded, size: 60.w, color: Colors.white),
                  SizedBox(height: 16.h),
                  Text(
                    'How can we help you?',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'We\'re here to help you with any questions or issues',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Contact Options
            _buildSectionTitle('CONTACT US'),
            SizedBox(height: 12.h),
            _buildContactCard(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@solarpulsepro.com',
              onTap: () => _launchEmail('support@solarpulsepro.com'),
            ),
            SizedBox(height: 12.h),
            _buildContactCard(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+91 1800-123-4567',
              onTap: () => _launchPhone('+911800123456'),
            ),
            SizedBox(height: 12.h),
            _buildContactCard(
              icon: Icons.chat_outlined,
              title: 'Live Chat',
              subtitle: 'Chat with our support team',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live chat coming soon!')),
                );
              },
            ),

            SizedBox(height: 24.h),

            // FAQs
            _buildSectionTitle('FREQUENTLY ASKED QUESTIONS'),
            SizedBox(height: 12.h),
            _buildFAQCard(
              context,
              question: 'How do I add a new worker?',
              answer: 'Go to the Workers tab from the bottom navigation, then tap the + button to add a new worker. Fill in their details and save.',
            ),
            SizedBox(height: 12.h),
            _buildFAQCard(
              context,
              question: 'How do I create a new job?',
              answer: 'Navigate to the Jobs tab and tap the + button. Select the customer, assign a worker, and fill in the job details.',
            ),
            SizedBox(height: 12.h),
            _buildFAQCard(
              context,
              question: 'How can workers report issues?',
              answer: 'Workers can report issues from their dashboard by clicking on a job and selecting "Report Issue". They can add photos and descriptions.',
            ),
            SizedBox(height: 12.h),
            _buildFAQCard(
              context,
              question: 'How do I track worker locations?',
              answer: 'Worker locations are automatically tracked when they check in. You can view their current location from the Workers tab.',
            ),

            SizedBox(height: 24.h),

            // Resources
            _buildSectionTitle('RESOURCES'),
            SizedBox(height: 12.h),
            _buildResourceCard(
              icon: Icons.book_outlined,
              title: 'User Guide',
              onTap: () => _launchUrl('https://solarpulsepro.com/guide'),
            ),
            SizedBox(height: 12.h),
            _buildResourceCard(
              icon: Icons.video_library_outlined,
              title: 'Video Tutorials',
              onTap: () => _launchUrl('https://solarpulsepro.com/tutorials'),
            ),
            SizedBox(height: 12.h),
            _buildResourceCard(
              icon: Icons.article_outlined,
              title: 'Knowledge Base',
              onTap: () => _launchUrl('https://solarpulsepro.com/kb'),
            ),

            SizedBox(height: 40.h),
          ],
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: const Color(0xFF1A237E), size: 24.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.w, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context, {required String question, required String answer}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        title: Text(
          question,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A237E), size: 24.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            ),
            Icon(Icons.open_in_new, size: 18.w, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

