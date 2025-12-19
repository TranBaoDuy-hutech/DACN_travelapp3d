import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_chat_page.dart';
import 'globals.dart' as globals;
import 'package:intl/intl.dart';
import 'booking_management_page.dart';
import 'guide_assignment_page.dart';
import 'tour_management_page.dart';
import 'customer_management_page.dart';
import 'user_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? errorMessage;
  int totalTours = 0;
  int totalCustomers = 0;
  int totalGuides = 0;
  double totalRevenue = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    fetchStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/admin/stats'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalTours = data['totalTours'] ?? 0;
          totalCustomers = data['totalCustomers'] ?? 0;
          totalGuides = data['totalGuides'] ?? 0;
          totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
          isLoading = false;
          errorMessage = null;
        });
        _animationController.forward(from: 0);
      } else {
        throw Exception("Failed to load statistics");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading data: $e";
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatCurrency.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Việt Lữ Travel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Admin Dashboard",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00838F),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00838F), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            tooltip: "Cập nhật số liệu",
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              fetchStats();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00838F),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Đang tải dữ liệu...",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF37474F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : errorMessage != null
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              ),
              const SizedBox(height: 16),
              Text(
                "Có lỗi xảy ra",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF78909C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: fetchStats,
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchStats,
        color: const Color(0xFF00838F),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00838F), Color(0xFF00ACC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00838F).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Chào mừng trở lại! 👋",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Quản lý hệ thống du lịch của bạn",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_graph,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Cards
              const Text(
                "Thống Kê Tổng Quan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      StatCard(
                        title: "Tours",
                        value: totalTours.toString(),
                        gradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                        icon: Icons.tour,
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2,
                        animation: _animationController,
                      ),
                      StatCard(
                        title: "Khách Hàng",
                        value: totalCustomers.toString(),
                        gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        icon: Icons.people,
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2,
                        animation: _animationController,
                      ),
                      StatCard(
                        title: "Hướng Dẫn Viên",
                        value: totalGuides.toString(),
                        gradient: const [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        icon: Icons.person_pin,
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2,
                        animation: _animationController,
                      ),
                      StatCard(
                        title: "Doanh Thu",
                        value: _formatCurrency(totalRevenue),
                        gradient: const [Color(0xFFFD79A8), Color(0xFFE17055)],
                        icon: Icons.payments,
                        width: constraints.maxWidth > 600
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2,
                        animation: _animationController,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Management Section
              const Text(
                "Quản Lý Hệ Thống",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ManagementButton(
                    title: "Quản Lý Tours",
                    icon: Icons.tour,
                    gradient: const [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TourManagementPage()),
                      );
                    },
                  ),
                  ManagementButton(
                    title: "Quản Lý Khách Hàng",
                    icon: Icons.people,
                    gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CustomerManagementPage()),
                      );
                    },
                  ),
                  ManagementButton(
                    title: "Quản Lý Nhân Viên",
                    icon: Icons.admin_panel_settings,
                    gradient: const [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserManagementPage()),
                      );
                    },
                  ),
                  ManagementButton(
                    title: "Quản Lý Đặt Chỗ",
                    icon: Icons.receipt_long,
                    gradient: const [Color(0xFFFD79A8), Color(0xFFE17055)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BookingManagementPage()),
                      );
                    },
                  ),
                  ManagementButton(
                    title: "Lịch HDV",
                    icon: Icons.assignment_ind,
                    gradient: const [Color(0xFFFDCB6E), Color(0xFFF6B93B)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GuideAssignmentPage()),
                      );
                    },
                  ),
                  ManagementButton(
                    title: "Tin Nhắn",
                    icon: Icons.chat_bubble,
                    gradient: const [Color(0xFF74B9FF), Color(0xFF0984E3)],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminChatPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> gradient;
  final IconData icon;
  final double width;
  final AnimationController animation;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradient,
    required this.icon,
    required this.width,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (animation.value * 0.2),
          child: Opacity(
            opacity: animation.value,
            child: Container(
              width: width,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ManagementButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const ManagementButton({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<ManagementButton> createState() => _ManagementButtonState();
}

class _ManagementButtonState extends State<ManagementButton> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(isPressed ? 0.95 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}