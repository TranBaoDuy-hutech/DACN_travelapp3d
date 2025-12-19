import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic> tour;
  const BookingPage({Key? key, required this.tour}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  int _numGuests = 1;
  DateTime? _selectedDate;
  String _specialRequests = "";
  bool _isLoading = false;

  bool _agreePolicy = false;
  bool _hasReadPolicy = false;

  String formatPrice(dynamic price) {
    final formatter = NumberFormat("#,##0", "vi_VN");
    final parsed = double.tryParse(price?.toString() ?? "0") ?? 0;
    return "${formatter.format(parsed)} VND";
  }

  double get totalPrice {
    final price = double.tryParse(widget.tour["Price"]?.toString() ?? "0") ?? 0;
    return price * _numGuests;
  }

  Future<bool?> showPolicyDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Lưu ý trước khi đặt tour"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("❗ Hủy tour trước ngày khởi hành 7 ngày."),
              SizedBox(height: 8),
              Text("💵 Thanh toán đủ 100% tổng giá trị tour vào ngay ngày khởi hành."),
              SizedBox(height: 8),
              Text("📅 Ngày khởi hành không thể thay đổi sau khi xác nhận."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Đồng ý"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFullPolicyDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.policy, color: Colors.teal),
            SizedBox(width: 8),
            Expanded(child: Text("Chính sách đặt tour & Quy định bảo mật")),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _policySection("Chính sách hủy tour", [
                  "Trước 7 ngày: được phép hủy tour.",
                  "Sau 7 ngày: KHÔNG chấp nhận hủy tour trong mọi trường hợp.",
                ]),
                _policySection("Thanh toán", [
                  "Thanh toán đủ 100% tổng giá trị tour vào ngay ngày khởi hành.",
                  "Các hình thức thanh toán được chấp nhận: Chuyển khoản ngân hàng hoặc Tiền mặt.",
                ]),
                _policySection("Thông tin cá nhân", [
                  "Chúng tôi cam kết bảo mật tuyệt đối thông tin cá nhân của khách hàng.",
                  "Thông tin chỉ được sử dụng để phục vụ tour và gửi thông tin xác nhận liên quan.",
                  "Thông tin không được chia sẻ cho bên thứ ba nếu chưa có sự đồng ý của khách hàng.",
                ]),
                _policySection("Trách nhiệm khách hàng", [
                  "Cung cấp thông tin chính xác (Họ tên, CMND/CCCD, Số điện thoại).",
                  "Có mặt đúng giờ tại điểm đón đã quy định.",
                  "Tuân thủ nghiêm ngặt các hướng dẫn của hướng dẫn viên trong suốt chuyến đi.",
                  "Tuyệt đối không tự ý rời khỏi đoàn khi chưa có sự đồng ý của hướng dẫn viên.",
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              setState(() {
                _hasReadPolicy = true;
                _agreePolicy = true;
              });
              Navigator.pop(context);
            },
            child: const Text("Tôi đã đọc và đồng ý"),
          ),
        ],
      ),
    );
  }

  Widget _policySection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Text("• $item", style: const TextStyle(fontSize: 14)),
          )),
        ],
      ),
    );
  }

  Future<void> confirmBooking() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _agreePolicy) {
      if (_selectedDate!.isBefore(DateTime.now().add(const Duration(days: -1)))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ngày khởi hành phải từ hôm nay trở đi")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final customer = globals.currentCustomer;
        if (customer == null) {
          throw Exception("Vui lòng đăng nhập để đặt tour");
        }

        final bookingData = {
          "CustomerID": customer.customerID ?? 0,
          "TourID": widget.tour['TourID'] ?? 0,
          "BookingDate": _selectedDate!.toIso8601String().split('T')[0],
          "NumberOfPeople": _numGuests,
          "TotalPrice": totalPrice,
          "SpecialRequests": _specialRequests.isEmpty ? null : _specialRequests,
        };

        final response = await http.post(
          Uri.parse("http://127.0.0.1:8000/bookings"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(bookingData),
        );

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception("Lỗi server: ${response.body}");
        }

        final resJson = jsonDecode(response.body);
        final bookingID = resJson["BookingID"] ?? resJson["booking_id"] ?? "Không có ID";
        final emailSent = resJson["EmailSent"] ?? true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            content: Text(
              "Đặt tour thành công!\nMã Booking: $bookingID\n${emailSent ? "Email xác nhận đã được gửi" : "Lỗi gửi email"}",
              style: const TextStyle(fontSize: 15),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 4));
        Navigator.pop(context, bookingID);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi đặt tour: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ và đồng ý chính sách")),
      );
    }
  }

  Widget buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final customer = globals.currentCustomer;

    // Nếu customer null → hiển thị lỗi hoặc redirect login
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đặt Tour")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Vui lòng đăng nhập để đặt tour", style: TextStyle(fontSize: 20, color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Redirect về login page (thay bằng route của bạn)
                  Navigator.pop(context);
                },
                child: const Text("Đăng nhập ngay"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Đặt Tour: ${tour['TourName'] ?? 'Tour không tên'}"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal, Colors.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  buildSectionCard(title: "Thông tin khách hàng", children: [
                    Text("Tên: ${customer.userName ?? 'Chưa cập nhật'}"),
                    Text("Email: ${customer.email ?? 'Chưa cập nhật'}"),
                    Text("Số điện thoại: ${customer.phone ?? 'Chưa cập nhật'}"),
                  ]),

                  buildSectionCard(title: "Thông tin tour", children: [
                    Text("Địa điểm: ${tour['Location'] ?? '-'}"),
                    Text("Giá: ${formatPrice(tour['Price'])} / khách"),
                    Text("Thời gian: ${tour['DurationDays'] ?? '-'} ngày"),
                    Text("Điểm xuất phát: ${tour['DepartureLocation'] ?? '-'}"),
                    Text("Khách sạn: ${tour['HotelName'] ?? '-'}"),
                    Text("Phương tiện: ${tour['Transportation'] ?? '-'}"),
                  ]),

                  buildSectionCard(title: "Chi tiết đặt tour", children: [
                    TextFormField(
                      initialValue: '1',
                      decoration: InputDecoration(
                        labelText: "Số lượng khách",
                        prefixIcon: const Icon(Icons.people, color: Colors.teal),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Vui lòng nhập số khách";
                        final n = int.tryParse(val);
                        if (n == null || n < 1) return "Tối thiểu 1 khách";
                        if (n > 50) return "Tối đa 50 khách";
                        return null;
                      },
                      onChanged: (val) {
                        final n = int.tryParse(val) ?? 1;
                        setState(() => _numGuests = n.clamp(1, 50));
                      },
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      tileColor: Colors.teal[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(_selectedDate == null
                          ? "Chọn ngày khởi hành"
                          : "Ngày khởi hành: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}"),
                      trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                      onTap: _isLoading
                          ? null
                          : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Yêu cầu đặc biệt (không bắt buộc)",
                        hintText: "VD: Phòng view biển, ăn chay, xe riêng...",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (val) => _specialRequests = val,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreePolicy,
                          activeColor: Colors.teal,
                          onChanged: _hasReadPolicy ? (val) => setState(() => _agreePolicy = val!) : null,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showFullPolicyDialog,
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                                children: [
                                  const TextSpan(text: "Tôi đã đọc và đồng ý với "),
                                  TextSpan(
                                    text: "chính sách đặt tour & bảo mật thông tin",
                                    style: const TextStyle(
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: " của công ty"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "Tổng giá tour: ${formatPrice(totalPrice)}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      onPressed: (_isLoading || !_agreePolicy)
                          ? null
                          : () async {
                        final confirm = await showPolicyDialog();
                        if (confirm == true) {
                          confirmBooking();
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("XÁC NHẬN ĐẶT TOUR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.teal)),
            ),
        ],
      ),
    );
  }
}