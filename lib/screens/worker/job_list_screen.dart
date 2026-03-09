import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../providers/job_update_screen.dart';
import '../../widgets/report_issue_dialog.dart';

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
    final allJobs = jobsState.jobs;
    final filteredJobs = _getFilteredJobs(allJobs);

    // Calculate dynamic counts for the filter pills
    final pendingCount = allJobs.where((j) => j.status == 'pending').length;
    final inProgressCount = allJobs.where((j) => j.status == 'in_progress').length;
    final completedCount = allJobs.where((j) => j.status == 'completed').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white background
      body: Column(
        children: [
          // Modern Professional Header
          _buildModernHeader(
            allJobs: allJobs,
            filteredJobs: filteredJobs,
            allCount: allJobs.length,
            pendingCount: pendingCount,
            inProgressCount: inProgressCount,
            completedCount: completedCount,
          ),

          // Main Job List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadJobs,
              color: const Color(0xFF1A237E), // Brand primary
              child: jobsState.isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E))))
                  : filteredJobs.isEmpty
                  ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState(),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  return _JobListItem(
                    job: job,
                    onTap: () => _navigateToJobUpdate(job),
                    onReportIssue: () => ReportIssueDialog.show(
                      context,
                      jobId: job.id,
                      customerName: job.customer?.fullName ?? 'Unknown Customer',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader({
    required List<JobModel> allJobs,
    required List<JobModel> filteredJobs,
    required int allCount,
    required int pendingCount,
    required int inProgressCount,
    required int completedCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Stats Section
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Jobs',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (allCount > 0) ...[
                      SizedBox(height: 4.h),
                      Text(
                        _filterStatus == 'all'
                            ? '$allCount total jobs'
                            : '${filteredJobs.length} of $allCount jobs',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                // Active Jobs Badge
                if (inProgressCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E88E5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '$inProgressCount Active',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Row(
              children: [
                _buildModernFilterChip('All', 'all', allCount),
                SizedBox(width: 8.w),
                _buildModernFilterChip('Pending', 'pending', pendingCount),
                SizedBox(width: 8.w),
                _buildModernFilterChip('In Progress', 'in_progress', inProgressCount),
                SizedBox(width: 8.w),
                _buildModernFilterChip('Completed', 'completed', completedCount),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildModernFilterChip(String label, String status, int count) {
    final isSelected = _filterStatus == status;

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title = 'No Jobs';
    String subtitle = 'Your schedule is clear for this category.';

    if (_filterStatus == 'pending') {
      title = 'No Pending Jobs';
      subtitle = 'All jobs have been started or completed.';
    } else if (_filterStatus == 'in_progress') {
      title = 'No Active Jobs';
      subtitle = 'Start a pending job to see it here.';
    } else if (_filterStatus == 'completed') {
      title = 'No Completed Jobs';
      subtitle = 'Completed jobs will appear here.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 64.w,
              color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToJobUpdate(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobUpdateScreen(
          jobId: job.id,
          jobTitle: job.customer?.fullName ?? 'Customer',
          initialProgress: job.progressPercentage,
          currentAddress: job.location,
          currentLat: job.latitude,
          currentLng: job.longitude,
        ),
      ),
    );
  }
}

// Modern Professional Job Card
class _JobListItem extends StatefulWidget {
  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onReportIssue;

  const _JobListItem({
    required this.job,
    required this.onTap,
    required this.onReportIssue,
  });

  @override
  State<_JobListItem> createState() => _JobListItemState();
}

class _JobListItemState extends State<_JobListItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.job.statusColor,
                  width: 4.w,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Customer Name & Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.job.customer?.fullName ?? 'Unknown Customer',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _buildStatusBadge(),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Date Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15.w,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        widget.job.scheduledDate.toString().split(' ')[0],
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Location & Panel Info
                  if (widget.job.location != null && widget.job.location!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 15.w,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            widget.job.location!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.solar_power_outlined,
                        size: 15.w,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        '${widget.job.panelQuantity}x ${widget.job.panelType}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${widget.job.progressPercentage}%',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.job.progressPercentage == 100
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF1E88E5),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: LinearProgressIndicator(
                          value: widget.job.progressPercentage / 100,
                          minHeight: 8.h,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.job.progressPercentage == 100
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Action Buttons
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.warning_rounded,
                          label: 'Report Issue',
                          color: const Color(0xFFE53935),
                          onPressed: widget.onReportIssue,
                        ),
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

  Widget _buildStatusBadge() {
    String label;
    Color color;

    switch (widget.job.status) {
      case 'pending':
        label = 'Pending';
        color = const Color(0xFFFF9800);
        break;
      case 'in_progress':
        label = 'In Progress';
        color = const Color(0xFF1E88E5);
        break;
      case 'completed':
        label = 'Completed';
        color = const Color(0xFF2E7D32);
        break;
      default:
        label = 'Unknown';
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.w, color: color),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}