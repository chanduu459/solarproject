import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 32.h),

              // --- Profile Header ---
              _buildProfileHeader(user),

              SizedBox(height: 32.h),

              // --- Contact Information ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('CONTACT INFORMATION'),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildInfoItem(Icons.email_outlined, 'Email Address', user?.email ?? 'Not set'),
                          const Divider(height: 1),
                          _buildInfoItem(Icons.phone_outlined, 'Phone Number', user?.phone ?? 'Not set'),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // --- Account Settings ---
                    _buildSectionTitle('ACCOUNT SETTINGS'),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildActionItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit Profile',
                            onTap: () { /* TODO: Navigate */ },
                          ),
                          const Divider(height: 1),
                          _buildActionItem(
                            icon: Icons.lock_outline_rounded,
                            title: 'Change Password',
                            onTap: () { /* TODO: Navigate */ },
                          ),
                          const Divider(height: 1),
                          _buildActionItem(
                            icon: Icons.notifications_none_rounded,
                            title: 'Notifications',
                            onTap: () { /* TODO: Navigate */ },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // --- App Settings ---
                    _buildSectionTitle('SYSTEM'),
                    SizedBox(height: 12.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildActionItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            onTap: () { /* TODO: Navigate */ },
                          ),
                          const Divider(height: 1),
                          _buildActionItem(
                            icon: Icons.shield_outlined,
                            title: 'Privacy Policy',
                            onTap: () { /* TODO: Navigate */ },
                          ),
                          const Divider(height: 1),
                          _buildActionItem(
                            icon: Icons.info_outline_rounded,
                            title: 'About App',
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // --- Sign Out Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _signOut(context, ref),
                        icon: const Icon(Icons.logout_rounded, color: Colors.white),
                        label: Text('Sign Out', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F), // Destructive Red
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        Container(
          width: 110.w,
          height: 110.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white, width: 4.w),
          ),
          child: user?.avatarUrl != null
              ? ClipOval(child: Image.network(user!.avatarUrl!, fit: BoxFit.cover))
              : Container(
            decoration: BoxDecoration(color: const Color(0xFFF1F3F4), shape: BoxShape.circle),
            child: Icon(Icons.person_rounded, size: 50.w, color: const Color(0xFF1A237E)),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          user?.fullName ?? 'Unknown Worker',
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.5),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            (user?.role ?? 'Field Worker').toUpperCase(),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E), letterSpacing: 1.0),
          ),
        ),
      ],
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(icon, size: 20.w, color: Colors.grey.shade600),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                SizedBox(height: 4.h),
                Text(value, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(icon, size: 20.w, color: const Color(0xFF1A237E)), // Deep Navy
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            ),
            Icon(Icons.chevron_right_rounded, size: 24.w, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        contentPadding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.solar_power_rounded, size: 56.w, color: const Color(0xFF1A237E)),
            ),
            SizedBox(height: 24.h),
            Text('SolarPulse Pro', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12.r)),
              child: Text('Version 2.1.0', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 24.h),
            Text(
              'Enterprise tracking solution for field operations, installation management, and workforce deployment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600, height: 1.5),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Close', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}