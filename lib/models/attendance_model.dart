class AttendanceModel {
  final String id;
  final String workerId;
  final String jobId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String status;
  final int? workingHours;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.workerId,
    required this.jobId,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkInAddress,
    this.checkOutAddress,
    this.status = 'checked_in',
    this.workingHours,
    this.notes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      jobId: json['job_id'] as String,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      checkInLatitude: json['check_in_latitude'] != null
          ? (json['check_in_latitude'] as num).toDouble()
          : null,
      checkInLongitude: json['check_in_longitude'] != null
          ? (json['check_in_longitude'] as num).toDouble()
          : null,
      checkOutLatitude: json['check_out_latitude'] != null
          ? (json['check_out_latitude'] as num).toDouble()
          : null,
      checkOutLongitude: json['check_out_longitude'] != null
          ? (json['check_out_longitude'] as num).toDouble()
          : null,
      checkInAddress: json['check_in_address'] as String?,
      checkOutAddress: json['check_out_address'] as String?,
      status: json['status'] as String? ?? 'checked_in',
      workingHours: json['working_hours'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'job_id': jobId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'check_in_address': checkInAddress,
      'check_out_address': checkOutAddress,
      'status': status,
      'working_hours': workingHours,
      'notes': notes,
    };
  }

  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';

  String get statusDisplay {
    switch (status) {
      case 'checked_in':
        return 'Checked In';
      case 'checked_out':
        return 'Checked Out';
      default:
        return 'Unknown';
    }
  }

  Duration? get duration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  String get durationDisplay {
    final dur = duration;
    if (dur == null) return 'In Progress';
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  AttendanceModel copyWith({
    String? id,
    String? workerId,
    String? jobId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkInAddress,
    String? checkOutAddress,
    String? status,
    int? workingHours,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      jobId: jobId ?? this.jobId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkInAddress: checkInAddress ?? this.checkInAddress,
      checkOutAddress: checkOutAddress ?? this.checkOutAddress,
      status: status ?? this.status,
      workingHours: workingHours ?? this.workingHours,
      notes: notes ?? this.notes,
    );
  }
}
