import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import 'dart:typed_data';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    await ref.read(jobsProvider.notifier).loadJobById(widget.jobId);
  }

  Future<void> _updateProgress(int progress) async {
    await ref.read(jobsProvider.notifier).updateProgress(
      jobId: widget.jobId,
      progressPercentage: progress,
    );
  }

  Future<void> _uploadImage(String imageType) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final user = ref.read(authProvider).user;
      if (user == null) return;

      // Get current location
      final position = await _locationService.getCurrentPosition();

      // Upload image
      final imageUrl = await _storageService.uploadInstallationImage(
        imageFile: File(pickedFile.path),
        jobId: widget.jobId,
        workerId: user.id,
        imageType: imageType,
      );

      // Save image record
      final imageService = InstallationImageService();
      await imageService.createImageRecord(
        jobId: widget.jobId,
        workerId: user.id,
        imageType: imageType,
        imageUrl: imageUrl,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image uploaded successfully'),
            backgroundColor: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showSignatureDialog() async {
    final signatureController = SignatureController(
      penStrokeWidth: 4,
      penColor: const Color(0xFF1A1A1A),
      exportBackgroundColor: Colors.transparent,
    );

    final customerNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Customer Sign-Off', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please have the customer sign to verify completion.', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
              SizedBox(height: 16.h),
              TextField(
                controller: customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Print Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF1A237E))),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Signature(
                    controller: signatureController,
                    height: 200.h,
                    backgroundColor: const Color(0xFFF8F9FA),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => signatureController.clear(),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Pad'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (customerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter customer name')));
                return;
              }

              final signature = await signatureController.toPngBytes();
              if (signature == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a signature')));
                return;
              }

              Navigator.pop(context);
              await _saveSignature(signature, customerNameController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Confirm & Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSignature(List<int> signatureBytes, String customerName) async {
    try {
      setState(() => _isUploading = true);

      final user = ref.read(authProvider).user;
      if (user == null) return;

      final signature = Uint8List.fromList(signatureBytes);

      final signatureUrl = await _storageService.uploadSignature(
        signatureBytes: signature,
        jobId: widget.jobId,
        customerName: customerName,
      );

      final completionService = JobCompletionService();
      await completionService.createCompletion(
        jobId: widget.jobId,
        workerId: user.id,
        customerSignatureUrl: signatureUrl,
        customerName: customerName,
      );

      await ref.read(jobsProvider.notifier).updateProgress(jobId: widget.jobId, progressPercentage: 100);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job completed successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save signature: $e'), backgroundColor: const Color(0xFFD32F2F)));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showIssueReportDialog() async {
    final issueTypeController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'medium';
    final user = ref.read(authProvider).user;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.report_problem_rounded,
                          color: Colors.white,
                          size: 28.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Issue',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Document site problems',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Section
                SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Info Card
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.work_outline_rounded,
                              color: const Color(0xFF1E88E5),
                              size: 20.w,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Job',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF1E88E5),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    ref.watch(jobsProvider).selectedJob?.customer?.fullName ?? 'Current Job',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Reported By (Read-only)
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 18.w,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reported By',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  user?.fullName ?? 'Worker',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Issue Type Dropdown
                      Text(
                        'Issue Type',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: issueTypeController.text.isEmpty ? null : issueTypeController.text,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              color: Colors.grey.shade600,
                              size: 20.w,
                            ),
                            hintText: 'Select issue type',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          ),
                          items: AppConstants.issueTypes.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                          onChanged: (value) => setState(() => issueTypeController.text = value ?? ''),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Priority Level
                      Text(
                        'Priority Level',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPriority,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.flag_rounded,
                              color: _getPriorityColor(selectedPriority),
                              size: 20.w,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          ),
                          items: ['low', 'medium', 'high', 'critical'].map((priority) {
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8.w,
                                    height: 8.w,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(priority),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    priority.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: _getPriorityColor(priority),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => selectedPriority = value ?? 'medium'),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Description Field
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Describe the issue in detail...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16.w),
                          ),
                          maxLines: 4,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF1A1A1A),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24.r),
                      bottomRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (issueTypeController.text.isEmpty || descriptionController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Please fill all required fields'),
                                  backgroundColor: const Color(0xFFFF9800),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            await _submitIssueReport(
                              issueTypeController.text,
                              descriptionController.text,
                              selectedPriority,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8.w),
                              Text(
                                'Submit Report',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return const Color(0xFF43A047);
      case 'medium':
        return const Color(0xFFFFA726);
      case 'high':
        return const Color(0xFFFF7043);
      case 'critical':
        return const Color(0xFFD32F2F);
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitIssueReport(String issueType, String description, String priority) async {
    try {
      setState(() => _isUploading = true);
      final user = ref.read(authProvider).user;
      if (user == null) return;

      final position = await _locationService.getCurrentPosition();

      await ref.read(issuesProvider.notifier).createIssueReport(
        jobId: widget.jobId,
        workerId: user.id,
        issueType: issueType,
        description: description,
        priority: priority,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Issue reported successfully to HQ'),
            backgroundColor: const Color(0xFFF57C00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report issue: $e')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final job = jobsState.selectedJob;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
        title: Text('Operation Details', style: TextStyle(color: const Color(0xFF1A1A1A), fontSize: 18.sp, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: jobsState.isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E))))
          : job == null
          ? Center(child: Text('Operation not found', style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600)))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('CLIENT INFORMATION'),
            _buildCustomerSection(job),

            SizedBox(height: 24.h),
            _buildSectionTitle('TECHNICAL SCOPE'),
            _buildJobDetailsSection(job),

            SizedBox(height: 24.h),
            _buildSectionTitle('INSTALLATION STATUS'),
            _buildProgressSection(job),

            SizedBox(height: 24.h),
            _buildSectionTitle('SITE DOCUMENTATION'),
            _buildPhotoUploadSection(),

            SizedBox(height: 32.h),
            _buildActionButtons(job),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildCustomerSection(JobModel job) {
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.person_outline_rounded, job.customer?.fullName ?? 'Unknown', isPrimary: true),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone_outlined, job.customer?.phone ?? 'No phone'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.email_outlined, job.customer?.email ?? 'No email'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.location_on_outlined, job.customer?.fullAddress ?? 'No address'),
        ],
      ),
    );
  }

  Widget _buildJobDetailsSection(JobModel job) {
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.solar_power_outlined, '${job.panelQuantity}x ${job.panelType}', isPrimary: true),
          const Divider(height: 24),
          _buildInfoRow(Icons.calendar_today_rounded, 'Scheduled: ${job.scheduledDate.toString().split(' ')[0]}'),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.flag_outlined, 'Priority: ${job.priority?.toUpperCase() ?? 'NORMAL'}'),
          if (job.notes != null && job.notes!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(Icons.note_alt_outlined, 'Notes: ${job.notes}'),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection(JobModel job) {
    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Progress', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              Text(
                '${job.progressPercentage}%',
                style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: job.progressPercentage == 100 ? const Color(0xFF2E7D32) : const Color(0xFF1A237E)
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: job.progressPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                job.progressPercentage == 100 ? const Color(0xFF2E7D32) : const Color(0xFF1A237E),
              ),
              minHeight: 10.h,
            ),
          ),
          SizedBox(height: 24.h),

          // Custom Segmented Control for Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0, 25, 50, 75, 100].map((progress) {
              final isSelected = job.progressPercentage == progress;
              return GestureDetector(
                onTap: () => _updateProgress(progress),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1A237E) : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade300),
                  ),
                  child: Text(
                    '$progress%',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return _buildContainer(
      child: Row(
        children: [
          Expanded(child: _PhotoUploadButton(label: 'Pre-Install', icon: Icons.camera_alt_outlined, onTap: _isUploading ? null : () => _uploadImage('before'))),
          SizedBox(width: 8.w),
          Expanded(child: _PhotoUploadButton(label: 'In-Progress', icon: Icons.camera_alt_outlined, onTap: _isUploading ? null : () => _uploadImage('during'))),
          SizedBox(width: 8.w),
          Expanded(child: _PhotoUploadButton(label: 'Completed', icon: Icons.task_alt_rounded, onTap: _isUploading ? null : () => _uploadImage('after'))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(JobModel job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (job.progressPercentage < 100) ...[
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _showSignatureDialog,
            icon: const Icon(Icons.verified_rounded, color: Colors.white),
            label: Text('Finalize & Complete Job', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 16.h),
        ],
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _showIssueReportDialog,
          icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
          label: Text('Report a Blockage/Issue', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F))),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            side: const BorderSide(color: Color(0xFFD32F2F)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isPrimary = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(8.r)),
          child: Icon(icon, size: 20.w, color: isPrimary ? const Color(0xFF1A237E) : Colors.grey.shade600),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              text,
              style: TextStyle(
                fontSize: isPrimary ? 16.sp : 14.sp,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                color: isPrimary ? const Color(0xFF1A1A1A) : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoUploadButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _PhotoUploadButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid), // Clean border
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1A237E), size: 28.w),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}