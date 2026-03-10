import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../widgets/worker_card.dart';
import '../widgets/worker_details_sheet.dart';
import '../dialogs/add_worker_dialog.dart';
import '../dialogs/edit_worker_dialog.dart';

class WorkersTab extends ConsumerStatefulWidget {
  const WorkersTab({super.key});

  @override
  ConsumerState<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends ConsumerState<WorkersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _statusFilter; // null = all, 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workersProvider.notifier).loadAllWorkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(workersProvider.notifier).loadAllWorkers();
  }

  // Filter workers based on search and status filter
  List<dynamic> _getFilteredWorkers(List<dynamic> workers) {
    var filtered = workers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((worker) {
        final name = worker.fullName.toLowerCase();
        final email = worker.email.toLowerCase();
        final phone = worker.phone?.toLowerCase() ?? '';
        final id = worker.id.toLowerCase();

        return name.contains(_searchQuery) ||
               email.contains(_searchQuery) ||
               phone.contains(_searchQuery) ||
               id.contains(_searchQuery);
      }).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      if (_statusFilter == 'active') {
        filtered = filtered.where((worker) => worker.isActive).toList();
      } else if (_statusFilter == 'inactive') {
        filtered = filtered.where((worker) => !worker.isActive).toList();
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final workersAsyncValue = ref.watch(workersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white
      body: Column(
        children: [
          _buildDirectoryHeader(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF1A237E), // Deep Navy
              child: workersAsyncValue.when(
                data: (workers) {
                  final filteredWorkers = _getFilteredWorkers(workers);

                  if (workers.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: _buildEmptyState(),
                      ),
                    );
                  }

                  if (filteredWorkers.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: _buildNoResultsState(),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 88.h), // Extra bottom padding for FAB
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: filteredWorkers.length,
                    itemBuilder: (context, index) {
                      final worker = filteredWorkers[index];
                      return GestureDetector(
                        onTap: () => _showWorkerDetails(worker),
                        child: WorkerCard(
                          worker: worker,
                          onEdit: () => _showEditWorkerDialog(worker),
                          onDelete: () => _showDeleteConfirmation(context, worker.id),
                          onStatusChange: (newStatus) => _toggleWorkerStatus(worker.id, newStatus),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                  ),
                ),
                error: (error, stack) => _buildErrorState(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddWorkerDialog(), // Ensure AddWorkerDialog has const constructor if possible
          );
        },
        backgroundColor: const Color(0xFF1A237E), // Brand primary
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text(
          'New Worker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildDirectoryHeader(BuildContext context) {
    final workersAsyncValue = ref.watch(workersProvider);
    final totalWorkers = workersAsyncValue.maybeWhen(
      data: (workers) => workers.length,
      orElse: () => 0,
    );
    final filteredCount = workersAsyncValue.maybeWhen(
      data: (workers) => _getFilteredWorkers(workers).length,
      orElse: () => 0,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field Team',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (totalWorkers > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _searchQuery.isNotEmpty || _statusFilter != null
                          ? '$filteredCount of $totalWorkers workers'
                          : '$totalWorkers total workers',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (_statusFilter != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusFilter == 'active' ? Icons.check_circle : Icons.cancel,
                        size: 14.w,
                        color: const Color(0xFF1A237E),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _statusFilter == 'active' ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search workers by name or ID...',
                      hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 20.sp),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600, size: 20.sp),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                height: 48.h,
                width: 48.h,
                decoration: BoxDecoration(
                  color: _statusFilter != null ? const Color(0xFF1A237E) : Colors.white,
                  border: Border.all(
                    color: _statusFilter != null ? const Color(0xFF1A237E) : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: _statusFilter != null ? Colors.white : const Color(0xFF1A237E),
                    size: 22.sp,
                  ),
                  onPressed: _showFilterOptions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
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
          child: Icon(Icons.engineering_rounded, size: 64.w, color: const Color(0xFFFFB300)), // Solar Amber
        ),
        SizedBox(height: 24.h),
        Text(
          'No Team Members',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Add your first field worker to start assigning jobs.',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState() {
    return Column(
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
          child: Icon(Icons.search_off_rounded, size: 64.w, color: Colors.grey.shade400),
        ),
        SizedBox(height: 24.h),
        Text(
          'No Workers Found',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _searchQuery.isNotEmpty
              ? 'No workers match "$_searchQuery"'
              : 'No workers match the selected filter',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 16.h),
        TextButton.icon(
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _statusFilter = null;
            });
          },
          icon: const Icon(Icons.clear_all_rounded),
          label: const Text('Clear Filters'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1A237E),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64.w, color: const Color(0xFFD32F2F)),
            SizedBox(height: 16.h),
            Text(
              'Connection Failed',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD32F2F),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Logic Methods ---

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Workers',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                if (_statusFilter != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _statusFilter = null;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: const Color(0xFF1A237E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildFilterOption(
              icon: Icons.people_rounded,
              title: 'All Workers',
              isSelected: _statusFilter == null,
              onTap: () {
                setState(() {
                  _statusFilter = null;
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 12.h),
            _buildFilterOption(
              icon: Icons.check_circle_rounded,
              title: 'Active Only',
              isSelected: _statusFilter == 'active',
              color: const Color(0xFF2E7D32),
              onTap: () {
                setState(() {
                  _statusFilter = 'active';
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 12.h),
            _buildFilterOption(
              icon: Icons.cancel_rounded,
              title: 'Inactive Only',
              isSelected: _statusFilter == 'inactive',
              color: const Color(0xFFD32F2F),
              onTap: () {
                setState(() {
                  _statusFilter = 'inactive';
                });
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? const Color(0xFF1A237E);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isSelected ? effectiveColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                size: 20.w,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? effectiveColor : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: effectiveColor,
                size: 24.w,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleWorkerStatus(String workerId, bool newStatus) {
    ref.read(workersProvider.notifier).toggleWorkerStatus(workerId, newStatus);
  }

  void _showWorkerDetails(dynamic worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkerDetailsSheet(worker: worker),
    );
  }

  void _showEditWorkerDialog(dynamic worker) {
    showDialog(
      context: context,
      builder: (context) => EditWorkerDialog(worker: worker),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String workerId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            const Text('Remove Worker'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this worker profile? This action cannot be undone.',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, height: 1.4),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(workersProvider.notifier).deleteWorker(workerId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Worker successfully removed.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F), // Destructive Red
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Delete Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}