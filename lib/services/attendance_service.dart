import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';
import 'package:geolocator/geolocator.dart';
class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check in - Start work
  Future<AttendanceModel> checkIn({
    required String workerId,
    required String jobId,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) async {
    try {
      final attendanceData = {
        'worker_id': workerId,
        'job_id': jobId,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_in_latitude': latitude,
        'check_in_longitude': longitude,
        'check_in_address': address,
        'status': 'checked_in',
        'notes': notes,
      };

      final response = await _supabase
          .from('attendance')
          .insert(attendanceData)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to check in: $e');
    }
  }

  // Check out - End work
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    double? latitude,
    double? longitude,
    String? address,
    String? notes,
  }) async {
    try {
      final checkOutTime = DateTime.now();
      
      // Get the attendance record to calculate working hours
      final attendance = await _supabase
          .from('attendance')
          .select()
          .eq('id', attendanceId)
          .single();

      final checkInTime = DateTime.parse(attendance['check_in_time'] as String);
      final workingHours = checkOutTime.difference(checkInTime).inMinutes;

      final updates = <String, dynamic>{
        'check_out_time': checkOutTime.toIso8601String(),
        'check_out_latitude': latitude,
        'check_out_longitude': longitude,
        'check_out_address': address,
        'status': 'checked_out',
        'working_hours': workingHours,
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      final response = await _supabase
          .from('attendance')
          .update(updates)
          .eq('id', attendanceId)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to check out: $e');
    }
  }

  // Get attendance by ID
  Future<AttendanceModel?> getAttendanceById(String attendanceId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('id', attendanceId)
          .single();

      if (response != null) {
        return AttendanceModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  // Get active attendance for a worker (checked in but not checked out)
  Future<AttendanceModel?> getActiveAttendance(String workerId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('worker_id', workerId)
          .eq('status', 'checked_in')
          .order('check_in_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return AttendanceModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch active attendance: $e');
    }
  }

  // Get attendance for a specific job
  Future<AttendanceModel?> getJobAttendance(String jobId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('job_id', jobId)
          .order('check_in_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return AttendanceModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch job attendance: $e');
    }
  }

  // Get all attendance records for a worker
  Future<List<AttendanceModel>> getWorkerAttendance(String workerId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select()
          .eq('worker_id', workerId)
          .order('check_in_time', ascending: false);

      return response.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch worker attendance: $e');
    }
  }

  // Get today's attendance for a worker
  Future<List<AttendanceModel>> getTodayAttendance(String workerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('attendance')
          .select()
          .eq('worker_id', workerId)
          .gte('check_in_time', startOfDay.toIso8601String())
          .lt('check_in_time', endOfDay.toIso8601String())
          .order('check_in_time', ascending: false);

      return response.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch today attendance: $e');
    }
  }

  // Get all attendance records (for owner)
  Future<List<AttendanceModel>> getAllAttendance() async {
    try {
      final response = await _supabase
          .from('attendance')
          .select('*, workers (full_name)')
          .order('check_in_time', ascending: false);

      return response.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all attendance: $e');
    }
  }

  // Get attendance by date range
  Future<List<AttendanceModel>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? workerId,
  }) async {
    try {
      var query = _supabase
          .from('attendance')
          .select('*, workers (full_name)')
          .gte('check_in_time', startDate.toIso8601String())
          .lt('check_in_time', endDate.toIso8601String());

      if (workerId != null) {
        query = query.eq('worker_id', workerId);
      }

      final response = await query.order('check_in_time', ascending: false);

      return response.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance by date range: $e');
    }
  }

  // Get attendance statistics
  Future<Map<String, dynamic>> getAttendanceStatistics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).toUtc().toIso8601String();

      // Get all active workers (role = 'worker' and is_active = true) - exclude owners
      final activeWorkersResponse = await _supabase
          .from('workers')
          .select('id')
          .eq('role', 'worker')
          .eq('is_active', true);

      final validWorkerIds = activeWorkersResponse
          .map((r) => r['id'] as String)
          .toSet();

      // Total active workers in system (role = 'worker' and is_active = true)
      final totalActiveWorkers = validWorkerIds.length;

      // Get workers with jobs in progress (truly active workers)
      final workersWithInProgressJobs = await _supabase
          .from('jobs')
          .select('worker_id')
          .eq('status', 'in_progress');

      final activeWorkerIds = workersWithInProgressJobs
          .where((r) => r['worker_id'] != null)
          .map((r) => r['worker_id'] as String)
          .where((id) => validWorkerIds.contains(id)) // Only count valid workers
          .toSet();

      // Also get workers checked in today from attendance
      final checkedInTodayResponse = await _supabase
          .from('attendance')
          .select('worker_id')
          .gte('check_in_time', startOfDay)
          .lt('check_in_time', endOfDay);

      final checkedInWorkerIds = checkedInTodayResponse
          .map((r) => r['worker_id'] as String)
          .where((id) => validWorkerIds.contains(id)) // Only count valid workers
          .toSet();

      // Combine both sets - workers are active if they have in_progress jobs OR checked in today
      final allActiveWorkerIds = activeWorkerIds.union(checkedInWorkerIds);

      // Get currently checked in workers (active right now via attendance)
      final currentlyCheckedInResponse = await _supabase
          .from('attendance')
          .select('worker_id')
          .eq('status', 'checked_in');

      final currentlyCheckedIn = currentlyCheckedInResponse
          .map((r) => r['worker_id'] as String)
          .where((id) => validWorkerIds.contains(id)) // Only count valid workers
          .toSet()
          .length;

      return {
        'total_active_workers': totalActiveWorkers, // All workers with is_active=true
        'workers_active_today': allActiveWorkerIds.length, // Workers working today
        'currently_checked_in': currentlyCheckedIn,
      };
    } catch (e) {
      throw Exception('Failed to get attendance statistics: $e');
    }
  }

  // Update attendance notes
  Future<AttendanceModel> updateNotes({
    required String attendanceId,
    required String notes,
  }) async {
    try {
      final response = await _supabase
          .from('attendance')
          .update({'notes': notes})
          .eq('id', attendanceId)
          .select()
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update attendance notes: $e');
    }
  }
}
