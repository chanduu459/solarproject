import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../dialogs/add_worker_dialog.dart';
import 'settings_tab.dart';

class DashboardTab extends StatelessWidget {
  final Map<String, dynamic> statistics;
  final bool isLoading;
  final VoidCallback onLogout;
  final Function(int)? onTabChange; // Added your new tab routing function

  const DashboardTab({
    super.key,
    required this.statistics,
    required this.isLoading,
    required this.onLogout,
    this.onTabChange, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement manual refresh logic
      },
      color: const Color(0xFF1A237E),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Live Operations'),
                  SizedBox(height: 16.h),

                  isLoading
                      ? Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
                  )
                      : _buildAnalyticsDashboard(),

                  SizedBox(height: 32.h),
                  _buildSectionTitle('Quick Actions'),
                  SizedBox(height: 16.h),
                  _buildQuickActions(context),

                  SizedBox(height: 32.h),
                  _buildSectionTitle('Activity Log'),
                  SizedBox(height: 16.h),
                  _buildRecentActivity(),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130.h,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFF1A237E),
      elevation: 0,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: PopupMenuButton<String>(
            offset: Offset(0, 50.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            elevation: 8,
            color: Colors.white,
            icon: CircleAvatar(
              radius: 18.r,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 20.sp),
            ),
            onSelected: (value) {
              if (value == 'notifications') {
                // TODO: Show notifications
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsTab()),
                );
              } else if (value == 'logout') {
                onLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: Colors.grey.shade800, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text('Notifications', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF263238), fontFamily: 'Roboto')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.grey.shade800, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text('Settings', style: TextStyle(fontSize: 14.sp, color: const Color(0xFF263238), fontFamily: 'Roboto')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: const Color(0xFFD50000), size: 20.sp),
                    SizedBox(width: 12.w),
                    Text('Sign Out', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFFD50000), fontFamily: 'Roboto')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Good Morning,',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70, fontFamily: 'Roboto'),
              ),
              Text(
                'Owner Dashboard',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF263238),
        letterSpacing: -0.3,
        fontFamily: 'Roboto',
      ),
    );
  }

  Widget _buildAnalyticsDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHorizontalMetricsBar(),
        SizedBox(height: 24.h),
        _buildCompletionDoughnutChart(),
        SizedBox(height: 16.h),
        _buildWeeklyActivityLineChart(),
      ],
    );
  }

  Widget _buildHorizontalMetricsBar() {
    final metrics = [
      {'title': 'Active Workers', 'value': statistics['total_active_workers']?.toString() ?? '0', 'icon': Icons.engineering_outlined, 'color': const Color(0xFF1E88E5)},
      {'title': 'Jobs Today', 'value': statistics['total_jobs']?.toString() ?? '0', 'icon': Icons.solar_power_outlined, 'color': const Color(0xFF43A047)},
      {'title': 'In Progress', 'value': statistics['in_progress_jobs']?.toString() ?? '0', 'icon': Icons.sync, 'color': const Color(0xFF8E24AA)},
      {'title': 'Completed', 'value': statistics['completed_jobs']?.toString() ?? '0', 'icon': Icons.task_alt, 'color': const Color(0xFF00C853)},
      {'title': 'Pending', 'value': statistics['pending_jobs']?.toString() ?? '0', 'icon': Icons.hourglass_empty, 'color': const Color(0xFFFFA726)},
      {
        'title': 'Issues',
        'value': ((statistics['open_issues'] ?? 0) + (statistics['in_progress_issues'] ?? 0)).toString(),
        'icon': Icons.error_outline,
        'color': const Color(0xFFD50000)
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: metrics.map((metric) {
          return Container(
            width: 130.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(color: (metric['color'] as Color).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: (metric['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(metric['icon'] as IconData, color: metric['color'] as Color, size: 20.sp),
                ),
                SizedBox(height: 12.h),
                Text(
                  metric['value'] as String,
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontFamily: 'Roboto'),
                ),
                SizedBox(height: 4.h),
                Text(
                  metric['title'] as String,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade500, fontFamily: 'Roboto'),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletionDoughnutChart() {
    final completed = double.tryParse(statistics['completed_jobs']?.toString() ?? '0') ?? 0;
    final inProgress = double.tryParse(statistics['in_progress_jobs']?.toString() ?? '0') ?? 0;
    final pending = double.tryParse(statistics['pending_jobs']?.toString() ?? '0') ?? 0;

    final total = completed + inProgress + pending;
    final hasData = total > 0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Execution Status', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF111827), fontFamily: 'Roboto')),
          SizedBox(height: 20.h),
          SizedBox(
            height: 180.h,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40.r,
                          sections: hasData ? [
                            PieChartSectionData(color: const Color(0xFF00C853), value: completed, title: '', radius: 16.r),
                            PieChartSectionData(color: const Color(0xFF1E88E5), value: inProgress, title: '', radius: 16.r),
                            PieChartSectionData(color: const Color(0xFFFFA726), value: pending, title: '', radius: 16.r),
                          ] : [
                            PieChartSectionData(color: Colors.grey.shade200, value: 1, title: '', radius: 16.r),
                          ],
                        ),
                      ),
                      Text(
                        hasData ? '${((completed / total) * 100).toInt()}%' : '0%',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontFamily: 'Roboto'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegend(color: const Color(0xFF00C853), label: 'Completed', value: completed.toInt().toString()),
                      SizedBox(height: 12.h),
                      _buildChartLegend(color: const Color(0xFF1E88E5), label: 'In Progress', value: inProgress.toInt().toString()),
                      SizedBox(height: 12.h),
                      _buildChartLegend(color: const Color(0xFFFFA726), label: 'Pending', value: pending.toInt().toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend({required Color color, required String label, required String value}) {
    return Row(
      children: [
        Container(width: 10.w, height: 10.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, fontFamily: 'Roboto')),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontFamily: 'Roboto')),
      ],
    );
  }

  Widget _buildWeeklyActivityLineChart() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7-Day Job Activity', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: const Color(0xFF111827), fontFamily: 'Roboto')),
          SizedBox(height: 24.h),
          SizedBox(
            height: 160.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 10, fontFamily: 'Roboto');
                        switch (value.toInt()) {
                          case 0: return const Text('Mon', style: style);
                          case 2: return const Text('Wed', style: style);
                          case 4: return const Text('Fri', style: style);
                          case 6: return const Text('Sun', style: style);
                          default: return const Text('');
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [FlSpot(0, 3), FlSpot(1, 1), FlSpot(2, 4), FlSpot(3, 2), FlSpot(4, 5), FlSpot(5, 3), FlSpot(6, 6)],
                    isCurved: true,
                    color: const Color(0xFF1A237E),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionChip(Icons.person_add_alt_1, 'Add Worker', const Color(0xFF1E88E5), () {
            showDialog(context: context, builder: (context) => AddWorkerDialog());
          }),
          SizedBox(width: 12.w),
          _buildActionChip(Icons.add_task, 'Create Job', const Color(0xFF43A047), () {
            // Updated your logic here to utilize the onTabChange routing
            if (onTabChange != null) {
              onTabChange!(3);
            }
          }),
          SizedBox(width: 12.w),
          _buildActionChip(Icons.analytics_outlined, 'Reports', const Color(0xFFFFA726), () {
            // TODO: Navigate to reports
          }),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: const Color(0xFF263238), fontFamily: 'Roboto')),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildTimelineTile(icon: Icons.check_circle, color: const Color(0xFF00C853), title: 'Job completed', subtitle: 'Solar installation at 123 Main St', time: '2h ago', isFirst: true),
          _buildTimelineTile(icon: Icons.login, color: const Color(0xFF1E88E5), title: 'Worker checked in', subtitle: 'John Doe started work', time: '3h ago'),
          _buildTimelineTile(icon: Icons.error_outline, color: const Color(0xFFD50000), title: 'Issue reported', subtitle: 'Missing equipment at job site', time: '5h ago', isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({required IconData icon, required Color color, required String title, required String subtitle, required String time, bool isFirst = false, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18.w),
              ),
              if (!isLast) Container(height: 30.h, width: 2.w, color: Colors.grey.shade200, margin: EdgeInsets.only(top: 4.h)),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: const Color(0xFF263238), fontFamily: 'Roboto')),
                SizedBox(height: 4.h),
                Text(subtitle, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, fontFamily: 'Roboto')),
              ],
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade400, fontFamily: 'Roboto')),
        ],
      ),
    );
  }
}