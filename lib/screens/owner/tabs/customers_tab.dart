import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/providers.dart';
import '../widgets/customer_card.dart';
import '../dialogs/add_customer_page.dart';

class CustomersTab extends ConsumerStatefulWidget {
  const CustomersTab({super.key});

  @override
  ConsumerState<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<CustomersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).loadAllCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter customers based on search query
  List<dynamic> _getFilteredCustomers(List<dynamic> customers) {
    if (_searchQuery.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      final name = customer.fullName.toLowerCase();
      final email = customer.email.toLowerCase();
      final phone = customer.phone.toLowerCase();
      final address = customer.fullAddress.toLowerCase();
      final notes = customer.notes?.toLowerCase() ?? '';

      return name.contains(_searchQuery) ||
             email.contains(_searchQuery) ||
             phone.contains(_searchQuery) ||
             address.contains(_searchQuery) ||
             notes.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsyncValue = ref.watch(customersProvider);

    // Using a Scaffold here allows us to use a true Floating Action Button
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional off-white background
      body: Column(
        children: [
          _buildSearchHeader(context),
          Expanded(
            child: customersAsyncValue.when(
              data: (customers) {
                final filteredCustomers = _getFilteredCustomers(customers);

                if (customers.isEmpty) {
                  return _buildEmptyState();
                }

                if (filteredCustomers.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  // Added 80.h padding at the bottom so the FAB doesn't cover the last card
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 80.h),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    return CustomerCard(customer: customer);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)), // Solar Amber
                ),
              ),
              error: (error, stack) => _buildErrorState(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCustomerPage(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1A237E), // Deep Navy
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Customer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  // --- UI Helper Methods Below ---

  Widget _buildSearchHeader(BuildContext context) {
    final customersAsyncValue = ref.watch(customersProvider);
    final totalCustomers = customersAsyncValue.maybeWhen(
      data: (customers) => customers.length,
      orElse: () => 0,
    );
    final filteredCount = customersAsyncValue.maybeWhen(
      data: (customers) => _getFilteredCustomers(customers).length,
      orElse: () => 0,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customers',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (totalCustomers > 0) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _searchQuery.isNotEmpty
                          ? '$filteredCount of $totalCustomers customers'
                          : '$totalCustomers total customers',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 20.sp),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: Colors.grey.shade600, size: 20.sp),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                height: 48.h,
                width: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: Icon(Icons.sort_rounded, color: const Color(0xFF1A237E), size: 22.sp),
                  onPressed: _showSortOptions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Icon(Icons.people_outline, size: 64.w, color: const Color(0xFFFFB300)),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Customers Found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your client database is currently empty.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Icon(Icons.search_off_rounded, size: 64.w, color: Colors.grey.shade400),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Customers Found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'No customers match "$_searchQuery"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 16.h),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Clear Search'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A237E),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: Colors.redAccent),
          SizedBox(height: 16.h),
          Text(
            'Failed to load customers',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(customersProvider.notifier).loadAllCustomers();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sort Options Dialog ---
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort Customers',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 16.h),
            _buildSortOption(
              icon: Icons.sort_by_alpha_rounded,
              title: 'Alphabetical (A-Z)',
              subtitle: 'Sort by customer name',
              onTap: () {
                // TODO: Implement alphabetical sorting
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sorted alphabetically'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            _buildSortOption(
              icon: Icons.access_time_rounded,
              title: 'Recently Added',
              subtitle: 'Show newest customers first',
              onTap: () {
                // TODO: Implement recent sorting
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sorted by recently added'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            _buildSortOption(
              icon: Icons.location_on_rounded,
              title: 'By Location',
              subtitle: 'Group by city/area',
              onTap: () {
                // TODO: Implement location sorting
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sorted by location'),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                size: 22.w,
                color: const Color(0xFF1A237E),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24.w,
            ),
          ],
        ),
      ),
    );
  }
}