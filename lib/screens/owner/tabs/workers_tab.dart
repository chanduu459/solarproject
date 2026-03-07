import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../widgets/worker_card.dart';
import '../dialogs/add_worker_dialog.dart';

class WorkersTab extends ConsumerStatefulWidget {
  const WorkersTab({super.key});

  @override
  ConsumerState<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends ConsumerState<WorkersTab> {
  @override
  void initState() {
    super.initState();
    // Load workers on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workersProvider.notifier).loadAllWorkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workersAsyncValue = ref.watch(workersProvider);

    return Column(
      children: [
        // Add Worker Button
        Padding(
          padding: EdgeInsets.all(16.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddWorkerDialog(),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add New Worker'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ),
        // Workers List
        Expanded(
          child: workersAsyncValue.when(
            data: (workers) {
              if (workers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64.w,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No workers yet',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Add your first worker to get started',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  return WorkerCard(
                    worker: worker,
                    onEdit: () {
                      // TODO: Implement edit worker
                    },
                    onDelete: () {
                      _showDeleteConfirmation(context, worker.id);
                    },
                    onStatusChange: (newStatus) {
                      _toggleWorkerStatus(worker.id, newStatus);
                    },
                  );
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF1E88E5),
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64.w,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Failed to load workers',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(workersProvider.notifier).loadAllWorkers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleWorkerStatus(String workerId, bool newStatus) {
    ref.read(workersProvider.notifier).toggleWorkerStatus(workerId, newStatus);
  }

  void _showDeleteConfirmation(BuildContext context, String workerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Worker'),
        content: const Text('Are you sure you want to delete this worker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(workersProvider.notifier).deleteWorker(workerId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Worker deleted')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

