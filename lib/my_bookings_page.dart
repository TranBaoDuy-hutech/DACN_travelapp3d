import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;
import 'package:intl/intl.dart';
import 'booking_detail_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> bookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final customer = globals.currentCustomer;
      if (customer == null) {
        setState(() {
          isLoading = false;
          errorMessage = "Bạn chưa đăng nhập";
        });
        return;
      }

      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/bookings/${customer.customerID}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> fetchedBookings = data is List ? data : [data];

        // Sắp xếp theo ngày gần nhất trước
        fetchedBookings.sort((a, b) {
          final da = DateTime.parse(a['date']);
          final db = DateTime.parse(b['date']);
          return db.compareTo(da);
        });

        setState(() {
          bookings = fetchedBookings;
          globals.myBookings = bookings; // Đồng bộ với globals để AccountPage cập nhật realtime
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Lỗi server: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Không thể kết nối đến server. Vui lòng kiểm tra mạng.";
      });
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "0 đ";
    try {
      final numVal = value is num ? value : num.parse(value.toString());
      final formatter = NumberFormat("#,###", "vi_VN");
      return "${formatter.format(numVal)} đ";
    } catch (_) {
      return "0 đ";
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return "Chưa rõ";
    try {
      final date = DateTime.parse(rawDate.toString());
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (_) {
      return "Chưa rõ";
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'đã xác nhận':
        return Colors.green;
      case 'pending':
      case 'chờ xác nhận':
        return Colors.orange;
      case 'cancelled':
      case 'đã hủy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Tour đã đặt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
          strokeWidth: 3,
        ),
      )
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchBookings,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      )
          : bookings.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Bạn chưa đặt tour nào",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "Hãy khám phá và đặt tour ngay!",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchBookings,
        color: Colors.teal,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final tourName = booking['tourName']?.toString() ?? "Tour không tên";
            final date = _formatDate(booking['date']);
            final numPeople = booking['numPeople']?.toString() ?? "0";
            final totalPrice = _formatCurrency(booking['totalPrice']);
            final status = (booking['status']?.toString() ?? "pending");

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailPage(booking: booking),
                    ),
                  ).then((_) {
                    // TỰ ĐỘNG CẬP NHẬT DANH SÁCH KHI QUAY LẠI (ví dụ: hủy tour thành công)
                    fetchBookings();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tour_rounded, color: Colors.teal, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tourName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Ngày khởi hành: $date",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$numPeople khách",
                            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                          ),
                          Text(
                            totalPrice,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}