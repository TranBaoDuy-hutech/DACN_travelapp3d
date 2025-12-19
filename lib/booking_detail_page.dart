import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool _isCancelling = false;

  String _formatCurrency(num value) {
    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(value)} VNĐ";
  }

  String _formatDate(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return DateFormat("dd/MM/yyyy").format(date);
    } catch (_) {
      return rawDate;
    }
  }

  bool canCancel(String dateStr) {
    try {
      final tourDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      return tourDate.difference(now).inDays >= 7 &&
          widget.booking['status'] != "Cancelled";
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelBooking(BuildContext context, int bookingID) async {
    setState(() => _isCancelling = true);
    try {
      final response = await http.delete(
        Uri.parse("http://127.0.0.1:8000/booking/${widget.booking['bookingID']}"),
      );


      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Hủy tour thành công"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() => widget.booking['status'] = "Cancelled");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hủy tour thất bại: ${response.body}"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool allowCancel = canCancel(widget.booking['date']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi Tiết Đặt Tour"),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        label: "Tên Tour",
                        value: widget.booking['tourName'] ?? "Chưa rõ",
                        isTitle: true,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        label: "Ngày Khởi Hành",
                        value: _formatDate(widget.booking['date']),
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        label: "Số Khách",
                        value: "${widget.booking['numPeople'] ?? 0}",
                        icon: Icons.group,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        label: "Tổng Tiền",
                        value: _formatCurrency(widget.booking['totalPrice'] ?? 0),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.error,
                        ),
                        icon: Icons.monetization_on,
                      ),
                      if (widget.booking['specialRequests'] != null &&
                          widget.booking['specialRequests'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildInfoRow(
                            label: "Yêu Cầu Đặc Biệt",
                            value: widget.booking['specialRequests'],
                            icon: Icons.note_alt,
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        label: "Trạng Thái",
                        value: widget.booking['status'] ?? "Pending",
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.booking['status'] == "Cancelled"
                              ? Colors.grey
                              : Colors.green,
                        ),
                        icon: Icons.info_outline,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              allowCancel
                  ? ElevatedButton.icon(
                onPressed: _isCancelling
                    ? null
                    : () => cancelBooking(
                    context, widget.booking['bookingID']),
                icon: _isCancelling
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.cancel_outlined),
                label: Text(
                  _isCancelling ? "Đang Hủy..." : "Hủy Tour",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 50),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  "Không thể hủy tour do đã quá gần ngày khởi hành\n(Yêu cầu ≥ 7 ngày trước)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade700, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isTitle = false,
    TextStyle? valueStyle,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.teal.shade700),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  )),
              const SizedBox(height: 4),
              Text(value,
                  style: valueStyle ??
                      TextStyle(
                        fontSize: isTitle ? 20 : 16,
                        fontWeight: isTitle ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.black87,
                      )),
            ],
          ),
        ),
      ],
    );
  }
}
