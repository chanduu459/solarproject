import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../login_screen.dart';
import 'job_list_screen.dart';
import 'attendance_screen.dart';
import 'profile_screen.dart';
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
    final user = ref.watch(authProvider).user;
    final jobsState = ref.watch(jobsProvider);
    final attendanceState = ref.watch(attendanceProvider);

    final screens = [
      const _HomeTab(),
      const JobListScreen(),
      const AttendanceScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Worker Dashboard',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final jobsState = ref.watch(jobsProvider);
    final attendanceState = ref.watch(attendanceProvider);

    final todayJobs = jobsState.todayJobs;
    final isCheckedIn = attendanceState.isCheckedIn;

    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await ref.read(jobsProvider.notifier).loadTodayJobs(user.id);
          await ref.read(attendanceProvider.notifier).loadActiveAttendance(user.id);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Hello, ${user?.fullName ?? 'Worker'}!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Here\'s your work overview for today',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            // Status card
            _buildStatusCard(context, isCheckedIn, todayJobs.length),
            SizedBox(height: 24.h),
            // Today's jobs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Jobs',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to jobs tab
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (todayJobs.isEmpty)
              _buildEmptyJobsCard()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayJobs.length > 3 ? 3 : todayJobs.length,
                itemBuilder: (context, index) {
                  return _JobCard(job: todayJobs[index]);
                },
              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isCheckedIn, int jobCount) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCheckedIn
              ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
              : [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  isCheckedIn ? Icons.check_circle : Icons.access_time,
                  color: Colors.white,
                  size: 32.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Currently Working' : 'Not Checked In',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      isCheckedIn
                          ? 'You are checked in and ready to work'
                          : 'Check in to start your work day',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Today\'s Jobs', jobCount.toString()),
              _buildStatItem('Status', isCheckedIn ? 'Active' : 'Inactive'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyJobsCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.work_off,
            size: 48.w,
            color: Colors.grey,
          ),
          SizedBox(height: 12.h),
          Text(
            'No jobs scheduled for today',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.camera_alt,
            label: 'Upload Photo',
            color: const Color(0xFF43A047),
            onTap: () {
              // TODO: Navigate to photo upload
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.report_problem,
            label: 'Report Issue',
            color: const Color(0xFFE53935),
            onTap: () {
              // TODO: Navigate to issue report
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.check_circle,
            label: 'Complete Job',
            color: const Color(0xFF1E88E5),
            onTap: () {
              // TODO: Navigate to job completion
            },
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
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      // 1. Wrap with InkWell to make it clickable
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          // 2. Navigate to the Update Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobUpdateScreen(
                jobId: job.id,
                jobTitle: job.customer?.fullName ?? 'customer',
                initialProgress: job.progressPercentage,
                currentAddress: job.address, // Must exist in JobModel
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
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: job.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      job.statusDisplay,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: job.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16.w, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      job.customer?.address ?? 'No address',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.solar_power, size: 16.w, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    '${job.panelQuantity}x ${job.panelType}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              LinearProgressIndicator(
                value: job.progressPercentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  job.progressPercentage == 100
                      ? const Color(0xFF43A047)
                      : const Color(0xFF1E88E5),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${job.progressPercentage}% Complete',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey,
                ),
              ),
            ],
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

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28.w),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
