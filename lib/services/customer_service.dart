import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

class CustomerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<CustomerModel>> getAllCustomers() async {
    final response = await _supabase
        .from('customers')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => CustomerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel> addCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    String? city,
    String? state,
    String? zipCode,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    }..removeWhere((key, value) => value == null);

    final response = await _supabase
        .from('customers')
        .insert(payload)
        .select()
        .single();

    return CustomerModel.fromJson(response as Map<String, dynamic>);
  }
}

