import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../login_screen.dart';
import 'job_list_screen.dart';
import 'attendance_screen.dart';
import 'profile_screen.dart';
import 'issues_screen.dart';
import '../../providers/job_update_screen.dart';

class WorkerDashboard extends ConsumerStatefulWidget {
  const WorkerDashboard({super.key});

  @override
  ConsumerState<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends ConsumerState<WorkerDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(jobsProvider.notifier).loadWorkerJobs(user.id);
      await ref.read(jobsProvider.notifier).loadTodayJobs(user.id);
      await ref.read(attendanceProvider.notifier).loadActiveAttendance(user.id);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeTab(onLogout: _signOut), // Passing logout to the custom header
      const JobListScreen(),
      const AttendanceScreen(),
      const WorkerIssuesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white background
      // Removed global AppBar to match Owner Dashboard architecture
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.1),
        indicatorColor: const Color(0xFFFFB300).withOpacity(0.2), // Solar Amber
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.black54),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1A237E)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline, color: Colors.black54),
            selectedIcon: Icon(Icons.work, color: Color(0xFF1A237E)),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time, color: Colors.black54),
            selectedIcon: Icon(Icons.access_time_filled, color: Color(0xFF1A237E)),
            label: 'Time',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined, color: Colors.black54),
            selectedIcon: Icon(Icons.report_problem, color: Color(0xFFD32F2F)), // Keep issues red
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.black54),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1A237E)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final VoidCallback onLogout;

  const _HomeTab({required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final jobsState = ref.watch(jobsProvider);
    final attendanceState = ref.watch(attendanceProvider);

    final todayJobs = jobsState.todayJobs;
    final isCheckedIn = attendanceState.isCheckedIn;

    return RefreshIndicator(
      color: const Color(0xFF1A237E),
      onRefresh: () async {
        if (user != null) {
          await ref.read(jobsProvider.notifier).loadTodayJobs(user.id);
          await ref.read(attendanceProvider.notifier).loadActiveAttendance(user.id);
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Custom Enterprise Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h), // Top padding accounts for status bar
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monday, March 9', // Future integration: make dynamic
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Hi, ${user?.fullName?.split(' ').first ?? 'Worker'}',
                        style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1A1A)),
                          onPressed: () { /* TODO */ },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                        child: IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Color(0xFFD32F2F)),
                          onPressed: onLogout,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status Hero Card
                _buildStatusCard(context, isCheckedIn, todayJobs.length),
                SizedBox(height: 32.h),

                // Quick Actions
                Text('Quick Actions', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                SizedBox(height: 16.h),
                _buildQuickActions(context),
                SizedBox(height: 32.h),

                // Today's Jobs Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Today\'s Schedule', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    TextButton(
                      onPressed: () { /* Navigate to jobs tab */ },
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E88E5)),
                      child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Jobs List
                if (todayJobs.isEmpty)
                  _buildEmptyJobsCard()
                else
                  ...todayJobs.take(3).map((job) => _JobCard(job: job)),

                SizedBox(height: 40.h), // Bottom safe space
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildStatusCard(BuildContext context, bool isCheckedIn, int jobCount) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCheckedIn
              ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)] // Success Green Gradient
              : [const Color(0xFF1A237E), const Color(0xFF0D47A1)], // Deep Navy Gradient
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? const Color(0xFF2E7D32) : const Color(0xFF1A237E)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  isCheckedIn ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                  color: Colors.white,
                  size: 28.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Active Shift' : 'Off Duty',
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isCheckedIn ? 'You are checked in and tracking time.' : 'Check in to start your work day.',
                      style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Assigned Today', jobCount.toString().padLeft(2, '0')),
                Container(width: 1, height: 40.h, color: Colors.white.withOpacity(0.2)),
                _buildStatItem('Status', isCheckedIn ? 'Online' : 'Offline'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyJobsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: const Color(0xFFF1F3F4), shape: BoxShape.circle),
            child: Icon(Icons.event_available_rounded, size: 40.w, color: const Color(0xFF1A237E)),
          ),
          SizedBox(height: 16.h),
          Text('Clear Schedule', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
          SizedBox(height: 8.h),
          Text('You have no installations assigned for today.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_a_photo_rounded,
            label: 'Site Photo',
            color: const Color(0xFF1E88E5), // Blue
            onTap: () { /* TODO */ },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.warning_amber_rounded,
            label: 'Report Issue',
            color: const Color(0xFFD32F2F), // Red
            onTap: () { /* TODO */ },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.task_alt_rounded,
            label: 'Finish Job',
            color: const Color(0xFF2E7D32), // Green
            onTap: () { /* TODO */ },
          ),
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: job.statusColor, width: 6.w)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobUpdateScreen(
                    jobId: job.id,
                    jobTitle: job.customer?.fullName ?? 'Customer',
                    initialProgress: job.progressPercentage,
                    currentAddress: job.location,
                    currentLat: job.latitude,
                    currentLng: job.longitude,
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          job.customer?.fullName ?? 'Unknown Customer',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(color: job.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
                        child: Text(
                          job.statusDisplay,
                          style: TextStyle(fontSize: 11.sp, color: job.statusColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16.w, color: Colors.grey.shade500),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          job.customer?.address ?? 'No address provided',
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.solar_power_outlined, size: 16.w, color: Colors.grey.shade500),
                      SizedBox(width: 8.w),
                      Text('${job.panelQuantity}x ${job.panelType}', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Modernized Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: job.progressPercentage / 100,
                            minHeight: 6.h,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              job.progressPercentage == 100 ? const Color(0xFF2E7D32) : const Color(0xFFFFB300), // Amber for in-progress
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '${job.progressPercentage}%',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24.w),
              ),
              SizedBox(height: 12.h),
              Text(
                label,
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}