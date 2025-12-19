import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({super.key});

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  List customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/admin/customers'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          customers = data['data'];
        });
      } else {
        throw Exception("Lỗi lấy danh sách khách hàng");
      }
    } catch (e) {
      print("Error fetching customers: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteCustomer(int customerId) async {
    try {
      final response = await http.delete(Uri.parse('http://127.0.0.1:8000/admin/customers/$customerId'));
      if (response.statusCode == 200) {
        fetchCustomers();
      } else {
        throw Exception("Xóa khách hàng thất bại");
      }
    } catch (e) {
      print("Error deleting customer: $e");
    }
  }

  Future<void> showCustomerForm({Map? customer}) async {
    final nameController = TextEditingController(text: customer?['UserName'] ?? '');
    final emailController = TextEditingController(text: customer?['Email'] ?? '');
    final phoneController = TextEditingController(text: customer?['Phone'] ?? '');
    final addressController = TextEditingController(text: customer?['Address'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? "Thêm Khách hàng" : "Sửa Khách hàng"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "SĐT")),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: "Địa chỉ")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final customerData = {
                "UserName": nameController.text,
                "Email": emailController.text,
                "Phone": phoneController.text,
                "Address": addressController.text,
              };

              try {
                if (customer == null) {
                  await http.post(
                    Uri.parse('http://127.0.0.1:8000/admin/customers'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(customerData),
                  );
                } else {
                  await http.put(
                    Uri.parse('http://127.0.0.1:8000/admin/customers/${customer['CustomerID']}'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(customerData),
                  );
                }
                fetchCustomers();
                Navigator.pop(context);
              } catch (e) {
                print("Error saving customer: $e");
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Customers"), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customers.isEmpty
          ? const Center(child: Text("Chưa có khách hàng nào.", style: TextStyle(fontSize: 18)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(customer['UserName']),
              subtitle: Text("${customer['Email']} • ${customer['Phone']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => showCustomerForm(customer: customer)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteCustomer(customer['CustomerID'])),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomerForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
