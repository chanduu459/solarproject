import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';

/// A reusable dialog for reporting issues from any job context.
/// Pass the jobId and customerName to show which job the issue is for.
class ReportIssueDialog extends ConsumerStatefulWidget {
  final String jobId;
  final String customerName;

  const ReportIssueDialog({
    super.key,
    required this.jobId,
    required this.customerName,
  });

  @override
  ConsumerState<ReportIssueDialog> createState() => _ReportIssueDialogState();

  /// Helper method to show the dialog
  static Future<void> show(BuildContext context, {
    required String jobId,
    required String customerName,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ReportIssueDialog(
        jobId: jobId,
        customerName: customerName,
      ),
    );
  }
}

class _ReportIssueDialogState extends ConsumerState<ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIssueType = AppConstants.issueTypes[0];
  String _selectedPriority = 'medium';
  final List<XFile> _selectedImages = [];
  final Map<int, Uint8List> _imageBytes = {};
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

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
            final filePath = 'issues/${widget.jobId}/$fileName';
            final fileBytes = await xFile.readAsBytes();

            await supabase.storage
                .from(AppConstants.installationImagesBucket)
                .uploadBinary(filePath, fileBytes,
                    fileOptions: const FileOptions(contentType: 'image/jpeg'));

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
            jobId: widget.jobId,
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
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Submit issue error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to report issue: $e'),
              backgroundColor: Colors.red),
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

    return Dialog(
      child: Container(
        width: 340.w,
        constraints: BoxConstraints(maxHeight: 580.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Report Issue',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),

            // Content
            Flexible(
              child: _isSubmitting
                  ? SizedBox(
                      height: 150.h,
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
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job info
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.work_outline,
                                      color: const Color(0xFF1E88E5), size: 20.w),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Job',
                                            style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.grey.shade600)),
                                        Text(
                                          widget.customerName,
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1E88E5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12.h),

                            // Worker name
                            TextFormField(
                              initialValue: user?.fullName ?? 'Unknown Worker',
                              decoration: InputDecoration(
                                labelText: 'Reported By',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                prefixIcon: Icon(Icons.person,
                                    color: Colors.grey, size: 20.w),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 12.h),
                              ),
                              enabled: false,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  fontSize: 14.sp),
                            ),
                            SizedBox(height: 12.h),

                            // Issue type
                            DropdownButtonFormField<String>(
                              value: _selectedIssueType,
                              decoration: InputDecoration(
                                labelText: 'Issue Type',
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 12.h),
                              ),
                              items: AppConstants.issueTypes.map((type) {
                                return DropdownMenuItem(
                                    value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedIssueType = value!),
                            ),
                            SizedBox(height: 12.h),

                            // Priority
                            DropdownButtonFormField<String>(
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                labelText: 'Priority',
                                border: const OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 12.h),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'low', child: Text('LOW')),
                                DropdownMenuItem(
                                    value: 'medium', child: Text('MEDIUM')),
                                DropdownMenuItem(
                                    value: 'high', child: Text('HIGH')),
                                DropdownMenuItem(
                                    value: 'critical', child: Text('CRITICAL')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedPriority = value!),
                            ),
                            SizedBox(height: 12.h),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Describe the issue...',
                                border: const OutlineInputBorder(),
                                alignLabelWithHint: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 12.h),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please describe the issue';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12.h),

                            // Add Photos button
                            OutlinedButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label:
                                  Text('Add Photos (${_selectedImages.length})'),
                            ),

                            // Selected images preview
                            if (_selectedImages.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: List.generate(_selectedImages.length,
                                    (index) {
                                  final bytes = _imageBytes[index];
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6.r),
                                        child: Container(
                                          width: 55.w,
                                          height: 55.h,
                                          color: Colors.grey.shade200,
                                          child: bytes != null
                                              ? Image.memory(bytes,
                                                  fit: BoxFit.cover)
                                              : Icon(Icons.image,
                                                  color: Colors.grey, size: 20.w),
                                        ),
                                      ),
                                      Positioned(
                                        top: -5,
                                        right: -5,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: EdgeInsets.all(2.w),
                                            decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle),
                                            child: Icon(Icons.close,
                                                color: Colors.white, size: 12.w),
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
            ),

            const Divider(height: 1),
            // Actions
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitIssue,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935)),
                    child: const Text('Submit',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

