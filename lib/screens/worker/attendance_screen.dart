import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../../models/models.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final LocationService _locationService = LocationService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      await ref.read(attendanceProvider.notifier).loadTodayAttendance(user.id);
      await ref.read(attendanceProvider.notifier).loadActiveAttendance(user.id);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isProcessing = true);

    try {
      // Validate location
      final locationValidation = await _locationService.validateAttendanceLocation();
      
      if (!locationValidation['valid']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(locationValidation['message'])),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      final position = locationValidation['position'] as Position?;
      final address = await _locationService.getAddressFromCoordinates(
        position?.latitude ?? 0,
        position?.longitude ?? 0,
      );

      final user = ref.read(authProvider).user;
      final jobsState = ref.read(jobsProvider);
      
      if (user == null) {
        setState(() => _isProcessing = false);
        return;
      }

      // Get the first pending or in-progress job for today
      JobModel? todayJob;
      try {
        todayJob = jobsState.todayJobs.firstWhere(
          (j) => j.status == 'pending' || j.status == 'in_progress',
        );
      } catch (e) {
        todayJob = jobsState.todayJobs.isNotEmpty ? jobsState.todayJobs.first : null;
      }

      if (todayJob == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No job assigned for today')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      await ref.read(attendanceProvider.notifier).checkIn(
        workerId: user.id,
        jobId: todayJob.id,
        latitude: position?.latitude,
        longitude: position?.longitude,
        address: address,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked in successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check in: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isProcessing = true);

    try {
      final attendanceState = ref.read(attendanceProvider);
      final activeAttendance = attendanceState.activeAttendance;

      if (activeAttendance == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active attendance found')),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Get current location
      final position = await _locationService.getCurrentPosition();
      final address = position != null
          ? await _locationService.getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            )
          : null;

      await ref.read(attendanceProvider.notifier).checkOut(
        attendanceId: activeAttendance.id,
        latitude: position?.latitude,
        longitude: position?.longitude,
        address: address,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check out: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);
    final isCheckedIn = attendanceState.isCheckedIn;
    final activeAttendance = attendanceState.activeAttendance;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status card
              _buildStatusCard(isCheckedIn, activeAttendance),
              SizedBox(height: 24.h),
              // Check in/out button
              _buildActionButton(isCheckedIn),
              SizedBox(height: 24.h),
              // Today's attendance history
              Text(
                'Today\'s Attendance',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              _buildAttendanceHistory(attendanceState.attendanceRecords),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isCheckedIn, AttendanceModel? activeAttendance) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCheckedIn
              ? [const Color(0xFF43A047), const Color(0xFF2E7D32)]
              : [const Color(0xFF9E9E9E), const Color(0xFF757575)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? const Color(0xFF43A047) : const Color(0xFF9E9E9E))
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isCheckedIn ? Icons.check_circle : Icons.access_time,
            size: 64.w,
            color: Colors.white,
          ),
          SizedBox(height: 16.h),
          Text(
            isCheckedIn ? 'You are Checked In' : 'You are Checked Out',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          if (isCheckedIn && activeAttendance != null) ...[
            Text(
              'Checked in at ${_formatTime(activeAttendance.checkInTime)}',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            if (activeAttendance.checkInAddress != null) ...[
              SizedBox(height: 4.h),
              Text(
                activeAttendance.checkInAddress!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isCheckedIn) {
    return SizedBox(
      height: 56.h,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : (isCheckedIn ? _checkOut : _checkIn),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCheckedIn ? const Color(0xFFE53935) : const Color(0xFF43A047),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isCheckedIn ? Icons.logout : Icons.login),
                  SizedBox(width: 12.w),
                  Text(
                    isCheckedIn ? 'Check Out' : 'Check In',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAttendanceHistory(List<AttendanceModel> records) {
    if (records.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48.w,
              color: Colors.grey,
            ),
            SizedBox(height: 12.h),
            Text(
              'No attendance records for today',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: record.isCheckedOut
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                record.isCheckedOut ? Icons.logout : Icons.login,
                color: record.isCheckedOut ? Colors.red : Colors.green,
              ),
            ),
            title: Text(
              record.isCheckedOut ? 'Checked Out' : 'Checked In',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time: ${_formatTime(record.checkInTime)}',
                  style: TextStyle(fontSize: 12.sp),
                ),
                if (record.workingHours != null)
                  Text(
                    'Duration: ${record.durationDisplay}',
                    style: TextStyle(fontSize: 12.sp),
                  ),
              ],
            ),
            trailing: record.isCheckedOut
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.timelapse, color: Colors.orange),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
