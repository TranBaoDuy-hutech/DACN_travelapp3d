import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class GuideAssignmentPage extends StatefulWidget {
  const GuideAssignmentPage({super.key});

  @override
  State<GuideAssignmentPage> createState() => _GuideAssignmentPageState();
}

class _GuideAssignmentPageState extends State<GuideAssignmentPage> {
  bool isLoading = true;
  String? errorMessage;
  List assignments = [];

  @override
  void initState() {
    super.initState();
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response =
      await http.get(Uri.parse('http://127.0.0.1:8000/admin/assignments'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Assignments raw data: $data");
        setState(() {
          assignments = data['data'] ?? [];
          print("Assignments length: ${assignments.length}");
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load assignments");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        print("Error fetching assignments: $e");
      });
    }
  }

  Future<void> deleteAssignment(int tourId, int guideId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa phân công này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
            "http://127.0.0.1:8000/admin/assignments?tour_id=$tourId&guide_id=$guideId"),
      );
      print("Delete response status: ${response.statusCode}");
      print("Delete response body: ${response.body}");
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xóa thành công")),
        );
        fetchAssignments();
      } else {
        throw Exception("Failed to delete assignment");
      }
    } catch (e) {
      print("Error deleting assignment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  String formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phân công HDV"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAssignments,
            tooltip: "Làm mới danh sách",
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text("Đang tải dữ liệu...", style: TextStyle(fontSize: 16)),
          ],
        ),
      )
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              "Lỗi: $errorMessage",
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchAssignments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Thử lại", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : assignments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Chưa có phân công HDV nào",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchAssignments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Làm mới", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchAssignments,
        color: Colors.teal,
        child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final a = assignments[index];
            final role = a['Role']?.toLowerCase() ?? '';
            Color roleColor = role.contains('main')
                ? Colors.teal
                : role.contains('assistant')
                ? Colors.blue
                : Colors.grey;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor,
                  child: Text(
                    a['GuideName']?.substring(0, 1).toUpperCase() ?? 'G',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  "${a['GuideName']} (${a['Role']})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "Tour: ${a['TourName']}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "Ngày: ${formatDate(a['AssignmentDate'])}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteAssignment(a['TourID'], a['GuideID']),
                  tooltip: "Xóa phân công",
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        ),
      ),
    );
  }
}