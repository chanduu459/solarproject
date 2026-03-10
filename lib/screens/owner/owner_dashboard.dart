import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adjust these paths based on your actual folder structure
import '../../providers/providers.dart';
import '../login_screen.dart';
import 'tabs/tabs_exports.dart';
import 'providers/providers_exports.dart';

// Explicitly importing the newly redesigned CustomersTab
import './tabs/customers_tab.dart';

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load dashboard data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    await ref.read(dashboardProvider.notifier).loadDashboardData();
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
    final dashboardState = ref.watch(dashboardProvider);

    final screens = [
      DashboardTab(
        statistics: dashboardState.statistics,
        isLoading: dashboardState.isLoading,
        onTabChange: (index) => setState(() => _currentIndex = index),
        onLogout: _signOut,
      ),
      const WorkersTab(),
      const CustomersTab(), // Your newly redesigned Enterprise Tab!
      const JobsTab(),
    ];

    return Scaffold(
      // Match the soft off-white background from the CustomersTab
      backgroundColor: const Color(0xFFF8F9FA),

      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 20, // Slightly higher elevation for a floating SaaS feel
        shadowColor: Colors.black.withValues(alpha: 0.1),
        // Solar Amber indicator for the selected tab
        indicatorColor: const Color(0xFFFFB300).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.black54),
              // Deep Navy for selected icons
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF1A237E)),
              label: 'Overview'
          ),
          NavigationDestination(
              icon: Icon(Icons.people_outline, color: Colors.black54),
              selectedIcon: Icon(Icons.people, color: Color(0xFF1A237E)),
              label: 'Employees'
          ),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined, color: Colors.black54),
              selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFF1A237E)),
              label: 'Orders'
          ),
          NavigationDestination(
              icon: Icon(Icons.work_outline, color: Colors.black54),
              selectedIcon: Icon(Icons.work, color: Color(0xFF1A237E)),
              label: 'Jobs'
          ),
        ],
      ),
    );
  }
}