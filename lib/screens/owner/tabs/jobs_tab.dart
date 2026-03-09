import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../../../models/job_model.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
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
    });
  }

  Future<void> _refresh() async {
    await ref.read(jobsProvider.notifier).loadAllJobs();
    await ref.read(workersProvider.notifier).loadAllWorkers();
    await ref.read(customersProvider.notifier).loadAllCustomers();
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

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final workersAsync = ref.watch(workersProvider);
    final customersAsync = ref.watch(customersProvider);
    final workers = workersAsync.asData?.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF1A237E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Customers "Quick Assign" Section
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                    child: Text('Client Quick-Assign', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  ),
                  SizedBox(
                    height: 140.h,
                    child: customersAsync.when(
                      data: (customers) {
                        if (customers.isEmpty) {
                          return Center(child: Text('No customers available', style: TextStyle(color: Colors.grey.shade600)));
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return _buildCustomerQuickCard(customer, customers, workers);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)))),
                      error: (_, __) => Center(child: TextButton(onPressed: () => ref.read(customersProvider.notifier).loadAllCustomers(), child: const Text('Retry Loading Customers'))),
                    ),
                  ),
                ],
              ),
            ),

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
                      return _buildJobCard(job, workersAsync, workers);
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

  Widget _buildCustomerQuickCard(CustomerModel customer, List<CustomerModel> customers, List<UserModel>? workers) {
    return Container(
      width: 220.w,
      margin: EdgeInsets.only(right: 12.w, bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: const Color(0xFF99D37F).withOpacity(0.2), // Solar Amber
                  child: Text(customer.fullName[0].toUpperCase(), style: TextStyle(color: const Color(
                      0xFF3A7066), fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(customer.fullName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.phone, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  height: 32.h,
                  child: OutlinedButton(
                    onPressed: () => _showCreateJobSheet(customers, workers ?? [], preselectedCustomerId: customer.id),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    ),
                    child: Text('Create Job', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(JobModel job, AsyncValue<List<UserModel>> workersAsync, List<UserModel>? workers) {
    final customerName = job.customer?.fullName ?? 'Unknown Customer';
    final scheduledDate = job.scheduledDate.toLocal().toString().split(' ').first;
    final assignedLabel = job.workerName ?? 'Unassigned';
    final isUnassigned = job.workerId == null;

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
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(customerName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
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
    );
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