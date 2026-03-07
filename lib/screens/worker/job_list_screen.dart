import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
// Note: We don't need job_detail_screen.dart anymore if we are using JobUpdateScreen
import '../../providers/job_update_screen.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    // Wrap in microtask to prevent the "setState during build" error!
    Future.microtask(() => _loadJobs());
  }

  Future<void> _loadJobs() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(jobsProvider.notifier).loadWorkerJobs(user.id);
    }
  }

  List<JobModel> _getFilteredJobs(List<JobModel> jobs) {
    if (_filterStatus == 'all') return jobs;
    return jobs.where((job) => job.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final filteredJobs = _getFilteredJobs(jobsState.jobs);

    return Column(
      children: [
        // Filter chips
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: 8.w),
                _buildFilterChip('Pending', 'pending'),
                SizedBox(width: 8.w),
                _buildFilterChip('In Progress', 'in_progress'),
                SizedBox(width: 8.w),
                _buildFilterChip('Completed', 'completed'),
              ],
            ),
          ),
        ),
        // Job list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadJobs,
            child: jobsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredJobs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: filteredJobs.length,
              itemBuilder: (context, index) {
                return _JobListItem(
                  job: filteredJobs[index],
                  onTap: () => _navigateToJobUpdate(filteredJobs[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      selectedColor: const Color(0xFF1E88E5).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1E88E5),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_off,
            size: 64.w,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'No jobs found',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You don\'t have any $_filterStatus jobs',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Changed this function to navigate to your new JobUpdateScreen
  void _navigateToJobUpdate(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobUpdateScreen(
          jobId: job.id,
          jobTitle: job.customer?.fullName ?? 'Customer',
          initialProgress: job.progressPercentage,
          currentAddress: job.address, // This will work once Step 1 & 2 are done
          currentLat: job.latitude,    // This will work once Step 1 & 2 are done
          currentLng: job.longitude,   // This will work once Step 1 & 2 are done
        ),
      ),
    );
  }
}

class _JobListItem extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobListItem({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.customer?.fullName ?? 'Unknown Customer',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          job.scheduledDate.toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: job.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
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
              SizedBox(height: 12.h),
              Divider(height: 1.h, color: Colors.grey.shade200),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18.w, color: Colors.grey),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      job.customer?.fullAddress ?? 'No address',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.solar_power_outlined, size: 18.w, color: Colors.grey),
                  SizedBox(width: 8.w),
                  Text(
                    '${job.panelQuantity}x ${job.panelType}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: job.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        job.progressPercentage == 100
                            ? const Color(0xFF43A047)
                            : const Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '${job.progressPercentage}%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: job.progressPercentage == 100
                          ? const Color(0xFF43A047)
                          : const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}