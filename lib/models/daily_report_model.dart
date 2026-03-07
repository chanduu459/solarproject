class DailyReportModel {
  final String id;
  final String workerId;
  final DateTime reportDate;
  final int totalJobs;
  final int completedJobs;
  final int pendingJobs;
  final int issuesReported;
  final int totalHoursWorked;
  final double? totalDistance;
  final List<String>? jobIds;
  final String? notes;
  final DateTime createdAt;
  
  // Joined data
  final String? workerName;

  DailyReportModel({
    required this.id,
    required this.workerId,
    required this.reportDate,
    required this.totalJobs,
    required this.completedJobs,
    required this.pendingJobs,
    required this.issuesReported,
    required this.totalHoursWorked,
    this.totalDistance,
    this.jobIds,
    this.notes,
    required this.createdAt,
    this.workerName,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      reportDate: DateTime.parse(json['report_date'] as String),
      totalJobs: json['total_jobs'] as int,
      completedJobs: json['completed_jobs'] as int,
      pendingJobs: json['pending_jobs'] as int,
      issuesReported: json['issues_reported'] as int,
      totalHoursWorked: json['total_hours_worked'] as int,
      totalDistance: json['total_distance'] != null
          ? (json['total_distance'] as num).toDouble()
          : null,
      jobIds: json['job_ids'] != null
          ? List<String>.from(json['job_ids'] as List)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      workerName: json['worker_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'report_date': reportDate.toIso8601String(),
      'total_jobs': totalJobs,
      'completed_jobs': completedJobs,
      'pending_jobs': pendingJobs,
      'issues_reported': issuesReported,
      'total_hours_worked': totalHoursWorked,
      'total_distance': totalDistance,
      'job_ids': jobIds,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get completionRate {
    if (totalJobs == 0) return 0.0;
    return (completedJobs / totalJobs) * 100;
  }

  String get hoursDisplay {
    final hours = totalHoursWorked ~/ 60;
    final minutes = totalHoursWorked % 60;
    return '${hours}h ${minutes}m';
  }

  DailyReportModel copyWith({
    String? id,
    String? workerId,
    DateTime? reportDate,
    int? totalJobs,
    int? completedJobs,
    int? pendingJobs,
    int? issuesReported,
    int? totalHoursWorked,
    double? totalDistance,
    List<String>? jobIds,
    String? notes,
    DateTime? createdAt,
    String? workerName,
  }) {
    return DailyReportModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      reportDate: reportDate ?? this.reportDate,
      totalJobs: totalJobs ?? this.totalJobs,
      completedJobs: completedJobs ?? this.completedJobs,
      pendingJobs: pendingJobs ?? this.pendingJobs,
      issuesReported: issuesReported ?? this.issuesReported,
      totalHoursWorked: totalHoursWorked ?? this.totalHoursWorked,
      totalDistance: totalDistance ?? this.totalDistance,
      jobIds: jobIds ?? this.jobIds,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      workerName: workerName ?? this.workerName,
    );
  }
}
