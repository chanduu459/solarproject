import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/providers.dart';
import '../../services/services.dart';
import '../login_screen.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/workers_tab.dart';
import 'tabs/customers_tab.dart';
import 'tabs/jobs_tab.dart';
import 'tabs/issues_tab.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  int _currentIndex = 0;
  Map<String, dynamic> _statistics = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    // CRITICAL FIX: Wait for the first frame to draw before loading data
    // This prevents the Riverpod "setState during build" crash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await _loadStatistics();

    // Only fetch if the widget is still on screen
    if (!mounted) return;

    await ref.read(jobsProvider.notifier).loadAllJobs();
    await ref.read(attendanceProvider.notifier).loadAllAttendance();
    await ref.read(issuesProvider.notifier).loadAllIssues();
  }

  Future<void> _loadStatistics() async {
    try {
      final jobService = JobService();
      final attendanceService = AttendanceService();
      final issueService = IssueReportService();

      final jobStats = await jobService.getJobStatistics();
      final attendanceStats = await attendanceService.getAttendanceStatistics();
      final issueStats = await issueService.getIssueStatistics();

      if (mounted) {
        setState(() {
          _statistics = {
            ...jobStats,
            ...attendanceStats,
            ...issueStats,
          };
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardTab(statistics: _statistics, isLoading: _isLoadingStats),
      const WorkersTab(),
      const CustomersTab(),
      const JobsTab(),
      const IssuesTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Owner Dashboard',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Workers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_circle),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Issues',
          ),
        ],
      ),
    );
  }
}

