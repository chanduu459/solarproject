import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/providers.dart';

class JobUpdateScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;
  final int initialProgress;
  final String? currentAddress; // ADD THIS
  final double? currentLat;     // ADD THIS
  final double? currentLng;     // ADD THIS

  const JobUpdateScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.initialProgress,
    this.currentAddress, // ADD THIS
    this.currentLat,     // ADD THIS
    this.currentLng,     // ADD THIS
  });

  @override
  ConsumerState<JobUpdateScreen> createState() => _JobUpdateScreenState();
}

class _JobUpdateScreenState extends ConsumerState<JobUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  late double _progressPercentage;
  bool _isSubmitting = false;
  String _loadingText = 'Submitting Update...';

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  @override
  @override
  void initState() {
    super.initState();
    _progressPercentage = widget.initialProgress.toDouble();

    // NEW: Initialize controllers with current data from the database
    _addressController.text = widget.currentAddress ?? '';

    if (widget.currentLat != null) {
      _latitudeController.text = widget.currentLat.toString();
    }

    if (widget.currentLng != null) {
      _longitudeController.text = widget.currentLng.toString();
    }
  }
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _loadingText = 'Uploading Images...';
    });

    try {
      final workerId = ref.read(authProvider).user?.id;
      if (workerId == null) throw Exception("User not logged in");

      // 1. Explicitly parse coordinates to double for Supabase numeric columns
      final double? lat = double.tryParse(_latitudeController.text.trim());
      final double? lng = double.tryParse(_longitudeController.text.trim());

      // 2. Format Address and Notes
      final String combinedNotes = _addressController.text.isNotEmpty
          ? "Address: ${_addressController.text}\nNotes: ${_notesController.text}"
          : _notesController.text;

      // 3. Handle Image Uploads
      final supabase = Supabase.instance.client;
      List<String> uploadedImageUrls = [];

      for (var xFile in _selectedImages) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
        final filePath = '${widget.jobId}/$fileName';

        // Use readAsBytes and uploadBinary for Web + Mobile compatibility
        final fileBytes = await xFile.readAsBytes();

        await supabase.storage
            .from('installation_images')
            .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

        final publicUrl = supabase.storage
            .from('installation_images')
            .getPublicUrl(filePath);

        uploadedImageUrls.add(publicUrl);
      }

      setState(() => _loadingText = 'Saving to Database...');

      // 4. Submit to Provider (Ensure latitude and longitude are passed)
      await ref.read(jobsProvider.notifier).submitWorkUpdate(
        jobId: widget.jobId,
        workerId: workerId,
        progressPercentage: _progressPercentage.toInt(),
        notes: combinedNotes,
        imageUrls: uploadedImageUrls,
        latitude: lat,
        longitude: lng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Update: ${widget.jobTitle}', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Progress Slider
              Text(
                'Job Progress: ${_progressPercentage.toInt()}%',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Slider(
                  value: _progressPercentage,
                  min: 0, max: 100, divisions: 20,
                  label: '${_progressPercentage.toInt()}%',
                  activeColor: const Color(0xFF1E88E5),
                  onChanged: (value) => setState(() => _progressPercentage = value),
                ),
              ),
              SizedBox(height: 24.h),

              // 2. Address Input
              Text(
                'Current Address / Location',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Enter site address or location details',
                  filled: true, fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter the address' : null,
              ),
              SizedBox(height: 24.h),

              // 3. Latitude & Longitude Inputs
              Row(
                children: [
                  Expanded(
                    child: _buildLocationInput('Latitude', _latitudeController, 'e.g. 14.4426'),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildLocationInput('Longitude', _longitudeController, 'e.g. 79.9865'),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // 4. Image Picker
              Text(
                'Installation Photos',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),

              if (_selectedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final xFile = _selectedImages[index];
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: kIsWeb
                              ? Image.network(xFile.path, fit: BoxFit.cover)
                              : Image.file(File(xFile.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -4, right: -4,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              SizedBox(height: 12.h),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add Photos'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 24.h),

              // 5. Work Notes
              Text(
                'Work Notes',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What work was completed today?',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 40.h),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: _isSubmitting
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 12.w),
                      Text(_loadingText, style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                    ],
                  )
                      : Text('Submit Update', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInput(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}