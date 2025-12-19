import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TourManagementPage extends StatefulWidget {
  const TourManagementPage({super.key});

  @override
  State<TourManagementPage> createState() => _TourManagementPageState();
}

class _TourManagementPageState extends State<TourManagementPage> {
  List tours = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTours();
  }

  Future<void> fetchTours() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/admin/tours'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => tours = data['data']);
      } else {
        throw Exception("Lỗi lấy danh sách tour");
      }
    } catch (e) {
      print("Error fetching tours: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteTour(int tourId) async {
    try {
      final response = await http.delete(Uri.parse('http://127.0.0.1:8000/admin/tours/$tourId'));
      if (response.statusCode == 200) {
        fetchTours();
      } else {
        throw Exception("Xóa tour thất bại");
      }
    } catch (e) {
      print("Error deleting tour: $e");
    }
  }

  Future<void> showTourForm({Map? tour}) async {
    final nameController = TextEditingController(text: tour?['TourName'] ?? '');
    final locationController = TextEditingController(text: tour?['Location'] ?? '');
    final priceController = TextEditingController(text: tour?['Price']?.toString() ?? '');
    final durationController = TextEditingController(text: tour?['DurationDays']?.toString() ?? '');
    final startDateController = TextEditingController(text: tour?['StartDate'] ?? '');
    final imageController = TextEditingController(text: tour?['ImageUrl'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tour == null ? "Thêm Tour" : "Sửa Tour"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên tour")),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: "Địa điểm")),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: "Giá"), keyboardType: TextInputType.number),
              TextField(controller: durationController, decoration: const InputDecoration(labelText: "Số ngày"), keyboardType: TextInputType.number),
              TextField(controller: startDateController, decoration: const InputDecoration(labelText: "Ngày khởi hành (YYYY-MM-DD)")),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: "Tên file hình (assets)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final tourData = {
                "TourName": nameController.text,
                "Location": locationController.text,
                "Price": double.tryParse(priceController.text) ?? 0,
                "DurationDays": int.tryParse(durationController.text) ?? 1,
                "StartDate": startDateController.text,
                "ImageUrl": imageController.text,
              };

              try {
                if (tour == null) {
                  await http.post(
                    Uri.parse('http://127.0.0.1:8000/admin/tours'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(tourData),
                  );
                } else {
                  await http.put(
                    Uri.parse('http://127.0.0.1:8000/admin/tours/${tour['TourID']}'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode(tourData),
                  );
                }
                fetchTours();
                Navigator.pop(context);
              } catch (e) {
                print("Error saving tour: $e");
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Widget tourImage(Map tour) {
    String imageName = tour['ImageUrl'] ?? "";

    // Xử lý trường hợp lặp "assets/"
    if (imageName.startsWith("/assets/")) {
      imageName = imageName.replaceFirst("/assets/", "");
    } else if (imageName.startsWith("assets/")) {
      imageName = imageName.replaceFirst("assets/", "");
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          image: imageName.isNotEmpty
              ? DecorationImage(
            image: AssetImage('assets/$imageName'),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: imageName.isEmpty
            ? const Icon(Icons.tour, size: 40, color: Colors.white)
            : null,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Tour"), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tours.isEmpty
          ? const Center(child: Text("Chưa có tour nào.", style: TextStyle(fontSize: 18)))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tours.length,
        itemBuilder: (context, index) {
          final tour = tours[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  tourImage(tour),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tour['TourName'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("${tour['Location']} • ${tour['DurationDays']} ngày"),
                        const SizedBox(height: 4),
                        Text("${tour['Price'].toStringAsFixed(0)} đ", style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => showTourForm(tour: tour)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteTour(tour['TourID'])),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTourForm(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
