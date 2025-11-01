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
  List bookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
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
        Uri.parse("http://10.0.2.2:8000/bookings/${customer.customerID}"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          bookings = data is List ? data : [data];
          bookings.sort((a, b) {
            final da = DateTime.parse(a['date']);
            final db = DateTime.parse(b['date']);
            return db.compareTo(da);
          });
          globals.myBookings = bookings;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
          "Server trả về lỗi ${response.statusCode}: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Lỗi khi tải dữ liệu: $e";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tour đã đặt")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : bookings.isEmpty
          ? const Center(child: Text("Bạn chưa đặt tour nào"))
          : RefreshIndicator(
        onRefresh: fetchBookings,
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final tourName = booking['tourName']?.toString() ?? "Chưa rõ";
            final date = _formatDate(booking['date']);
            final numPeople = booking['numPeople']?.toString() ?? "Chưa rõ";
            final totalPrice = _formatCurrency(booking['totalPrice']);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.tour, color: Colors.teal, size: 32),
                title: Text(tourName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text("Ngày: $date | Khách: $numPeople"),
                trailing: Text(totalPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingDetailPage(booking: booking),
                    ),
                  ).then((_) => fetchBookings());
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
