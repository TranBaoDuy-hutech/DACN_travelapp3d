import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;
import 'customer.dart';
import 'login_page.dart';
import 'my_bookings_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with TickerProviderStateMixin {
  File? _avatarFile;
  late AnimationController _floatingController;
  late AnimationController _fadeController;
  bool _isRefreshingBookings = false;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _refreshBookingsCount();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Hàm lấy dữ liệu bookings từ server và cập nhật globals + UI
  Future<void> _refreshBookingsCount() async {
    final customer = globals.currentCustomer;
    if (customer == null || !mounted) return;

    setState(() {
      _isRefreshingBookings = true;
    });

    try {
      final response = await http.get(
        Uri.parse("http://127.0.0.1:8000/bookings/${customer.customerID}"),
      );

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List<dynamic> fetchedBookings = data is List ? data : [data];

        setState(() {
          globals.myBookings = fetchedBookings;
          _isRefreshingBookings = false;
        });
      } else if (mounted) {
        setState(() {
          _isRefreshingBookings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshingBookings = false;
        });
      }
      debugPrint("Lỗi khi cập nhật số lượng tour: $e");
    }
  }

  Future<void> _pickAvatar() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  void _logout() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => _buildLogoutDialog(),
    );
  }

  void _performLogout() {
    setState(() {
      globals.currentCustomer = null;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _goToLogin() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Chuyển sang MyBookings và tự động refresh khi quay lại
  void _goToMyBookings() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyBookingsPage()),
    ).then((_) {
      if (mounted) {
        _refreshBookingsCount(); // Cập nhật lại nếu có thay đổi trong MyBookings
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Customer? customer = globals.currentCustomer;
    if (customer == null) {
      return _buildLoginPrompt();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(customer),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildStatsCards(),
                      const SizedBox(height: 24),
                      _buildInfoSection(customer),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          "© 2025 Trần Bảo Duy. All rights reserved.",
                          style: TextStyle(
                            color: Colors.blue.shade900.withOpacity(0.7),
                            fontSize: 15,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Loading nhỏ khi đang refresh bookings (không làm gián đoạn UI)
          if (_isRefreshingBookings)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Đang cập nhật...",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (_floatingController.value * 50),
              right: -80,
              child: _buildFloatingCircle(250, Colors.blue.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -150 + (_floatingController.value * -30),
              left: -100,
              child: _buildFloatingCircle(300, Colors.purple.withOpacity(0.04)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_outline_rounded, size: 64, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Chào mừng bạn!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Đăng nhập để trải nghiệm đầy đủ tính năng",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildPremiumButton(
                    onPressed: _goToLogin,
                    icon: Icons.login_rounded,
                    label: "Đăng nhập ngay",
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Customer customer) {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/nen2.png",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xAA00B4DB),
                    Color(0xCC0083B0),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildAvatar(),
                  const SizedBox(height: 16),
                  Text(
                    customer.userName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          customer.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey[100],
              backgroundImage: _avatarFile != null
                  ? FileImage(_avatarFile!)
                  : const AssetImage("assets/BDUY.jpg") as ImageProvider,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    int daDat = globals.myBookings.length;
    int yeuThich = 8;
    int diem = 450;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(Icons.bookmark_rounded, "Đã đặt", "$daDat", Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.favorite_rounded, "Yêu thích", "$yeuThich", Colors.red)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(Icons.star_rounded, "Điểm", "$diem", Colors.amber)),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Customer customer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Thông tin cá nhân",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildInfoRow(Icons.phone_rounded, "Số điện thoại", customer.phone ?? "Chưa cập nhật", Colors.green),
            _buildDivider(),
            _buildInfoRow(Icons.home_rounded, "Địa chỉ", customer.address ?? "Chưa cập nhật", Colors.orange),
            _buildDivider(),
            _buildInfoRow(Icons.cake_rounded, "Ngày sinh", customer.dateOfBirth ?? "Chưa cập nhật", Colors.pink),
            _buildDivider(),
            _buildInfoRow(Icons.wc_rounded, "Giới tính", customer.gender ?? "Chưa cập nhật", Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.grey[200], height: 1),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildPremiumButton(
            onPressed: _goToMyBookings,
            icon: Icons.history_rounded,
            label: "Lịch sử đặt tour",
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildPremiumButton(
            onPressed: _logout,
            icon: Icons.logout_rounded,
            label: "Đăng xuất",
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFE53935)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              "Đăng xuất",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Bạn có chắc chắn muốn đăng xuất?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Hủy",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Đăng xuất",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}