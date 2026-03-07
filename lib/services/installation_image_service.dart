import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installation_image_model.dart';

class InstallationImageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<InstallationImageModel> createImageRecord({
    required String jobId,
    required String workerId,
    required String imageType,
    required String imageUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) async {
    try {
      final imageData = {
        'job_id': jobId,
        'worker_id': workerId,
        'image_type': imageType,
        'image_url': imageUrl,
        'captured_at': DateTime.now().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'notes': notes,
      };

      final response = await _supabase
          .from('installation_images')
          .insert(imageData)
          .select()
          .single();

      return InstallationImageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create image record: $e');
    }
  }

  Future<InstallationImageModel?> getImageById(String imageId) async {
    try {
      final response = await _supabase
          .from('installation_images')
          .select()
          .eq('id', imageId)
          .maybeSingle();

      return response != null ? InstallationImageModel.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch image: $e');
    }
  }

  Future<List<InstallationImageModel>> getJobImages(String jobId) async {
    try {
      final response = await _supabase
          .from('installation_images')
          .select()
          .eq('job_id', jobId)
          .order('captured_at', ascending: false);

      return (response as List).map((json) =>
          InstallationImageModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch job images: $e');
    }
  }

  Future<Map<String, dynamic>> getImageStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).toUtc().toIso8601String();

      final List<int> results = await Future.wait<int>([
        _supabase.from('installation_images').count(CountOption.exact),
        _supabase.from('installation_images').count(CountOption.exact).gte('captured_at', startOfDay).lt('captured_at', endOfDay),
        _supabase.from('installation_images').count(CountOption.exact).eq('image_type', 'before'),
        _supabase.from('installation_images').count(CountOption.exact).eq('image_type', 'during'),
        _supabase.from('installation_images').count(CountOption.exact).eq('image_type', 'after'),
      ]);

      return {
        'total_images': results[0],
        'today_images': results[1],
        'before_images': results[2],
        'during_images': results[3],
        'after_images': results[4],
      };
    } catch (e) {
      throw Exception('Failed to get image statistics: $e');
    }
  }
}