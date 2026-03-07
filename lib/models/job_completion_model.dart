class JobCompletionModel {
  final String id;
  final String jobId;
  final String workerId;
  final bool safetyConfirmed;
  final DateTime? safetyConfirmedAt;
  final String? customerSignatureUrl;
  final String? customerName;
  final DateTime? signedAt;
  final DateTime completedAt;
  final String? notes;
  final double? finalLatitude;
  final double? finalLongitude;

  JobCompletionModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.safetyConfirmed,
    this.safetyConfirmedAt,
    this.customerSignatureUrl,
    this.customerName,
    this.signedAt,
    required this.completedAt,
    this.notes,
    this.finalLatitude,
    this.finalLongitude,
  });

  factory JobCompletionModel.fromJson(Map<String, dynamic> json) {
    return JobCompletionModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      workerId: json['worker_id'] as String,
      safetyConfirmed: json['safety_confirmed'] as bool,
      safetyConfirmedAt: json['safety_confirmed_at'] != null
          ? DateTime.parse(json['safety_confirmed_at'] as String)
          : null,
      customerSignatureUrl: json['customer_signature_url'] as String?,
      customerName: json['customer_name'] as String?,
      signedAt: json['signed_at'] != null
          ? DateTime.parse(json['signed_at'] as String)
          : null,
      completedAt: DateTime.parse(json['completed_at'] as String),
      notes: json['notes'] as String?,
      finalLatitude: json['final_latitude'] != null
          ? (json['final_latitude'] as num).toDouble()
          : null,
      finalLongitude: json['final_longitude'] != null
          ? (json['final_longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'safety_confirmed': safetyConfirmed,
      'safety_confirmed_at': safetyConfirmedAt?.toIso8601String(),
      'customer_signature_url': customerSignatureUrl,
      'customer_name': customerName,
      'signed_at': signedAt?.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'notes': notes,
      'final_latitude': finalLatitude,
      'final_longitude': finalLongitude,
    };
  }

  bool get isFullyCompleted =>
      safetyConfirmed && customerSignatureUrl != null && customerName != null;

  JobCompletionModel copyWith({
    String? id,
    String? jobId,
    String? workerId,
    bool? safetyConfirmed,
    DateTime? safetyConfirmedAt,
    String? customerSignatureUrl,
    String? customerName,
    DateTime? signedAt,
    DateTime? completedAt,
    String? notes,
    double? finalLatitude,
    double? finalLongitude,
  }) {
    return JobCompletionModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      safetyConfirmed: safetyConfirmed ?? this.safetyConfirmed,
      safetyConfirmedAt: safetyConfirmedAt ?? this.safetyConfirmedAt,
      customerSignatureUrl: customerSignatureUrl ?? this.customerSignatureUrl,
      customerName: customerName ?? this.customerName,
      signedAt: signedAt ?? this.signedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      finalLatitude: finalLatitude ?? this.finalLatitude,
      finalLongitude: finalLongitude ?? this.finalLongitude,
    );
  }
}
