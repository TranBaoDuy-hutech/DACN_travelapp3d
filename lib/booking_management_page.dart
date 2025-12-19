import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  bool isLoading = true;
  String? errorMessage;
  List bookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final response =
      await http.get(Uri.parse('http://127.0.0.1:8000/admin/bookings'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          bookings = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load bookings");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _showBookingDetail(Map<String, dynamic> booking) {
    final assignedGuides = booking['AssignedGuides'] ?? [];
    int? selectedGuide = assignedGuides.isNotEmpty ? assignedGuides[0]['GuideID'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final bookingIdRaw = booking['BookingID'];

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16),
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Text("PHÂN CÔNG HDV",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailRow("Tour:", booking['TourName'] ?? "Chưa rõ"),
                  _buildDetailRow("Khách hàng:", booking['CustomerName'] ?? "Chưa rõ"),
                  _buildDetailRow("Ngày:", booking['BookingDate'] ?? "Chưa rõ"),
                  _buildDetailRow("Số người:", "${booking['NumberOfPeople'] ?? 0}"),
                  _buildDetailRow("Tổng tiền:", "${booking['TotalPrice']} đ"),

                  // Hiển thị HDV hiện tại nếu có
                  if (assignedGuides.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "HDV hiện tại: ${assignedGuides[0]['GuideName']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Load HDV khả dụng
                  FutureBuilder<http.Response>(
                    future: http.get(Uri.parse(
                        'http://127.0.0.1:8000/admin/available-guides/$bookingIdRaw')),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return const Text("Lỗi tải HDV");

                      final data = json.decode(snapshot.data!.body);
                      final availableGuides = data['availableGuides'] ?? [];

                      // Thêm HDV hiện tại nếu chưa có
                      if (assignedGuides.isNotEmpty &&
                          !availableGuides.any((g) => g['GuideID'] == assignedGuides[0]['GuideID'])) {
                        availableGuides.add(assignedGuides[0]);
                      }

                      return DropdownButtonFormField<int>(
                        value: selectedGuide,
                        items: availableGuides.map<DropdownMenuItem<int>>(
                              (g) => DropdownMenuItem<int>(
                            value: g['GuideID'],
                            child: Text(g['GuideName']),
                          ),
                        ).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedGuide = val;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Chọn HDV",
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: selectedGuide == null
                        ? null
                        : () async {
                      final tourId =
                          int.tryParse(booking['TourID'].toString()) ?? 0;
                      final bookingId =
                          int.tryParse(booking['BookingID'].toString()) ?? 0;

                      final payload = {
                        "TourID": tourId,
                        "GuideID": selectedGuide,
                        "BookingID": bookingId,
                        "AssignmentDate":
                        booking['BookingDate']?.split(' ')[0] ?? "",
                        "Role": "Main Guide"
                      };

                      try {
                        final res = await http.post(
                          Uri.parse('http://127.0.0.1:8000/admin/assignments'),
                          headers: {"Content-Type": "application/json"},
                          body: json.encode(payload),
                        );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Phân công HDV thành công!"),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.pop(context);
                          fetchBookings();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Lỗi phân công: ${res.body}"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Lỗi khi gửi API: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text("Xác nhận phân công"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.black87),
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Manage Bookings"), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text("Error: $errorMessage"))
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final b = bookings[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.teal),
              title: Text("${b['TourName']} - ${b['CustomerName']}"),
              subtitle: Text(
                  "Ngày: ${b['BookingDate']} | Số người: ${b['NumberOfPeople']}"),
              trailing: Text("${b['TotalPrice']} đ",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              onTap: () => _showBookingDetail(b),
            ),
          );
        },
      ),
    );
  }
}
