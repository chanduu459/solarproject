import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';

class WorkerIssuesScreen extends ConsumerStatefulWidget {
  const WorkerIssuesScreen({super.key});

  @override
  ConsumerState<WorkerIssuesScreen> createState() => _WorkerIssuesScreenState();
}

class _WorkerIssuesScreenState extends ConsumerState<WorkerIssuesScreen> {
  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(issuesProvider.notifier).loadWorkerIssues(user.id);
    }
  }

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental closing while filling out
      builder: (context) => const _ReportIssueDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issuesState = ref.watch(issuesProvider);
    final workerIssues = issuesState.issues.where((issue) {
      final user = ref.read(authProvider).user;
      return issue.workerId == user?.id;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white
      body: Column(
        children: [
          _buildScreenHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadIssues,
              color: const Color(0xFF1A237E),
              child: issuesState.isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E))))
                  : workerIssues.isEmpty
                  ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState(),
                ),
              )
                  : ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 88.h), // FAB padding
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: workerIssues.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  return _IssueCard(issue: workerIssues[index]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportIssueDialog,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: Text('Report Issue', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFD32F2F), // Destructive red to indicate alert creation
        elevation: 4,
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h), // Top padding for status bar
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Reported Issues',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Track blockages, hazards, or equipment problems.',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
        ],
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
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Icon(Icons.check_circle_outline_rounded, size: 64.w, color: const Color(0xFF2E7D32).withOpacity(0.5)),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Issues Reported',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
          ),
          SizedBox(height: 8.h),
          Text(
            'All your sites are running smoothly!',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IssueReportModel issue;

  const _IssueCard({required this.issue});

  // Enterprise Priority Colors
  Color _getPriorityColor() {
    switch (issue.priority.toLowerCase()) {
      case 'critical': return const Color(0xFFD32F2F);
      case 'high': return const Color(0xFFF57C00);
      case 'medium': return const Color(0xFFFFB300);
      case 'low': return const Color(0xFF2E7D32);
      default: return Colors.grey.shade600;
    }
  }

  // Enterprise Status Colors
  Color _getStatusColor() {
    switch (issue.status.toLowerCase()) {
      case 'open': return const Color(0xFFD32F2F);
      case 'in_progress': return const Color(0xFF1E88E5);
      case 'resolved': return const Color(0xFF2E7D32);
      default: return Colors.grey.shade600;
    }
  }

  String _getStatusDisplay() {
    switch (issue.status.toLowerCase()) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return issue.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();
    final statusColor = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: priorityColor, width: 6.w)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        issue.issueType,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _buildBadge(_getStatusDisplay(), statusColor, isSolid: issue.status == 'resolved'),
                  ],
                ),
                SizedBox(height: 8.h),

                // Description
                Text(
                  issue.description,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16.h),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                SizedBox(height: 12.h),

                // Footer Info
                Row(
                  children: [
                    _buildPriorityBadge(issue.priority, priorityColor),
                    const Spacer(),
                    Icon(Icons.access_time_rounded, size: 14.w, color: Colors.grey.shade500),
                    SizedBox(width: 4.w),
                    Text(
                      _formatDateTime(issue.reportedAt),
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                // Attachments Indicator
                if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8.r)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 14.w, color: const Color(0xFF1E88E5)),
                        SizedBox(width: 6.w),
                        Text(
                          '${issue.imageUrls!.length} Attachment(s)',
                          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF1E88E5), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],

                // Resolution Box
                if (issue.status == 'resolved' && issue.resolutionNotes != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 16.w),
                            SizedBox(width: 6.w),
                            Text(
                              'HQ Resolution',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          issue.resolutionNotes!,
                          style: TextStyle(fontSize: 13.sp, color: Colors.green.shade900, height: 1.4),
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
    );
  }

  Widget _buildBadge(String text, Color color, {bool isSolid = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isSolid ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: isSolid ? Colors.white : color),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12.w, color: color),
          SizedBox(width: 4.w),
          Text(
            priority.toUpperCase(),
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}

// --- Modernized Report Dialog ---

class _ReportIssueDialog extends ConsumerStatefulWidget {
  const _ReportIssueDialog();

  @override
  ConsumerState<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends ConsumerState<_ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIssueType = AppConstants.issueTypes.isNotEmpty ? AppConstants.issueTypes[0] : 'General';
  String _selectedPriority = 'medium';
  String? _selectedJobId;
  final List<XFile> _selectedImages = [];
  final Map<int, Uint8List> _imageBytes = {};
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  List<JobModel> _availableJobs = [];
  bool _isLoadingJobs = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorkerJobs();
    });
  }

  Future<void> _loadWorkerJobs() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(jobsProvider.notifier).loadWorkerJobs(user.id);
      final jobsState = ref.read(jobsProvider);
      setState(() {
        _availableJobs = jobsState.jobs;
        _isLoadingJobs = false;
      });
    } else {
      setState(() => _isLoadingJobs = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          final index = _selectedImages.length;
          _selectedImages.add(file);
          _imageBytes[index] = bytes;
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      final newBytes = <int, Uint8List>{};
      for (int i = 0; i < _selectedImages.length; i++) {
        if (i < index) {
          newBytes[i] = _imageBytes[i]!;
        } else {
          newBytes[i] = _imageBytes[i + 1]!;
        }
      }
      _imageBytes.clear();
      _imageBytes.addAll(newBytes);
    });
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedJobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a job')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not logged in');

      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        try {
          final supabase = Supabase.instance.client;
          for (int i = 0; i < _selectedImages.length; i++) {
            final xFile = _selectedImages[i];
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final filePath = 'issues/$_selectedJobId/$fileName';
            final fileBytes = await xFile.readAsBytes();

            await supabase.storage
                .from(AppConstants.installationImagesBucket)
                .uploadBinary(filePath, fileBytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

            final publicUrl = supabase.storage
                .from(AppConstants.installationImagesBucket)
                .getPublicUrl(filePath);

            imageUrls.add(publicUrl);
          }
        } catch (e) {
          debugPrint('Image upload error: $e');
          imageUrls = [];
        }
      }

      double? latitude;
      double? longitude;
      try {
        final locationService = LocationService();
        final position = await locationService.getCurrentPosition();
        latitude = position?.latitude;
        longitude = position?.longitude;
      } catch (e) {
        debugPrint('Location error: $e');
      }

      await ref.read(issuesProvider.notifier).createIssueReport(
        jobId: _selectedJobId!,
        workerId: user.id,
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        reportedBy: user.fullName,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
        latitude: latitude,
        longitude: longitude,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Issue reported successfully'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit issue error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report issue: $e'), backgroundColor: const Color(0xFFD32F2F)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      insetPadding: EdgeInsets.all(16.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
        child: _isSubmitting || _isLoadingJobs
            ? SizedBox(
          height: 200.h,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E))),
                SizedBox(height: 16.h),
                Text(
                  _isSubmitting ? 'Uploading report...' : 'Loading your jobs...',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        )
            : SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.report_problem_rounded, color: const Color(0xFFD32F2F), size: 24.w),
                    ),
                    SizedBox(width: 12.w),
                    Text('Report Issue', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  ],
                ),
                SizedBox(height: 24.h),

                // Helpful tip
                if (_availableJobs.isEmpty)
                  Container(
                    padding: EdgeInsets.all(12.w),
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 20.w),
                        SizedBox(width: 8.w),
                        Expanded(child: Text('No active jobs. Navigate to the Jobs tab to select a specific installation.', style: TextStyle(color: Colors.orange.shade800, fontSize: 13.sp, height: 1.4))),
                      ],
                    ),
                  ),

                // Job selection
                Text('Select Installation Site', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  value: _selectedJobId,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  hint: Text(_availableJobs.isEmpty ? 'No jobs available' : 'Choose a job...', style: TextStyle(color: Colors.grey.shade500)),
                  items: _availableJobs.map((job) {
                    return DropdownMenuItem(
                      value: job.id,
                      child: Text(job.customer?.fullName ?? 'Job #${job.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: _availableJobs.isEmpty ? null : (value) => setState(() => _selectedJobId = value),
                  validator: (value) => value == null ? 'Selection required' : null,
                ),
                SizedBox(height: 20.h),

                // Issue Type & Priority Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Issue Type', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            value: _selectedIssueType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            ),
                            items: AppConstants.issueTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: TextStyle(fontSize: 14.sp), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (value) => setState(() => _selectedIssueType = value!),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Priority', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                          SizedBox(height: 8.h),
                          DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('LOW')),
                              DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                              DropdownMenuItem(value: 'high', child: Text('HIGH')),
                              DropdownMenuItem(value: 'critical', child: Text('CRITICAL')),
                            ],
                            onChanged: (value) => setState(() => _selectedPriority = value!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Description
                Text('Description', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Describe the problem in detail...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Description is required';
                    return null;
                  },
                ),
                SizedBox(height: 20.h),

                // Modern Image Uploader
                Text('Attachments', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                SizedBox(height: 8.h),
                InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: const Color(0xFF1A237E), size: 28.w),
                        SizedBox(height: 8.h),
                        Text('Tap to add photos', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF1A237E), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: List.generate(_selectedImages.length, (index) {
                      final bytes = _imageBytes[index];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: 70.w,
                              height: 70.h,
                              color: Colors.grey.shade200,
                              child: bytes != null
                                  ? Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: Colors.grey, size: 24.w))
                                  : Icon(Icons.image, color: Colors.grey, size: 24.w),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                                child: Icon(Icons.close_rounded, size: 14.w, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
                SizedBox(height: 32.h),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('Cancel', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitIssue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text('Submit', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
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
}