import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InventoryItem {
  final String id;
  String name;
  String category;
  int quantity;
  String unit;
  double price;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'unit': unit,
    'price': price,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    quantity: json['quantity'],
    unit: json['unit'],
    price: (json['price'] as num).toDouble(),
  );
}

class InventoryManagementScreen extends ConsumerStatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  ConsumerState<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends ConsumerState<InventoryManagementScreen> {
  List<InventoryItem> _items = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Solar Panels', 'Inverters', 'Batteries', 'Cables', 'Mounting', 'Tools', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    // Load from SharedPreferences or initialize with sample data
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _items = [
        InventoryItem(id: '1', name: 'Monocrystalline Panel 400W', category: 'Solar Panels', quantity: 150, unit: 'pcs', price: 15000),
        InventoryItem(id: '2', name: 'Polycrystalline Panel 330W', category: 'Solar Panels', quantity: 80, unit: 'pcs', price: 12000),
        InventoryItem(id: '3', name: '5kW String Inverter', category: 'Inverters', quantity: 25, unit: 'pcs', price: 45000),
        InventoryItem(id: '4', name: '10kW Hybrid Inverter', category: 'Inverters', quantity: 15, unit: 'pcs', price: 85000),
        InventoryItem(id: '5', name: 'Lithium Battery 5kWh', category: 'Batteries', quantity: 30, unit: 'pcs', price: 120000),
        InventoryItem(id: '6', name: 'DC Cable 4mm²', category: 'Cables', quantity: 500, unit: 'meters', price: 45),
        InventoryItem(id: '7', name: 'AC Cable 6mm²', category: 'Cables', quantity: 300, unit: 'meters', price: 65),
        InventoryItem(id: '8', name: 'Roof Mount Kit', category: 'Mounting', quantity: 100, unit: 'sets', price: 3500),
        InventoryItem(id: '9', name: 'Ground Mount Frame', category: 'Mounting', quantity: 50, unit: 'sets', price: 8000),
        InventoryItem(id: '10', name: 'MC4 Connectors', category: 'Other', quantity: 200, unit: 'pairs', price: 150),
      ];
      _isLoading = false;
    });
  }

  List<InventoryItem> get _filteredItems {
    if (_selectedCategory == 'All') return _items;
    return _items.where((item) => item.category == _selectedCategory).toList();
  }

  void _showAddEditDialog([InventoryItem? item]) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final quantityController = TextEditingController(text: item?.quantity.toString() ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final unitController = TextEditingController(text: item?.unit ?? 'pcs');
    String selectedCategory = item?.category ?? 'Solar Panels';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(isEditing ? 'Edit Item' : 'Add Item', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setDialogState(() => selectedCategory = value!),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;

                final newItem = InventoryItem(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  category: selectedCategory,
                  quantity: int.tryParse(quantityController.text) ?? 0,
                  unit: unitController.text,
                  price: double.tryParse(priceController.text) ?? 0,
                );

                setState(() {
                  if (isEditing) {
                    final index = _items.indexWhere((i) => i.id == item.id);
                    if (index != -1) _items[index] = newItem;
                  } else {
                    _items.add(newItem);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEditing ? 'Item updated' : 'Item added'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
              child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _items.removeWhere((i) => i.id == item.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Item deleted'), backgroundColor: Colors.red.shade600),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Inventory',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : Column(
              children: [
                // Category Filter
                Container(
                  height: 50.h,
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = category),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1A237E) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Summary Cards
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Items',
                          _items.length.toString(),
                          Icons.inventory_2_outlined,
                          const Color(0xFF1A237E),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildSummaryCard(
                          'Low Stock',
                          _items.where((i) => i.quantity < 20).length.toString(),
                          Icons.warning_amber_outlined,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                // Item List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isLowStock = item.quantity < 20;
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isLowStock ? Colors.orange.shade200 : Colors.grey.shade200,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12.w),
                          leading: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              _getCategoryIcon(item.category),
                              color: const Color(0xFF1A237E),
                              size: 24.w,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4.h),
                              Text(
                                item.category,
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.orange.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      '${item.quantity} ${item.unit}',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock ? Colors.orange.shade800 : Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showAddEditDialog(item);
                              } else if (value == 'delete') {
                                _deleteItem(item);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
              Text(title, style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Solar Panels':
        return Icons.solar_power_outlined;
      case 'Inverters':
        return Icons.electrical_services_outlined;
      case 'Batteries':
        return Icons.battery_charging_full_outlined;
      case 'Cables':
        return Icons.cable_outlined;
      case 'Mounting':
        return Icons.foundation_outlined;
      case 'Tools':
        return Icons.build_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}



