import 'package:flutter/material.dart';
class AppConstants {
  // Supabase Configuration
  // Configured with project credentials
  static const String supabaseUrl = 'https://jmsfihtndxwycnlwzbnj.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_OiD-xOJbseiC5T1vYBlxRg_VY761wgZ';

  // Storage Buckets
  static const String installationImagesBucket = 'solarbucket';
  static const String signaturesBucket = 'solarbucket';
  
  // User Roles
  static const String roleOwner = 'owner';
  static const String roleWorker = 'worker';
  
  // Job Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Progress Percentages
  static const List<int> progressSteps = [0, 25, 50, 75, 100];
  
  // Image Types
  static const String imageTypeBefore = 'before';
  static const String imageTypeDuring = 'during';
  static const String imageTypeAfter = 'after';
  
  // Issue Types
  static const List<String> issueTypes = [
    'Broken Panels',
    'Missing Equipment',
    'Customer Issues',
    'Weather Delay',
    'Safety Concern',
    'Other',
  ];
  
  // App Colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF43A047);
  static const Color accentColor = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF1E88E5);
  
  // Offline Sync
  static const String pendingSyncBox = 'pending_sync';
  static const String offlineDataBox = 'offline_data';
}

// Extension for Color since we can't use const with Color in class
extension AppColors on Color {
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF43A047);
  static const Color accentColor = Color(0xFFFFA726);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF1E88E5);
  static const Color darkColor = Color(0xFF263238);
  static const Color lightColor = Color(0xFFF5F5F5);
  static const Color greyColor = Color(0xFF9E9E9E);
}
