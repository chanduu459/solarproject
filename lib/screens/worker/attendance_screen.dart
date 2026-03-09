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
            SnackBar(
              content: Text(locationValidation['message']),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
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
            SnackBar(
              content: const Text('No job assigned for today'),
              backgroundColor: const Color(0xFFF57C00),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
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
          SnackBar(
            content: const Text('Checked in successfully'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
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
            SnackBar(
              content: const Text('No active attendance found'),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
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
          SnackBar(
            content: const Text('Checked out successfully'),
            backgroundColor: const Color(0xFF1A237E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check out: $e'),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
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
    final records = attendanceState.attendanceRecords;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white
      body: Column(
        children: [
          _buildScreenHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAttendance,
              color: const Color(0xFF1A237E),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatusCard(isCheckedIn, activeAttendance),
                          SizedBox(height: 24.h),
                          _buildActionButton(isCheckedIn),
                          SizedBox(height: 32.h),
                          Text('Today\'s Log', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                  if (records.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _buildEmptyState(),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildAttendanceRecord(records[index]),
                          childCount: records.length,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildScreenHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time & Attendance',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A), letterSpacing: -0.5),
          ),
          SizedBox(height: 4.h),
          Text(
            'Log your shift hours and location.',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isCheckedIn, AttendanceModel? activeAttendance) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCheckedIn
              ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)] // Active Green Gradient
              : [const Color(0xFF1A237E), const Color(0xFF0D47A1)], // Deep Navy Gradient
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? const Color(0xFF2E7D32) : const Color(0xFF1A237E)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(
              isCheckedIn ? Icons.how_to_reg_rounded : Icons.pending_actions_rounded,
              size: 40.w,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            isCheckedIn ? 'ON THE CLOCK' : 'OFF DUTY',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), letterSpacing: 1.5),
          ),
          SizedBox(height: 8.h),
          Text(
            isCheckedIn ? 'You are actively tracking time.' : 'You are currently clocked out.',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (isCheckedIn && activeAttendance != null) ...[
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_rounded, color: Colors.white70, size: 16.w),
                      SizedBox(width: 8.w),
                      Text('Started at ${_formatTime(activeAttendance.checkInTime)}', style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (activeAttendance.checkInAddress != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on_outlined, color: Colors.white70, size: 16.w),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            activeAttendance.checkInAddress!,
                            style: TextStyle(fontSize: 13.sp, color: Colors.white70, height: 1.4),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isCheckedIn) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32)).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 60.h,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : (isCheckedIn ? _checkOut : _checkIn),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCheckedIn ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
          child: _isProcessing
              ? SizedBox(height: 24.h, width: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isCheckedIn ? Icons.timer_off_rounded : Icons.timer_rounded, size: 24.w),
              SizedBox(width: 12.w),
              Text(
                isCheckedIn ? 'CLOCK OUT' : 'CLOCK IN',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: const Color(0xFFF1F3F4), shape: BoxShape.circle),
            child: Icon(Icons.history_rounded, size: 40.w, color: const Color(0xFF1A237E)),
          ),
          SizedBox(height: 16.h),
          Text('No Records Yet', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
          SizedBox(height: 8.h),
          Text('Your attendance logs for today will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecord(AttendanceModel record) {
    final bool isCompleted = record.isCheckedOut;
    final Color statusColor = isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFFFB300); // Green if finished, Amber if open

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 6.w)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                  child: Icon(isCompleted ? Icons.task_alt_rounded : Icons.pending_actions_rounded, color: statusColor, size: 24.w),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isCompleted ? 'Completed Shift' : 'Active Shift',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: const Color(0xFF1A1A1A)),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                            child: Text(
                              isCompleted ? 'Closed' : 'Open',
                              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Icon(Icons.login_rounded, size: 14.w, color: Colors.grey.shade500),
                          SizedBox(width: 6.w),
                          Text('In: ${_formatTime(record.checkInTime)}', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      if (isCompleted && record.checkOutTime != null) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 14.w, color: Colors.grey.shade500),
                            SizedBox(width: 6.w),
                            Text('Out: ${_formatTime(record.checkOutTime!)}', style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                      if (record.workingHours != null) ...[
                        SizedBox(height: 12.h),
                        const Divider(height: 1),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(Icons.timelapse_rounded, size: 14.w, color: const Color(0xFF1A237E)),
                            SizedBox(width: 6.w),
                            Text(
                              'Total Duration: ${record.durationDisplay}',
                              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF1A237E), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    // Convert to 12-hour format with AM/PM for a more natural reading experience
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }
}