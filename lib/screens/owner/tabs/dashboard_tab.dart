import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_button.dart';
import '../dialogs/add_worker_dialog.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final bool isLoading;

  const DashboardTab({
    super.key,
    required this.statistics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement manual refresh logic
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Real-time insights of your operations',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            // Statistics grid
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStatisticsGrid(),
            SizedBox(height: 24.h),
            // Quick actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            _buildQuickActions(context),
            SizedBox(height: 24.h),
            // Recent activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final stats = [
      {
        'title': 'Active Workers',
        'value': statistics['workers_active_today']?.toString() ?? '0',
        'icon': Icons.people,
        'color': const Color(0xFF1E88E5),
      },
      {
        'title': 'Jobs Today',
        'value': statistics['total_jobs']?.toString() ?? '0',
        'icon': Icons.work,
        'color': const Color(0xFF43A047),
      },
      {
        'title': 'Completed',
        'value': statistics['completed_today']?.toString() ?? '0',
        'icon': Icons.check_circle,
        'color': const Color(0xFF43A047),
      },
      {
        'title': 'Pending',
        'value': statistics['pending_jobs']?.toString() ?? '0',
        'icon': Icons.pending,
        'color': const Color(0xFFFFA726),
      },
      {
        'title': 'In Progress',
        'value': statistics['in_progress_jobs']?.toString() ?? '0',
        'icon': Icons.timelapse,
        'color': const Color(0xFF9E9E9E),
      },
      {
        'title': 'Open Issues',
        'value': statistics['open_issues']?.toString() ?? '0',
        'icon': Icons.report_problem,
        'color': const Color(0xFFE53935),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickActionButton(
            icon: Icons.person_add,
            label: 'Add Worker',
            color: const Color(0xFF1E88E5),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AddWorkerDialog(),
              );
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: QuickActionButton(
            icon: Icons.add_circle,
            label: 'Create Job',
            color: const Color(0xFF43A047),
            onTap: () {
              // TODO: Navigate to create job
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: QuickActionButton(
            icon: Icons.assessment,
            label: 'Reports',
            color: const Color(0xFFFFA726),
            onTap: () {
              // TODO: Navigate to reports
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.check_circle,
            color: Colors.green,
            title: 'Job completed',
            subtitle: 'Solar installation at 123 Main St',
            time: '2 hours ago',
          ),
          Divider(height: 24.h),
          _buildActivityItem(
            icon: Icons.login,
            color: Colors.blue,
            title: 'Worker checked in',
            subtitle: 'John Doe started work',
            time: '3 hours ago',
          ),
          Divider(height: 24.h),
          _buildActivityItem(
            icon: Icons.report_problem,
            color: Colors.orange,
            title: 'Issue reported',
            subtitle: 'Missing equipment at job site',
            time: '5 hours ago',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

