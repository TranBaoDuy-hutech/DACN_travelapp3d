import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tour_detail_page.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({Key? key}) : super(key: key);

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final _customerController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _ageController = TextEditingController();

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> recommended = [];
  List<Map<String, dynamic>> booked = [];

  final String apiUrl = "http://127.0.0.1:8000/recommend-tour";

  // Màu sắc
  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color deepOcean = const Color(0xFF005A8C);
  final Color accentOrange = const Color(0xFFFF6B35);
  final Color backgroundLight = const Color(0xFFF5F9FF);
  final Color cardShadow = const Color(0x220077BE);

  Future<void> fetchRecommendations({bool isRefresh = false}) async {
    // (giữ nguyên code fetch như phiên bản trước)
    final customerId = _customerController.text.trim();
    final preferences = _preferencesController.text.trim();
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText) ?? 0;

    if (customerId.isEmpty) {
      setState(() => _error = "Vui lòng nhập CustomerID");
      return;
    }

    if (!isRefresh) setState(() { _loading = true; _error = null; });

    try {
      final body = jsonEncode({
        "customer_id": customerId,
        "preferences": preferences.isEmpty ? null : preferences,
        "age": age > 0 ? age : null,
      });

      final resp = await http.post(Uri.parse(apiUrl), headers: {"Content-Type": "application/json"}, body: body).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        setState(() => _error = "Lỗi server: ${resp.statusCode}");
      } else {
        final data = jsonDecode(resp.body);
        if (data is Map<String, dynamic>) {
          final recData = data["recommendations"] as Map<String, dynamic>?;
          recommended = (recData?["recommended_tours"] as List?)?.cast<Map<String, dynamic>>() ?? [];
          booked = (recData?["booked_tours"] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (data.containsKey("error")) setState(() => _error = data["error"].toString());
        } else {
          setState(() => _error = "Phản hồi không hợp lệ");
        }
      }
    } catch (ex) {
      setState(() => _error = "Lỗi kết nối: $ex");
    } finally {
      if (!isRefresh) setState(() => _loading = false);
    }
  }

  Widget _buildTourCard(Map<String, dynamic> t, {required bool isRecommended}) {
    final title = t["TourName"]?.toString() ?? "Không tên";
    final location = t["Location"]?.toString() ?? "Chưa có địa điểm";
    final price = t["Price"] != null ? "${t["Price"]} VNĐ" : "Liên hệ";
    final duration = t["DurationDays"] != null ? "${t["DurationDays"]} ngày" : "Chưa rõ";
    final itinerary = t["Itinerary"]?.toString() ?? "Chưa có lịch trình chi tiết";
    final imagePath = t["ImageUrl"]?.toString() ?? "";
    final isHot = t["IsHot"] == true;

    Widget imageWidget = _placeholderImage();
    if (imagePath.isNotEmpty) {
      final assetPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
      imageWidget = Image.asset(assetPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderImage());
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..translate(0, -4, 0),
        child: Card(
          elevation: 12,
          shadowColor: cardShadow.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TourDetailPage(tour: t))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: AspectRatio(aspectRatio: 16/9, child: imageWidget)),
                    if (isRecommended) Positioned(top: 12, left: 12, child: _buildBadge("GỢI Ý HÔM NAY", accentOrange, Icons.auto_awesome)),
                    if (isHot) Positioned(top: 12, right: 12, child: _buildBadge("HOT", Colors.red, Icons.whatshot)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepOcean)),
                      const SizedBox(height: 8),
                      Row(children: [Icon(Icons.location_on_outlined, size: 18, color: lightOcean), const SizedBox(width: 6), Expanded(child: Text(location, style: const TextStyle(fontSize: 14)))]),
                      const SizedBox(height: 12),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(duration, style: TextStyle(color: Colors.grey[700])),
                        Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentOrange)),
                      ]),
                      const SizedBox(height: 12),
                      Text(itinerary, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
    );
  }

  Widget _placeholderImage() {
    return Container(
      decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), gradient: LinearGradient(colors: [lightOcean.withOpacity(0.6), oceanBlue.withOpacity(0.4)])),
      child: const Icon(Icons.landscape, size: 80, color: Colors.white70),
    );
  }

  Widget _buildGridSection(String title, List<Map<String, dynamic>> tours, bool isRecommended) {
    if (tours.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deepOcean))),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            if (constraints.maxWidth > 1200) crossAxisCount = 4;
            else if (constraints.maxWidth > 900) crossAxisCount = 3;
            else if (constraints.maxWidth > 600) crossAxisCount = 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.78,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
              ),
              itemCount: tours.length,
              itemBuilder: (_, i) => _buildTourCard(tours[i], isRecommended: isRecommended),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(title: const Text("Gợi ý tour du lịch cá nhân hóa"), backgroundColor: oceanBlue, foregroundColor: Colors.white, centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => fetchRecommendations(isRefresh: true),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              // Form tìm kiếm – rộng hơn trên web
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildInputCard()),
              ),
              if (_error != null)
                Padding(padding: const EdgeInsets.all(24), child: Card(color: Colors.red[50], child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(Icons.error_outline, color: Colors.red[700]), const SizedBox(width: 12), Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700])))])))),
              const SizedBox(height: 32),
              _buildGridSection("Tour đã đặt của bạn", booked, false),
              const SizedBox(height: 32),
              _buildGridSection("Tour gợi ý dành riêng cho bạn", recommended, true),
              if (!_loading && recommended.isEmpty && booked.isEmpty && _error == null)
                const Padding(padding: EdgeInsets.all(64), child: Text("Nhập thông tin và tìm gợi ý để bắt đầu!", style: TextStyle(fontSize: 18, color: Colors.grey))),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 8,
      shadowColor: cardShadow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF5F9FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.travel_explore, color: oceanBlue, size: 30),
                const SizedBox(width: 12),
                const Text("Tìm tour phù hợp với bạn", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _customerController,
              decoration: InputDecoration(
                labelText: "Mã khách hàng (CustomerID)",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _preferencesController,
              decoration: InputDecoration(
                labelText: "Sở thích (tùy chọn)",
                hintText: "Ví dụ: biển, núi, văn hóa...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.favorite_border),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Tuổi (tùy chọn)",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : () => fetchRecommendations(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightOcean,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Tìm gợi ý ngay", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customerController.dispose();
    _preferencesController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}