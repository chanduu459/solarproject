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

  // Enterprise Color Palette for Priorities
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F3D); // Deep Red
      case 'high':
        return const Color(0xFFBC58D1); // Alert Orange
      case 'medium':
        return const Color(0xFF2B4763); // Solar Amber
      case 'low':
        return const Color(0xFF2E7D32); // Success Green
      default:
        return Colors.grey.shade600;
    }
  }

  // Enterprise Color Palette for Statuses
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFFD32F2F); // Needs attention
      case 'in_progress':
        return const Color(0xFF1E88E5); // Active Blue
      case 'resolved':
        return const Color(0xFF2E7D32); // Completed Green
      default:
        return Colors.grey.shade600;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white background
      body: Column(
        children: [
          _buildModernHeader(issuesState),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadIssues,
              color: const Color(0xFF1A237E),
              child: _buildMainContent(issuesState, filteredIssues),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODERN PROFESSIONAL HEADER ---
  Widget _buildModernHeader(dynamic issuesState) {
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
                          'Issue Reports',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${issuesState.issues.length} total issues',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Quick Stats Badge
                    if (issuesState.openIssues.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD32F2F),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${issuesState.openIssues.length} Open',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildCustomFilterChip('All', 'all', issuesState.issues.length),
                      SizedBox(width: 8.w),
                      _buildCustomFilterChip('Open', 'open', issuesState.openIssues.length),
                      SizedBox(width: 8.w),
                      _buildCustomFilterChip('In Progress', 'in_progress', issuesState.inProgressIssues.length),
                      SizedBox(width: 8.w),
                      _buildCustomFilterChip('Resolved', 'resolved', issuesState.resolvedIssues.length),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MODERN REFINED FILTER PILLS ---
  Widget _buildCustomFilterChip(String label, String status, int count) {
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

  Widget _buildMainContent(dynamic issuesState, List<IssueReportModel> filteredIssues) {
    if (issuesState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E))),
      );
    }

    if (issuesState.error != null) {
      return _buildErrorState(issuesState.error!);
    }

    if (filteredIssues.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: filteredIssues.length,
      itemBuilder: (context, index) => _buildIssueCard(filteredIssues[index]),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.task_alt_rounded,
              size: 64.w,
              color: const Color(0xFF2E7D32).withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _filterStatus == 'all' ? 'Inbox Zero' : 'No ${_getStatusDisplay(_filterStatus)} Issues',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
          ),
          SizedBox(height: 8.h),
          Text(
            _filterStatus == 'all' ? 'All systems are running smoothly.' : 'No issues found under this filter.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMsg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64.w, color: const Color(0xFFD32F2F)),
          SizedBox(height: 16.h),
          Text('Data Sync Failed', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(errorMsg, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadIssues,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(IssueReportModel issue) {
    final priorityColor = _getPriorityColor(issue.priority);
    final statusColor = _getStatusColor(issue.status);

    return GestureDetector(
      onTap: () => _showIssueDetails(issue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: priorityColor, width: 4.w),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showIssueDetails(issue),
                borderRadius: BorderRadius.circular(20.r),
                child: Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              issue.issueType,
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
                          _buildStatusBadge(issue.status, statusColor),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        issue.description,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade600,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          _buildPriorityBadge(issue.priority, priorityColor),
                          const Spacer(),
                          Icon(Icons.person_outline_rounded, size: 15.w, color: Colors.grey.shade500),
                          SizedBox(width: 6.w),
                          Text(
                            issue.reportedBy ?? issue.workerName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Icon(Icons.access_time_rounded, size: 15.w, color: Colors.grey.shade500),
                          SizedBox(width: 6.w),
                          Text(
                            _formatDate(issue.reportedAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
                        SizedBox(height: 14.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 16.w,
                                color: const Color(0xFF1E88E5),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '${issue.imageUrls!.length} Attachment${issue.imageUrls!.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF1E88E5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- REFINED BADGES ---
  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _getStatusDisplay(status),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 13.w, color: color),
          SizedBox(width: 5.w),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) return '${difference.inMinutes}m ago';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IssueDetailsDialog(issue: issue),
    );
  }
}

class _IssueDetailsDialog extends ConsumerWidget {
  final IssueReportModel issue;

  const _IssueDetailsDialog({required this.issue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(issue.status);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)),
            ),
          ),

          // Header Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue.issueType,
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.black54),
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildDetailBadge(_getStatusDisplay(issue.status), statusColor, isSolid: true),
                      SizedBox(width: 8.w),
                      _buildDetailBadge(issue.priority.toUpperCase(), _getPriorityColor(issue.priority)),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  Text('Description', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                  SizedBox(height: 8.h),
                  Text(issue.description, style: TextStyle(fontSize: 15.sp, color: const Color(0xFF1A1A1A), height: 1.5)),

                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline, 'Reported by', issue.reportedBy ?? issue.workerName ?? 'Unknown'),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Reported on', '${issue.reportedAt.day}/${issue.reportedAt.month}/${issue.reportedAt.year} at ${issue.reportedAt.hour}:${issue.reportedAt.minute.toString().padLeft(2, '0')}'),
                        if (issue.customerName != null) ...[
                          const Divider(height: 24),
                          _buildInfoRow(Icons.home_outlined, 'Customer', issue.customerName!),
                        ],
                      ],
                    ),
                  ),

                  if (issue.resolutionNotes != null && issue.resolutionNotes!.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.green.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 18.w),
                              SizedBox(width: 8.w),
                              Text('Resolution Notes', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(issue.resolutionNotes!, style: TextStyle(fontSize: 14.sp, color: Colors.green.shade900)),
                        ],
                      ),
                    ),
                  ],

                  if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
                    SizedBox(height: 24.h),
                    Text('Attachments', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 100.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: issue.imageUrls!.length,
                        itemBuilder: (context, index) {
                          final url = issue.imageUrls![index];
                          return GestureDetector(
                            onTap: () => _showFullImage(context, url),
                            child: Container(
                              margin: EdgeInsets.only(right: 12.w),
                              width: 100.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.grey.shade200),
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

              // Action Buttons Bottom Bar
          if (issue.status != 'resolved')
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h), // Safe area bottom padding
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Row(
                children: [
                  if (issue.status == 'open')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(context, ref, 'in_progress'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: const BorderSide(color: Color(0xFF1E88E5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('Start Progress', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5))),
                      ),
                    ),
                  if (issue.status == 'open') SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showResolveDialog(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: Text('Resolve Issue', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(String text, Color color, {bool isSolid = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isSolid ? color : color.withValues(alpha: 0.1),
        border: isSolid ? null : Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: isSolid ? Colors.white : color),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: Colors.grey.shade500),
        SizedBox(width: 12.w),
        Text(label, style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return const Color(0xFFD32F2F);
      case 'high': return const Color(0xFFB37984);
      case 'medium': return const Color(0xFF7FCA77);
      case 'low': return const Color(0xFF597D2E);
      default: return Colors.grey.shade600;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return const Color(0xFFD32F2F);
      case 'in_progress': return const Color(0xFF1E88E5);
      case 'resolved': return const Color(0xFF2E7D32);
      default: return Colors.grey.shade600;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return status;
    }
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(4.w),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(issuesProvider.notifier).updateIssueStatus(issueId: issue.id, status: status);
      // Reload all issues to refresh the UI
      await ref.read(issuesProvider.notifier).loadAllIssues();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to ${_getStatusDisplay(status)}'), backgroundColor: const Color(0xFF2E7D32)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
    }
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Resolve Issue'),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: 'Resolution Notes',
            hintText: 'Enter details on how this was fixed...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF2E7D32))),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(issuesProvider.notifier).updateIssueStatus(issueId: issue.id, status: 'resolved', resolutionNotes: notesController.text.trim());
                // Reload all issues to refresh the UI
                await ref.read(issuesProvider.notifier).loadAllIssues();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  Navigator.pop(context); // Close bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue resolved successfully'), backgroundColor: Color(0xFF2E7D32)));
                }
              } catch (e) {
                if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Failed to resolve: $e'), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
            child: const Text('Resolve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}