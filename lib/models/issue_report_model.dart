class IssueReportModel {
  final String id;
  final String jobId;
  final String workerId;
  final String issueType;
  final String description;
  final String priority;
  final String status;
  final DateTime reportedAt;
  final String? reportedBy;
  final DateTime? resolvedAt;
  final String? resolvedByWorker;
  final String? resolutionNotes;
  final List<String>? imageUrls;
  final double? latitude;
  final double? longitude;
  
  // Joined data
  final String? workerName;
  final String? customerName;

  IssueReportModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.issueType,
    required this.description,
    this.priority = 'medium',
    this.status = 'open',
    required this.reportedAt,
    this.reportedBy,
    this.resolvedAt,
    this.resolvedByWorker,
    this.resolutionNotes,
    this.imageUrls,
    this.latitude,
    this.longitude,
    this.workerName,
    this.customerName,
  });

  factory IssueReportModel.fromJson(Map<String, dynamic> json) {
    return IssueReportModel(
      id: json['id'] as String,
      jobId: json['job_id'] as String,
      workerId: json['worker_id'] as String,
      issueType: json['issue_type'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      reportedAt: DateTime.parse(json['reported_at'] as String),
      reportedBy: json['reported_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedByWorker: json['resolved_by'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      workerName: json['worker_name'] as String?,
      customerName: json['customer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'worker_id': workerId,
      'issue_type': issueType,
      'description': description,
      'priority': priority,
      'status': status,
      'reported_at': reportedAt.toIso8601String(),
      'reported_by': reportedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedByWorker,
      'resolution_notes': resolutionNotes,
      'image_urls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  String get statusDisplay {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Unknown';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  IssueReportModel copyWith({
    String? id,
    String? jobId,
    String? workerId,
    String? issueType,
    String? description,
    String? priority,
    String? status,
    DateTime? reportedAt,
    String? reportedBy,
    DateTime? resolvedAt,
    String? resolvedByWorker,
    String? resolutionNotes,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? workerName,
    String? customerName,
  }) {
    return IssueReportModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      workerId: workerId ?? this.workerId,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      reportedAt: reportedAt ?? this.reportedAt,
      reportedBy: reportedBy ?? this.reportedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByWorker: resolvedByWorker ?? this.resolvedByWorker,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      workerName: workerName ?? this.workerName,
      customerName: customerName ?? this.customerName,
    );
  }
}
