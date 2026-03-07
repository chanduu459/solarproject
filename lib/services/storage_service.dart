import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Keep for Color support if needed elsewhere
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../utils/constants.dart';
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Upload installation image
  Future<String> uploadInstallationImage({
    required File imageFile,
    required String jobId,
    required String workerId,
    required String imageType,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = '${jobId}_${imageType}_${workerId}_$timestamp$extension';
      final filePath = '$jobId/$fileName';

      await _supabase.storage
          .from(AppConstants.installationImagesBucket)
          .upload(filePath, imageFile);

      // Get public URL
      final imageUrl = _supabase.storage
          .from(AppConstants.installationImagesBucket)
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload installation image: $e');
    }
  }

  // Upload installation image from bytes (for signature)
  Future<String> uploadImageFromBytes({
    required Uint8List bytes,
    required String jobId,
    required String workerId,
    required String imageType,
    String extension = '.png',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${jobId}_${imageType}_${workerId}_$timestamp$extension';
      final filePath = '$jobId/$fileName';

      await _supabase.storage
          .from(AppConstants.installationImagesBucket)
          .uploadBinary(filePath, bytes);

      // Get public URL
      final imageUrl = _supabase.storage
          .from(AppConstants.installationImagesBucket)
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image from bytes: $e');
    }
  }

  // Upload customer signature
  Future<String> uploadSignature({
    required Uint8List signatureBytes,
    required String jobId,
    required String customerName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = customerName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '${jobId}_signature_${sanitizedName}_$timestamp.png';
      final filePath = '$jobId/$fileName';

      await _supabase.storage
          .from(AppConstants.signaturesBucket)
          .uploadBinary(filePath, signatureBytes);

      // Get public URL
      final signatureUrl = _supabase.storage
          .from(AppConstants.signaturesBucket)
          .getPublicUrl(filePath);

      return signatureUrl;
    } catch (e) {
      throw Exception('Failed to upload signature: $e');
    }
  }

  // Upload issue report images
  Future<List<String>> uploadIssueImages({
    required List<File> images,
    required String issueId,
    required String workerId,
  }) async {
    try {
      final uploadedUrls = <String>[];

      for (var i = 0; i < images.length; i++) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(images[i].path);
        final fileName = '${issueId}_image${i + 1}_${workerId}_$timestamp$extension';
        final filePath = 'issues/$issueId/$fileName';

        await _supabase.storage
            .from(AppConstants.installationImagesBucket)
            .upload(filePath, images[i]);

        final imageUrl = _supabase.storage
            .from(AppConstants.installationImagesBucket)
            .getPublicUrl(filePath);

        uploadedUrls.add(imageUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload issue images: $e');
    }
  }

  // Delete image
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the bucket name in the path
      final bucketIndex = pathSegments.indexOf('object');
      if (bucketIndex == -1 || bucketIndex + 1 >= pathSegments.length) {
        throw Exception('Invalid image URL');
      }

      final bucketName = pathSegments[bucketIndex + 1];
      final filePath = pathSegments.sublist(bucketIndex + 2).join('/');

      await _supabase.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Get image URL
  String getImageUrl(String bucketName, String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }

  // List images in a folder
  Future<List<String>> listImagesInFolder(String folderPath) async {
    try {
      final response = await _supabase.storage
          .from(AppConstants.installationImagesBucket)
          .list(path: folderPath);

      return response.map((file) {
        return _supabase.storage
            .from(AppConstants.installationImagesBucket)
            .getPublicUrl('$folderPath/${file.name}');
      }).toList();
    } catch (e) {
      throw Exception('Failed to list images: $e');
    }
  }

  // Download image
  Future<Uint8List> downloadImage(String bucketName, String filePath) async {
    try {
      final response = await _supabase.storage
          .from(bucketName)
          .download(filePath);

      return response;
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  // Create storage buckets if they don't exist (Owner only)
  Future<void> createBuckets() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final bucketIds = buckets.map((b) => b.id).toList();

      // if (!bucketIds.contains(AppConstants.installationImagesBucket)) {
      //   await _supabase.storage.createBucket(
      //     id: AppConstants.installationImagesBucket, // Ensure this is named 'id'
      //    config: const BucketOptions(               // Change 'options' to 'config'
      //       public: true,
      //       fileSizeLimit: '10485760', // 10MB
      //       allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
      //     ),
      //   );
      // }
    } catch (e) {
      throw Exception('Failed to create storage buckets: $e');
    }
  }
}
