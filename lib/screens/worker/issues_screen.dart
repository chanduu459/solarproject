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
      body: RefreshIndicator(
        onRefresh: _loadIssues,
        child: workerIssues.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: EdgeInsets.all(16.w),
                itemCount: workerIssues.length,
                itemBuilder: (context, index) {
                  return _IssueCard(issue: workerIssues[index]);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportIssueDialog,
        icon: const Icon(Icons.add),
        label: const Text('Report Issue'),
        backgroundColor: const Color(0xFFE53935),
      ),
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
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Issues Reported',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'All systems running smoothly!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IssueReportModel issue;

  const _IssueCard({required this.issue});

  Color _getPriorityColor() {
    switch (issue.priority) {
      case 'critical':
        return const Color(0xFFE53935);
      case 'high':
        return const Color(0xFFFFA726);
      case 'medium':
        return const Color(0xFF1E88E5);
      case 'low':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (issue.status) {
      case 'open':
        return const Color(0xFFE53935);
      case 'in_progress':
        return const Color(0xFFFFA726);
      case 'resolved':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue.issueType,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getPriorityColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        issue.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: _getPriorityColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        issue.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              issue.description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 14.w, color: Colors.grey),
                SizedBox(width: 4.w),
                Text(
                  _formatDateTime(issue.reportedAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (issue.imageUrls != null && issue.imageUrls!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.image, size: 14.w, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(
                    '${issue.imageUrls!.length} image(s) attached',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
            if (issue.status == 'resolved' && issue.resolutionNotes != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resolution:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      issue.resolutionNotes!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green.shade700,
                      ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _ReportIssueDialog extends ConsumerStatefulWidget {
  const _ReportIssueDialog();

  @override
  ConsumerState<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends ConsumerState<_ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIssueType = AppConstants.issueTypes[0];
  String _selectedPriority = 'medium';
  String? _selectedJobId;
  final List<XFile> _selectedImages = [];
  final Map<int, Uint8List> _imageBytes = {}; // Cache image bytes
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
      setState(() {
        _isLoadingJobs = false;
      });
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
      // Rebuild image bytes map
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not logged in');

      // Upload images if any
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
                .uploadBinary(
              filePath,
              fileBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

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

      // Get location
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

      // Submit issue to database with selected jobId
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
          const SnackBar(
            content: Text('Issue reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Submit issue error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report issue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return AlertDialog(
      title: const Text('Report Issue'),
      content: _isSubmitting
          ? SizedBox(
              height: 200.h,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting issue...'),
                  ],
                ),
              ),
            )
          : _isLoadingJobs
          ? SizedBox(
              height: 200.h,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your jobs...'),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Helpful tip
              if (_availableJobs.isEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'No jobs assigned. Go to Jobs tab to report issues for specific jobs.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Worker name (frozen/read-only)
              TextFormField(
                initialValue: user?.fullName ?? 'Unknown Worker',
                decoration: InputDecoration(
                  labelText: 'Reported By',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  prefixIcon: Icon(Icons.person, color: Colors.grey, size: 20.w),
                ),
                enabled: false,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // Job selection
              DropdownButtonFormField<String>(
                value: _selectedJobId,
                decoration: const InputDecoration(
                  labelText: 'Select Job',
                  border: OutlineInputBorder(),
                ),
                hint: Text(_availableJobs.isEmpty ? 'No jobs available' : 'Select a job'),
                items: _availableJobs.map((job) {
                  return DropdownMenuItem(
                    value: job.id,
                    child: Text(
                      job.customer?.fullName ?? 'Job #${job.id.substring(0, 8)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _availableJobs.isEmpty
                    ? null
                    : (value) => setState(() => _selectedJobId = value),
                validator: (value) => value == null ? 'Please select a job' : null,
              ),
              SizedBox(height: 16.h),

              // Issue type
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.issueTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedIssueType = value!),
              ),
              SizedBox(height: 16.h),

              // Priority
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('LOW')),
                  DropdownMenuItem(value: 'medium', child: Text('MEDIUM')),
                  DropdownMenuItem(value: 'high', child: Text('HIGH')),
                  DropdownMenuItem(value: 'critical', child: Text('CRITICAL')),
                ],
                onChanged: (value) => setState(() => _selectedPriority = value!),
              ),
              SizedBox(height: 16.h),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Image picker
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.camera_alt),
                label: Text('Add Photos (${_selectedImages.length})'),
              ),
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
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
                                ? Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.broken_image, color: Colors.grey, size: 24.w);
                                    },
                                  )
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
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 12.w,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitIssue,
          child: _isSubmitting
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}

