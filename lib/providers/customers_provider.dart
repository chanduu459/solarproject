import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

final customersProvider =
    StateNotifierProvider<CustomersNotifier, AsyncValue<List<CustomerModel>>>(
  (ref) => CustomersNotifier(),
);

class CustomersNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerService _customerService = CustomerService();

  CustomersNotifier() : super(const AsyncValue.loading());

  Future<void> loadAllCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _customerService.getAllCustomers();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CustomerModel> addCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    String? city,
    String? stateName,
    String? zipCode,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final newCustomer = await _customerService.addCustomer(
        fullName: fullName,
        email: email,
        phone: phone,
        address: address,
        city: city,
        state: stateName,
        zipCode: zipCode,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      final currentCustomers = state.when(
        data: (customers) => customers,
        loading: () => <CustomerModel>[],
        error: (_, __) => <CustomerModel>[],
      );

      state = AsyncValue.data([newCustomer, ...currentCustomers]);
      return newCustomer;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _customerService.deleteCustomer(customerId);

      final currentCustomers = state.when(
        data: (customers) => customers,
        loading: () => <CustomerModel>[],
        error: (_, __) => <CustomerModel>[],
      );

      state = AsyncValue.data(
        currentCustomers.where((c) => c.id != customerId).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
