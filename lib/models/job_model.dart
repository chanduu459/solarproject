import 'package:flutter/material.dart';
import 'customer_model.dart';

class JobModel {
  final String id;
  final String customerId;
  final String? workerId;
  final String panelType;
  final int panelQuantity;
  final DateTime scheduledDate;
  final String status;
  final int progressPercentage;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final double? estimatedCost;
  final String? priority;

  // NEW: Fields for Location Tracking
  final String? location;
  final double? latitude;
  final double? longitude;

  // Joined data
  final CustomerModel? customer;
  final String? workerName;

  JobModel({
    required this.id,
    required this.customerId,
    this.workerId,
    required this.panelType,
    required this.panelQuantity,
    required this.scheduledDate,
    this.status = 'pending',
    this.progressPercentage = 0,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    this.estimatedCost,
    this.priority = 'normal',
    this.location,
    this.latitude,
    this.longitude,
    this.customer,
    this.workerName,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      workerId: json['worker_id'] as String?,
      panelType: json['panel_type'] as String,
      panelQuantity: json['panel_quantity'] as int,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      status: json['status'] as String? ?? 'pending',
      progressPercentage: json['progress_percentage'] as int? ?? 0, // Assigned only once
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      notes: json['notes'] as String?,
      estimatedCost: json['estimated_cost'] != null
          ? (json['estimated_cost'] as num).toDouble()
          : null,
      priority: json['priority'] as String? ?? 'normal',

      // NEW: Correct Mapping for Location Tracking
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,

      customer: json['customers'] != null
          ? CustomerModel.fromJson(json['customers'] as Map<String, dynamic>)
          : null,
      workerName: json['worker_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'worker_id': workerId,
      'panel_type': panelType,
      'panel_quantity': panelQuantity,
      'scheduled_date': scheduledDate.toIso8601String(),
      'status': status,
      'progress_percentage': progressPercentage,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
      'estimated_cost': estimatedCost,
      'priority': priority,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Helper getters
  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusDisplay {
    switch (status) {
      case 'pending': return 'Pending';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return const Color(0xFF9E9E9E);
      case 'in_progress': return const Color(0xFF1E88E5);
      case 'completed': return const Color(0xFF43A047);
      case 'cancelled': return const Color(0xFFE53935);
      default: return const Color(0xFF9E9E9E);
    }
  }

  JobModel copyWith({
    String? id,
    String? customerId,
    String? workerId,
    String? panelType,
    int? panelQuantity,
    DateTime? scheduledDate,
    String? status,
    int? progressPercentage,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    double? estimatedCost,
    String? priority,
    String? location,
    double? latitude,
    double? longitude,
    CustomerModel? customer,
    String? workerName,
  }) {
    return JobModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      panelType: panelType ?? this.panelType,
      panelQuantity: panelQuantity ?? this.panelQuantity,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      customer: customer ?? this.customer,
      workerName: workerName ?? this.workerName,
    );
  }
}