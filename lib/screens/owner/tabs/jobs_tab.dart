import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../../../models/job_model.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
import '../../../models/issue_report_model.dart';
import '../dialogs/create_job_dialog.dart';

class JobsTab extends ConsumerStatefulWidget {
  const JobsTab({super.key});

  @override
  ConsumerState<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends ConsumerState<JobsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).loadAllJobs();
      ref.read(workersProvider.notifier).loadAllWorkers();
      ref.read(customersProvider.notifier).loadAllCustomers();
      ref.read(issuesProvider.notifier).loadAllIssues();
    });
  }

  Future<void> _refresh() async {
    await ref.read(jobsProvider.notifier).loadAllJobs();
    await ref.read(workersProvider.notifier).loadAllWorkers();
    await ref.read(customersProvider.notifier).loadAllCustomers();
    await ref.read(issuesProvider.notifier).loadAllIssues();
  }

  void _showAssignSheet(JobModel job, List<UserModel> workers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String? selectedWorkerId = job.workerId;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 24.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  Text(
                    'Assign Field Worker',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Select a team member to handle this installation.',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 24.h),

                  // Modern Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedWorkerId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1A237E)),
                      decoration: InputDecoration(
                        labelText: 'Select Worker',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      ),
                      items: workers.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedWorkerId = val),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      onPressed: isSubmitting || selectedWorkerId == null
                          ? null
                          : () async {
                        setModalState(() => isSubmitting = true);
                        try {
                          await ref.read(jobsProvider.notifier).assignWorkerToJob(
                            jobId: job.id,
                            workerId: selectedWorkerId!,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Worker assigned successfully'),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              ),
                            );
                          }
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Failed to assign worker'),
                                backgroundColor: const Color(0xFFD32F2F),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              ),
                            );
                          }
                        } finally {
                          setModalState(() => isSubmitting = false);
                        }
                      },
                      child: isSubmitting
                          ? SizedBox(height: 20.h, width: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Text('Confirm Assignment', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateJobSheet(List<CustomerModel> customers, List<UserModel> workers, {String? preselectedCustomerId}) {
    showDialog(
      context: context,
      builder: (ctx) => CreateJobDialog(
        customers: customers,
        workers: workers,
        preselectedCustomerId: preselectedCustomerId,
      ),
    );
  }

  void _showJobDetailsSheet(JobModel job) {
    final customer = job.customer;
    final workerName = job.workerName ?? 'Unassigned';
    final isUnassigned = job.workerId == null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h + MediaQuery.of(context).padding.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

                // Header with Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job Details',
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: job.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        job.statusDisplay,
                        style: TextStyle(fontSize: 12.sp, color: job.statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Customer Section
                _buildDetailSection(
                  title: 'CUSTOMER DETAILS',
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFF1A237E),
                  children: [
                    _buildDetailRow('Name', customer?.fullName ?? 'Unknown'),
                    _buildDetailRow('Phone', customer?.phone ?? 'N/A'),
                    _buildDetailRow('Email', customer?.email ?? 'N/A'),
                    _buildDetailRow('Address', customer?.fullAddress ?? 'N/A'),
                  ],
                ),
                SizedBox(height: 20.h),

                // Assigned Worker Section
                _buildDetailSection(
                  title: 'ASSIGNED WORKER',
                  icon: Icons.engineering_rounded,
                  iconColor: isUnassigned ? Colors.red.shade400 : const Color(0xFF2E7D32),
                  children: [
                    _buildDetailRow(
                      'Worker',
                      workerName,
                      valueColor: isUnassigned ? Colors.red.shade600 : null,
                    ),
                    if (!isUnassigned) _buildDetailRow('Status', 'Active'),
                  ],
                ),
                SizedBox(height: 20.h),

                // Job Info Section
                _buildDetailSection(
                  title: 'JOB INFORMATION',
                  icon: Icons.solar_power_rounded,
                  iconColor: const Color(0xFFFF9800),
                  children: [
                    _buildDetailRow('Panel Type', job.panelType),
                    _buildDetailRow('Quantity', '${job.panelQuantity} panels'),
                    _buildDetailRow('Scheduled Date', job.scheduledDate.toLocal().toString().split(' ').first),
                    _buildDetailRow('Progress', '${job.progressPercentage}%'),
                    if (job.priority != null) _buildDetailRow('Priority', job.priority!.toUpperCase()),
                    if (job.notes != null && job.notes!.isNotEmpty) _buildDetailRow('Notes', job.notes!),
                  ],
                ),
                SizedBox(height: 24.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Close', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          final workers = ref.read(workersProvider).asData?.value ?? [];
                          _showAssignSheet(job, workers);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: Text(
                          isUnassigned ? 'Assign Worker' : 'Reassign',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 18.w, color: iconColor),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final workersAsync = ref.watch(workersProvider);
    final customersAsync = ref.watch(customersProvider);
    final issuesState = ref.watch(issuesProvider);
    final workers = workersAsync.asData?.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF1A237E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [

            // Active Jobs Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Operations', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                      child: Text('${jobsState.jobs.length} Jobs', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    ),
                  ],
                ),
              ),
            ),

            // Jobs List
            if (jobsState.isLoading && jobsState.jobs.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)))))
            else if (!jobsState.isLoading && jobsState.jobs.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 80.h), // Bottom padding for FAB
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final job = jobsState.jobs[index];
                      final jobIssues = issuesState.issues.where((issue) => issue.jobId == job.id).toList();
                      return _buildJobCard(job, workersAsync, workers, jobIssues);
                    },
                    childCount: jobsState.jobs.length,
                  ),
                ),
              ),
          ],
        ),
      ),

      // Floating Action Button replaces the top static button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          customersAsync.whenOrNull(data: (customers) {
            final workerList = workersAsync.asData?.value ?? [];
            _showCreateJobSheet(customers, workerList);
          });
        },
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
      ),
    );
  }

  // --- UI Component Builders ---


  Widget _buildJobCard(JobModel job, AsyncValue<List<UserModel>> workersAsync, List<UserModel>? workers, List<IssueReportModel> jobIssues) {
    final customerName = job.customer?.fullName ?? 'Unknown Customer';
    final scheduledDate = job.scheduledDate.toLocal().toString().split(' ').first;
    final assignedLabel = job.workerName ?? 'Unassigned';
    final isUnassigned = job.workerId == null;
    final totalIssuesCount = jobIssues.length;
    final hasIssues = totalIssuesCount > 0;
    // Check if there are any open/in-progress issues to determine badge color
    final hasOpenIssues = jobIssues.any((i) => i.status == 'open' || i.status == 'in_progress');

    return GestureDetector(
      onTap: () => _showJobDetailsSheet(job),
      child: Container(
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
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(customerName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)), overflow: TextOverflow.ellipsis),
                            ),
                            if (hasIssues) ...[
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: () => _showJobIssuesSheet(job, jobIssues),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: hasOpenIssues ? Colors.red.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: hasOpenIssues ? Colors.red.shade200 : Colors.green.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        hasOpenIssues ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                        size: 14.w,
                                        color: hasOpenIssues ? Colors.red.shade600 : Colors.green.shade600,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text('$totalIssuesCount', style: TextStyle(fontSize: 11.sp, color: hasOpenIssues ? Colors.red.shade600 : Colors.green.shade600, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(color: job.statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
                        child: Text(job.statusDisplay, style: TextStyle(fontSize: 11.sp, color: job.statusColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  const Divider(height: 1),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14.w, color: Colors.grey.shade500),
                                SizedBox(width: 6.w),
                                Text(scheduledDate, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(Icons.engineering_rounded, size: 14.w, color: isUnassigned ? Colors.red.shade400 : Colors.grey.shade500),
                                SizedBox(width: 6.w),
                                Text(
                                    assignedLabel,
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        color: isUnassigned ? Colors.red.shade600 : Colors.grey.shade700,
                                        fontWeight: isUnassigned ? FontWeight.bold : FontWeight.w500
                                    )
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: workersAsync.maybeWhen(
                          data: (workerList) => () => _showAssignSheet(job, workerList),
                          orElse: () => null,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUnassigned ? const Color(0xFF1A237E) : Colors.grey.shade100,
                          foregroundColor: isUnassigned ? Colors.white : const Color(0xFF1A237E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                        child: Text(isUnassigned ? 'Assign' : 'Reassign', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
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

  void _showJobIssuesSheet(JobModel job, List<IssueReportModel> issues) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 24.w),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Issues for ${job.customer?.fullName ?? 'Job'}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                          SizedBox(height: 2.h),
                          Text('${issues.length} issue${issues.length > 1 ? 's' : ''} reported', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              const Divider(height: 1),
              // Issues List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                  itemCount: issues.length,
                  itemBuilder: (context, index) {
                    final issue = issues[index];
                    return _buildIssueCard(issue);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIssueCard(IssueReportModel issue) {
    Color statusColor;
    String statusText;
    switch (issue.status) {
      case 'open':
        statusColor = Colors.red;
        statusText = 'Open';
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusText = 'In Progress';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resolved';
        break;
      default:
        statusColor = Colors.grey;
        statusText = issue.status;
    }

    Color priorityColor;
    switch (issue.priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showIssueDetailsSheet(issue),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(statusText, style: TextStyle(fontSize: 11.sp, color: statusColor, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(issue.priority.toUpperCase(), style: TextStyle(fontSize: 11.sp, color: priorityColor, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(
                  issue.reportedAt.toLocal().toString().split(' ').first,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(issue.issueType, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
            SizedBox(height: 6.h),
            Text(issue.description, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700), maxLines: 3, overflow: TextOverflow.ellipsis),
            if (issue.reportedBy != null || issue.workerName != null) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14.w, color: Colors.grey.shade500),
                  SizedBox(width: 4.w),
                  Text('Reported by: ${issue.reportedBy ?? issue.workerName ?? 'Unknown'}', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                ],
              ),
            ],
            if (issue.resolutionNotes != null && issue.resolutionNotes!.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16.w, color: Colors.green.shade600),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(issue.resolutionNotes!, style: TextStyle(fontSize: 12.sp, color: Colors.green.shade700)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showIssueDetailsSheet(IssueReportModel issue) {
    Color statusColor;
    String statusText;
    switch (issue.status) {
      case 'open':
        statusColor = Colors.red;
        statusText = 'Open';
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        statusText = 'In Progress';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resolved';
        break;
      default:
        statusColor = Colors.grey;
        statusText = issue.status;
    }

    Color priorityColor;
    String priorityText;
    switch (issue.priority) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = 'High Priority';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = 'Medium Priority';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityText = 'Low Priority';
        break;
      default:
        priorityColor = Colors.grey;
        priorityText = issue.priority;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h + MediaQuery.of(context).padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 20.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),

                  // Header with Status
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.warning_amber_rounded, color: statusColor, size: 28.w),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Issue Details', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(statusText, style: TextStyle(fontSize: 11.sp, color: statusColor, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(priorityText, style: TextStyle(fontSize: 11.sp, color: priorityColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Issue Type
                  _buildDetailSection(
                    title: 'ISSUE TYPE',
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFF1A237E),
                    children: [
                      Text(issue.issueType, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Description
                  _buildDetailSection(
                    title: 'DESCRIPTION',
                    icon: Icons.description_rounded,
                    iconColor: Colors.blueGrey,
                    children: [
                      Text(issue.description, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, height: 1.5)),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Status Section
                  _buildDetailSection(
                    title: 'STATUS',
                    icon: Icons.info_rounded,
                    iconColor: statusColor,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(statusText, style: TextStyle(fontSize: 14.sp, color: statusColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Reporter Info
                  _buildDetailSection(
                    title: 'REPORTED BY',
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF2E7D32),
                    children: [
                      _buildDetailRow('Worker', issue.reportedBy ?? issue.workerName ?? 'Unknown'),
                      _buildDetailRow('Date', issue.reportedAt.toLocal().toString().split(' ').first),
                      _buildDetailRow('Time', issue.reportedAt.toLocal().toString().split(' ')[1].substring(0, 5)),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Location (if available)
                  if (issue.latitude != null && issue.longitude != null) ...[
                    _buildDetailSection(
                      title: 'LOCATION',
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.red,
                      children: [
                        _buildDetailRow('Latitude', issue.latitude!.toStringAsFixed(6)),
                        _buildDetailRow('Longitude', issue.longitude!.toStringAsFixed(6)),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Resolution (if resolved)
                  if (issue.status == 'resolved' && issue.resolutionNotes != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 20.w),
                              SizedBox(width: 8.w),
                              Text('RESOLUTION', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.green.shade700, letterSpacing: 0.5)),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(issue.resolutionNotes!, style: TextStyle(fontSize: 14.sp, color: Colors.green.shade800, height: 1.5)),
                          if (issue.resolvedAt != null) ...[
                            SizedBox(height: 8.h),
                            Text('Resolved on: ${issue.resolvedAt!.toLocal().toString().split(' ').first}', style: TextStyle(fontSize: 12.sp, color: Colors.green.shade600)),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Images (if available)
                  if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
                    Text('ATTACHED IMAGES', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.5)),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 120.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: issue.imageUrls!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120.w,
                            margin: EdgeInsets.only(right: 12.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                issue.imageUrls![index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 40.w),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Action Buttons
                  if (issue.status != 'resolved') ...[
                    Row(
                      children: [
                        if (issue.status == 'open') ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateIssueStatus(context, issue, 'in_progress'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                side: const BorderSide(color: Color(0xFF1E88E5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: Text('Start Progress', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5))),
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showResolveIssueDialog(context, issue),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Text('Resolve Issue', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text('Close', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateIssueStatus(BuildContext context, IssueReportModel issue, String status) async {
    try {
      await ref.read(issuesProvider.notifier).updateIssueStatus(
        issueId: issue.id,
        status: status,
      );
      // Reload all issues to refresh the UI
      await ref.read(issuesProvider.notifier).loadAllIssues();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue status updated to ${_getStatusDisplayText(status)}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResolveIssueDialog(BuildContext context, IssueReportModel issue) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: const Color(0xFF2E7D32), size: 24.w),
            SizedBox(width: 12.w),
            const Text('Resolve Issue'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue: ${issue.issueType}',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Resolution Notes',
                hintText: 'Describe how this issue was resolved...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(issuesProvider.notifier).updateIssueStatus(
                  issueId: issue.id,
                  status: 'resolved',
                  resolutionNotes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );
                // Reload all issues to refresh the UI
                await ref.read(issuesProvider.notifier).loadAllIssues();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  Navigator.pop(context); // Close bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Issue resolved successfully!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to resolve: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return status;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.work_outline_rounded, size: 60.w, color: const Color(
                0xFF2F4675)),
          ),
          SizedBox(height: 24.h),
          Text('No Active Jobs', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
          SizedBox(height: 8.h),
          Text('Click the New Job button below to start scheduling.', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}