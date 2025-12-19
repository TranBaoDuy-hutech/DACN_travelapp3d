import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/admin/users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = data['data'];
        });
      } else {
        throw Exception("Lỗi lấy danh sách nhân viên");
      }
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(Uri.parse('http://127.0.0.1:8000/admin/users/$userId'));
      if (response.statusCode == 200) {
        fetchUsers();
      } else {
        throw Exception("Xóa nhân viên thất bại");
      }
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Future<void> showUserForm({Map? user}) async {
    final usernameController = TextEditingController(text: user?['Username'] ?? '');
    final fullnameController = TextEditingController(text: user?['FullName'] ?? '');
    final emailController = TextEditingController(text: user?['Email'] ?? '');
    final roleController = TextEditingController(text: user?['RoleID']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? "Thêm Nhân viên" : "Sửa Nhân viên"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
              TextField(controller: fullnameController, decoration: const InputDecoration(labelText: "Họ và tên")),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: roleController, decoration: const InputDecoration(labelText: "RoleID"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final userData = {
                "Username": usernameController.text,
                "FullName": fullnameController.text,
                "Email": emailController.text,
                "RoleID": int.tryParse(roleController.text) ?? 1,
              };

              try {
                if (user == null) {
                  await http.post(
                    Uri.parse('http://127.0.0.1:8000/admin/users'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(userData),
                  );
                } else {
                  await http.put(
                    Uri.parse('http://127.0.0.1:8000/admin/users/${user['UserID']}'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(userData),
                  );
                }
                fetchUsers();
                Navigator.pop(context);
              } catch (e) {
                print("Error saving user: $e");
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
      appBar: AppBar(title: const Text("Manage Staff"), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(child: Text("Chưa có nhân viên nào.", style: TextStyle(fontSize: 18)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(user['Username']),
              subtitle: Text("${user['FullName']} • Role: ${user['RoleID']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => showUserForm(user: user)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteUser(user['UserID'])),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUserForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
