class InstallationImageModel {
  final String id;
  final String jobId;
  final String workerId;
  final String imageType;
  final String imageUrl;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? notes;

  InstallationImageModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.imageType,
    required this.imageUrl,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.notes,
  });

  factory InstallationImageModel.fromJson(Map<String, dynamic> json) {
    return InstallationImageModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      workerId: json['worker_id'] as String,
      imageType: json['image_type'] as String,
      imageUrl: json['image_url'] as String,
      capturedAt: DateTime.parse(json['captured_at'] as String),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'image_type': imageType,
      'image_url': imageUrl,
      'captured_at': capturedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'notes': notes,
    };
  }

  String get imageTypeDisplay {
    switch (imageType) {
      case 'before':
        return 'Before Installation';
      case 'during':
        return 'During Installation';
      case 'after':
        return 'After Installation';
      default:
        return 'Unknown';
    }
  }

  InstallationImageModel copyWith({
    String? id,
    String? jobId,
    String? workerId,
    String? imageType,
    String? imageUrl,
    DateTime? capturedAt,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) {
    return InstallationImageModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      imageType: imageType ?? this.imageType,
      imageUrl: imageUrl ?? this.imageUrl,
      capturedAt: capturedAt ?? this.capturedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }
}
