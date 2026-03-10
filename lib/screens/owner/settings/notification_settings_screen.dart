import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _newJobAlerts = true;
  bool _issueAlerts = true;
  bool _workerUpdates = true;
  bool _dailyReports = false;
  bool _weeklyReports = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _newJobAlerts = prefs.getBool('new_job_alerts') ?? true;
      _issueAlerts = prefs.getBool('issue_alerts') ?? true;
      _workerUpdates = prefs.getBool('worker_updates') ?? true;
      _dailyReports = prefs.getBool('daily_reports') ?? false;
      _weeklyReports = prefs.getBool('weekly_reports') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('new_job_alerts', _newJobAlerts);
    await prefs.setBool('issue_alerts', _issueAlerts);
    await prefs.setBool('worker_updates', _workerUpdates);
    await prefs.setBool('daily_reports', _dailyReports);
    await prefs.setBool('weekly_reports', _weeklyReports);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 1),
        ),
      );
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
          'Notifications',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),

                  // General Notifications
                  _buildSectionTitle('GENERAL'),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications on your device',
                      icon: Icons.notifications_outlined,
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Email Notifications',
                      subtitle: 'Receive updates via email',
                      icon: Icons.email_outlined,
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                        _saveSettings();
                      },
                    ),
                  ]),

                  SizedBox(height: 24.h),

                  // Alert Preferences
                  _buildSectionTitle('ALERTS'),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      title: 'New Job Alerts',
                      subtitle: 'Get notified when new jobs are created',
                      icon: Icons.work_outline,
                      value: _newJobAlerts,
                      onChanged: (value) {
                        setState(() => _newJobAlerts = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Issue Alerts',
                      subtitle: 'Get notified when issues are reported',
                      icon: Icons.warning_amber_outlined,
                      value: _issueAlerts,
                      onChanged: (value) {
                        setState(() => _issueAlerts = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Worker Updates',
                      subtitle: 'Get notified about worker activities',
                      icon: Icons.people_outline,
                      value: _workerUpdates,
                      onChanged: (value) {
                        setState(() => _workerUpdates = value);
                        _saveSettings();
                      },
                    ),
                  ]),

                  SizedBox(height: 24.h),

                  // Reports
                  _buildSectionTitle('REPORTS'),
                  SizedBox(height: 12.h),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      title: 'Daily Reports',
                      subtitle: 'Receive daily summary reports',
                      icon: Icons.today_outlined,
                      value: _dailyReports,
                      onChanged: (value) {
                        setState(() => _dailyReports = value);
                        _saveSettings();
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Weekly Reports',
                      subtitle: 'Receive weekly summary reports',
                      icon: Icons.date_range_outlined,
                      value: _weeklyReports,
                      onChanged: (value) {
                        setState(() => _weeklyReports = value);
                        _saveSettings();
                      },
                    ),
                  ]),

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

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 20.w, color: const Color(0xFF1A237E)),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF1A237E).withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1A237E);
              }
              return Colors.grey.shade400;
            }),
          ),
        ],
      ),
    );
  }
}


