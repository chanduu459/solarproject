class WorkUpdateModel {
  final String id;
  final String jobId;
  final String workerId;
  final int progressPercentage;
  final String? notes;
  final List<String>? imageUrls;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  WorkUpdateModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.progressPercentage,
    this.notes,
    this.imageUrls,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory WorkUpdateModel.fromJson(Map<String, dynamic> json) {
    return WorkUpdateModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      workerId: json['worker_id'] as String,
      progressPercentage: json['progress_percentage'] as int,
      notes: json['notes'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'progress_percentage': progressPercentage,
      'notes': notes,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  WorkUpdateModel copyWith({
    String? id,
    String? jobId,
    String? workerId,
    int? progressPercentage,
    String? notes,
    List<String>? imageUrls,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return WorkUpdateModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
