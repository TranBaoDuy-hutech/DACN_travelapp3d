import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'vanhoa_detail_page.dart';

class VanHoaPage extends StatefulWidget {
  const VanHoaPage({super.key});

  @override
  State<VanHoaPage> createState() => _VanHoaPageState();
}

class _VanHoaPageState extends State<VanHoaPage> {
  List<dynamic> vanHoaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVanHoa();
  }

  Future<void> fetchVanHoa() async {
    try {
      final res = await http.get(Uri.parse("http://127.0.0.1:8000/vanhoaw"));
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        setState(() {
          vanHoaList = jsonData["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
      setState(() => isLoading = false);
    }
  }

  // Widget card riêng để tái sử dụng
  Widget buildVanHoaCard(dynamic item, bool isDesktop, bool isTablet) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setCardState) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setCardState(() => isHovered = true),
          onExit: (_) => setCardState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VanHoaDetailPage(vanHoaId: item['id']),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade900, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.greenAccent.shade700.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? Colors.greenAccent.withOpacity(0.4)
                        : Colors.greenAccent.withOpacity(0.2),
                    blurRadius: isHovered ? 30 : 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      item['hinhAnh'],
                      width: double.infinity,
                      height: isDesktop ? 280 : (isTablet ? 240 : 220),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: isDesktop ? 280 : (isTablet ? 240 : 220),
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.greenAccent.shade400,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: isDesktop ? 280 : (isTablet ? 240 : 220),
                        color: Colors.grey[800],
                        child: const Icon(Icons.image_not_supported, size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isDesktop ? 24 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isDesktop ? 12 : 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.greenAccent.shade400, Colors.green.shade700],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.account_balance,
                                color: Colors.white,
                                size: isDesktop ? 26 : 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['tieuDe'],
                                style: TextStyle(
                                  fontSize: isDesktop ? 24 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.greenAccent.shade400,
                              size: isDesktop ? 22 : 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.greenAccent.shade700.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['moTa'],
                          maxLines: isDesktop ? 4 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isDesktop ? 16 : 15,
                            color: Colors.grey.shade300,
                            height: 1.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;      // 3 cột
    final isTablet = size.width > 600 && size.width <= 1200; // 2 cột
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, color: Colors.greenAccent.shade400, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Văn Hóa An Giang',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.tealAccent),
            ),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade900.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.green.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.greenAccent.shade400,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đang tải văn hóa...',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
              : vanHoaList.isEmpty
              ? Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade800.withOpacity(0.8), Colors.black.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade700, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade400, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có dữ liệu văn hóa',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
              : GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? size.width * 0.1 : (isTablet ? 24 : 16),
              vertical: 24,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: isDesktop ? 0.85 : (isTablet ? 0.8 : 0.75),
              crossAxisSpacing: 24,
              mainAxisSpacing: 32,
            ),
            itemCount: vanHoaList.length,
            itemBuilder: (context, index) {
              final item = vanHoaList[index];
              return buildVanHoaCard(item, isDesktop, isTablet);
            },
          ),
        ),
      ),
    );
  }
}