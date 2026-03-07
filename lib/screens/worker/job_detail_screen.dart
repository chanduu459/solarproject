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
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showSignatureDialog() async {
    final signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
    );

    final customerNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Signature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Enter customer name',
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Signature(
                controller: signatureController,
                height: 200.h,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (customerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter customer name')),
                );
                return;
              }

              final signature = await signatureController.toPngBytes();
              if (signature == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a signature')),
                );
                return;
              }

              Navigator.pop(context);
              await _saveSignature(signature, customerNameController.text);
            },
            child: const Text('Save'),
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

      // Convert List<int> to Uint8List
      final signature = Uint8List.fromList(signatureBytes);

      // Upload signature
      final signatureUrl = await _storageService.uploadSignature(
        signatureBytes: signature,
        jobId: widget.jobId,
        customerName: customerName,
      );

      // Save completion record
      final completionService = JobCompletionService();
      await completionService.createCompletion(
        jobId: widget.jobId,
        workerId: user.id,
        customerSignatureUrl: signatureUrl,
        customerName: customerName,
      );

      // Update job to completed
      await ref.read(jobsProvider.notifier).updateProgress(
        jobId: widget.jobId,
        progressPercentage: 100,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job completed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save signature: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _showIssueReportDialog() async {
    final issueTypeController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'medium';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: issueTypeController.text.isEmpty ? null : issueTypeController.text,
                hint: const Text('Select Issue Type'),
                items: AppConstants.issueTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  issueTypeController.text = value ?? '';
                },
              ),
              SizedBox(height: 16.h),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: ['low', 'medium', 'high', 'critical'].map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedPriority = value ?? 'medium';
                },
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (issueTypeController.text.isEmpty ||
                  descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitIssueReport(
    String issueType,
    String description,
    String priority,
  ) async {
    try {
      setState(() => _isUploading = true);

      final user = ref.read(authProvider).user;
      if (user == null) return;

      // Get current location
      final position = await _locationService.getCurrentPosition();

      // Create issue report
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
          const SnackBar(content: Text('Issue reported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report issue: $e')),
        );
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
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: jobsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : job == null
              ? const Center(child: Text('Job not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer info card
                      _buildCustomerCard(job),
                      SizedBox(height: 16.h),
                      // Job details card
                      _buildJobDetailsCard(job),
                      SizedBox(height: 16.h),
                      // Progress card
                      _buildProgressCard(job),
                      SizedBox(height: 16.h),
                      // Photo upload section
                      _buildPhotoUploadSection(),
                      SizedBox(height: 16.h),
                      // Action buttons
                      _buildActionButtons(job),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCustomerCard(JobModel job) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow(Icons.person, job.customer?.fullName ?? 'Unknown'),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.phone, job.customer?.phone ?? 'No phone'),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.email, job.customer?.email ?? 'No email'),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.location_on, job.customer?.fullAddress ?? 'No address'),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsCard(JobModel job) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Details',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow(Icons.solar_power, '${job.panelQuantity}x ${job.panelType}'),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.calendar_today, 'Scheduled: ${job.scheduledDate.toString().split(' ')[0]}'),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.flag, 'Priority: ${job.priority?.toUpperCase() ?? 'NORMAL'}'),
            SizedBox(height: 8.h),
            _buildInfoRow(Icons.attach_money, 'Estimated: \$${job.estimatedCost?.toStringAsFixed(2) ?? 'N/A'}'),
            if (job.notes != null && job.notes!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              _buildInfoRow(Icons.note, 'Notes: ${job.notes}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(JobModel job) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Installation Progress',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            LinearProgressIndicator(
              value: job.progressPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                job.progressPercentage == 100
                    ? const Color(0xFF43A047)
                    : const Color(0xFF1E88E5),
              ),
              minHeight: 12.h,
            ),
            SizedBox(height: 8.h),
            Text(
              '${job.progressPercentage}% Complete',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: job.progressPercentage == 100
                    ? const Color(0xFF43A047)
                    : const Color(0xFF1E88E5),
              ),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              children: [0, 25, 50, 75, 100].map((progress) {
                return ChoiceChip(
                  label: Text('$progress%'),
                  selected: job.progressPercentage == progress,
                  onSelected: (selected) {
                    if (selected) {
                      _updateProgress(progress);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo Documentation',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _PhotoUploadButton(
                    label: 'Before',
                    icon: Icons.camera_alt,
                    onTap: _isUploading ? null : () => _uploadImage('before'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _PhotoUploadButton(
                    label: 'During',
                    icon: Icons.camera_alt,
                    onTap: _isUploading ? null : () => _uploadImage('during'),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _PhotoUploadButton(
                    label: 'After',
                    icon: Icons.camera_alt,
                    onTap: _isUploading ? null : () => _uploadImage('after'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            icon: const Icon(Icons.check_circle),
            label: const Text('Complete Job'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
          SizedBox(height: 12.h),
        ],
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _showIssueReportDialog,
          icon: const Icon(Icons.report_problem),
          label: const Text('Report Issue'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA726),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20.w, color: Colors.grey),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
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

  const _PhotoUploadButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1E88E5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1E88E5), size: 28.w),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: const Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
