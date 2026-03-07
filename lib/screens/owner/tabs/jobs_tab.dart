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
      builder: (ctx) {
        String? selectedWorkerId = job.workerId;
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Worker',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    value: selectedWorkerId,
                    decoration: const InputDecoration(labelText: 'Select worker'),
                    items: workers
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedWorkerId = val),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                                    const SnackBar(
                                      content: Text('Worker assigned successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to assign worker'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? SizedBox(
                              height: 18.h,
                              width: 18.w,
                              child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Text('Assign'),
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

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final workersAsync = ref.watch(workersProvider);
    final customersAsync = ref.watch(customersProvider);
    final workers = workersAsync.asData?.value;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  customersAsync.whenOrNull(data: (customers) {
                    final workerList = workersAsync.asData?.value ?? [];
                    _showCreateJobSheet(customers, workerList);
                  });
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Text('Customers', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text('No customers available yet', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700)),
                  );
                }
                return Column(
                  children: customers
                      .map(
                        (customer) => Card(
                          margin: EdgeInsets.only(bottom: 10.h),
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.fullName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4.h),
                                Text(customer.email, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                                SizedBox(height: 4.h),
                                Text(customer.phone, style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showCreateJobSheet(
                                        customers,
                                        workers ?? [],
                                        preselectedCustomerId: customer.id,
                                      ),
                                      icon: const Icon(Icons.person_add_alt_1),
                                      label: const Text('Add & Assign'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1E88E5),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (workers == null || workers.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 6.h),
                                    child: Text(
                                      'Load workers to assign jobs',
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Column(
                  children: [
                    Text('Failed to load customers', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                    TextButton(
                      onPressed: () => ref.read(customersProvider.notifier).loadAllCustomers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
            child: Text('Jobs', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          ),
          if (jobsState.isLoading && jobsState.jobs.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (!jobsState.isLoading && jobsState.jobs.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Text('No jobs found', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700)),
            ),
          ...jobsState.jobs.map((job) {
            final customerName = job.customer?.fullName ?? 'Unknown Customer';
            final scheduledDate = job.scheduledDate.toLocal().toString().split(' ').first;
            final assignedLabel = job.workerName ?? 'Unassigned';

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: job.statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              job.statusDisplay,
                              style: TextStyle(fontSize: 12.sp, color: job.statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16),
                          SizedBox(width: 6.w),
                          Text('Scheduled: $scheduledDate', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          const Icon(Icons.badge, size: 16),
                          SizedBox(width: 6.w),
                          Text('Assigned: $assignedLabel', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700)),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: workersAsync.maybeWhen(
                              data: (workers) => () => _showAssignSheet(job, workers),
                              orElse: () => null,
                            ),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: Text(job.workerId == null ? 'Assign' : 'Reassign'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 16.h),
        ],
      ),
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
}



