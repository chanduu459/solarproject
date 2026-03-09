import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../../../models/models.dart';

class IssuesTab extends ConsumerStatefulWidget {
  const IssuesTab({super.key});

  @override
  ConsumerState<IssuesTab> createState() => _IssuesTabState();
}

class _IssuesTabState extends ConsumerState<IssuesTab> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadIssues());
  }

  Future<void> _loadIssues() async {
    await ref.read(issuesProvider.notifier).loadAllIssues();
  }

  List<IssueReportModel> _getFilteredIssues(List<IssueReportModel> issues) {
    if (_filterStatus == 'all') return issues;
    return issues.where((issue) => issue.status == _filterStatus).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final issuesState = ref.watch(issuesProvider);
    final filteredIssues = _getFilteredIssues(issuesState.issues);

    return Column(
      children: [
        // Filter chips
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', issuesState.issues.length),
                SizedBox(width: 8.w),
                _buildFilterChip('Open', 'open', issuesState.openIssues.length),
                SizedBox(width: 8.w),
                _buildFilterChip('In Progress', 'in_progress', issuesState.inProgressIssues.length),
                SizedBox(width: 8.w),
                _buildFilterChip('Resolved', 'resolved', issuesState.resolvedIssues.length),
              ],
            ),
          ),
        ),

        // Issues list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadIssues,
            child: issuesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : issuesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48.w, color: Colors.red),
                            SizedBox(height: 16.h),
                            Text(
                              'Error loading issues',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              issuesState.error!,
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _loadIssues,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredIssues.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16.w),
                            itemCount: filteredIssues.length,
                            itemBuilder: (context, index) {
                              return _buildIssueCard(filteredIssues[index]);
                            },
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String status, int count) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF1E88E5) : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
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
            Icons.check_circle_outline,
            size: 80.w,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            _filterStatus == 'all' ? 'No Issues Reported' : 'No ${_getStatusDisplay(_filterStatus)} Issues',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _filterStatus == 'all'
                ? 'All systems running smoothly!'
                : 'No issues with this status',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(IssueReportModel issue) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showIssueDetails(issue),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Issue type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(issue.priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: _getPriorityColor(issue.priority).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            issue.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(issue.priority),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            issue.issueType,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(issue.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getStatusDisplay(issue.status),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(issue.status),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Description
              Text(
                issue.description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),

              // Footer: Worker and date
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16.w, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    issue.reportedBy ?? issue.workerName ?? 'Unknown',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16.w, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(issue.reportedAt),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ],
              ),

              // Show images indicator if any
              if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.photo_library, size: 16.w, color: Colors.blue),
                    SizedBox(width: 4.w),
                    Text(
                      '${issue.imageUrls!.length} photo(s) attached',
                      style: TextStyle(fontSize: 12.sp, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showIssueDetails(IssueReportModel issue) {
    showDialog(
      context: context,
      builder: (context) => _IssueDetailsDialog(issue: issue),
    );
  }
}

class _IssueDetailsDialog extends ConsumerWidget {
  final IssueReportModel issue;

  const _IssueDetailsDialog({required this.issue});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        width: 360.w,
        constraints: BoxConstraints(maxHeight: 600.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _getStatusColor(issue.status).withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.issueType,
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(issue.priority),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                issue.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _getStatusColor(issue.status),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                _getStatusDisplay(issue.status),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      issue.description,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 16.h),

                    // Reporter info
                    _buildInfoRow(Icons.person, 'Reported by', issue.reportedBy ?? issue.workerName ?? 'Unknown'),
                    SizedBox(height: 8.h),
                    _buildInfoRow(Icons.calendar_today, 'Reported on',
                        '${issue.reportedAt.day}/${issue.reportedAt.month}/${issue.reportedAt.year} at ${issue.reportedAt.hour}:${issue.reportedAt.minute.toString().padLeft(2, '0')}'),

                    if (issue.customerName != null) ...[
                      SizedBox(height: 8.h),
                      _buildInfoRow(Icons.home, 'Customer', issue.customerName!),
                    ],

                    if (issue.resolvedAt != null) ...[
                      SizedBox(height: 8.h),
                      _buildInfoRow(Icons.check_circle, 'Resolved on',
                          '${issue.resolvedAt!.day}/${issue.resolvedAt!.month}/${issue.resolvedAt!.year}'),
                    ],

                    if (issue.resolutionNotes != null && issue.resolutionNotes!.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'Resolution Notes',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        issue.resolutionNotes!,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ],

                    // Images
                    if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'Photos',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: issue.imageUrls!.map((url) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: GestureDetector(
                              onTap: () => _showFullImage(context, url),
                              child: Image.network(
                                url,
                                width: 80.w,
                                height: 80.h,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80.w,
                                    height: 80.h,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (issue.status != 'resolved')
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    if (issue.status == 'open')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus(context, ref, 'in_progress'),
                          child: const Text('Mark In Progress'),
                        ),
                      ),
                    if (issue.status == 'open') SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showResolveDialog(context, ref),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Resolve', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: Colors.grey),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Photo'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200.h,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image, size: 48)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(issuesProvider.notifier).updateIssueStatus(
            issueId: issue.id,
            status: status,
          );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issue status updated to ${_getStatusDisplay(status)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve Issue'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Resolution Notes',
            hintText: 'Enter resolution details...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(issuesProvider.notifier).updateIssueStatus(
                      issueId: issue.id,
                      status: 'resolved',
                      resolutionNotes: notesController.text.trim(),
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Issue resolved successfully')),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Failed to resolve: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
