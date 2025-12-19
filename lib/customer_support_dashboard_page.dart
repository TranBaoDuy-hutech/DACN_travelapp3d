import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_chat_page.dart';
import 'customer_management_page.dart';
import 'guide_assignment_page.dart';

class CustomerSupportDashboardPage extends StatefulWidget {
  const CustomerSupportDashboardPage({super.key});

  @override
  State<CustomerSupportDashboardPage> createState() =>
      _CustomerSupportDashboardPageState();
}

class _CustomerSupportDashboardPageState
    extends State<CustomerSupportDashboardPage> {
  bool isLoading = true;

  int totalCustomers = 0;
  int supportRequests = 0;
  int pendingRequests = 0;
  int unreadMessages = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchUnreadMessages();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchStats() async {
    try {
      final statsResponse =
      await http.get(Uri.parse("http://127.0.0.1:8000/admin/stats"));

      final unreadResponse =
      await http.get(Uri.parse("http://127.0.0.1:8000/chat/unread-count"));

      if (statsResponse.statusCode == 200 && unreadResponse.statusCode == 200) {
        final statsData = json.decode(statsResponse.body);
        final unreadData = json.decode(unreadResponse.body);

        setState(() {
          totalCustomers = statsData['totalCustomers'] ?? 0;
          supportRequests = statsData['supportRequests'] ?? 0;
          pendingRequests = statsData['pendingRequests'] ?? 0;
          unreadMessages = unreadData['unread_count'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUnreadMessages() async {
    try {
      final response =
      await http.get(Uri.parse("http://127.0.0.1:8000/chat/unread-count"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newCount = data['unread_count'] ?? 0;

        if (newCount != unreadMessages) {
          setState(() {
            unreadMessages = newCount;
          });
        }
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        title: const Text(
          "CSKH - Việt Lữ Travel",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6C63FF),
                    Color(0xFF8E82FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent, size: 40, color: Colors.white),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Xin chào CSKH 👋",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Chúc bạn 1 ngày làm việc hiệu quả!",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Thống kê hôm nay",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2660),
              ),
            ),
            const SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                        width: cardWidth,
                        child: _statCard("Khách hàng", totalCustomers,
                            Icons.people, Colors.purpleAccent)),
                    SizedBox(
                        width: cardWidth,
                        child: _statCard("Yêu cầu hỗ trợ", supportRequests,
                            Icons.help_center, Colors.blueAccent)),
                    SizedBox(
                        width: cardWidth,
                        child: _statCard("Chưa xử lý", pendingRequests,
                            Icons.pending_actions, Colors.deepOrange)),
                    SizedBox(
                        width: cardWidth,
                        child: _statCard("Tin nhắn mới", unreadMessages,
                            Icons.mark_chat_unread, Colors.green)),
                  ],
                );
              },
            ),
            const SizedBox(height: 35),
            const Text(
              "Chức năng chính",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2660),
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              crossAxisCount:
              MediaQuery.of(context).size.width > 600 ? 3 : 2,
              shrinkWrap: true,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _featureButton(
                  "Chat với khách hàng",
                  Icons.chat,
                  Colors.blue,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminChatPage()),
                    );
                  },
                ),
                _featureButton(
                  "Quản lý khách hàng",
                  Icons.people_alt,
                  Colors.purple,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CustomerManagementPage()),
                    );
                  },
                ),
                _featureButton(
                  "Xem lịch HDV",
                  Icons.calendar_today,
                  Colors.orange,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GuideAssignmentPage()),
                    );
                  },
                ),
                _featureButton(
                  "Báo cáo sự cố",
                  Icons.report_problem,
                  Colors.redAccent,
                      () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2660),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
