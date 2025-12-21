import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:diacritic/diacritic.dart';
import 'dacsan.dart'; // Giả sử đây là model DacSan
import 'dac_san_detail_page.dart';

class DacSanPage extends StatefulWidget {
  const DacSanPage({super.key});

  @override
  State<DacSanPage> createState() => _DacSanPageState();
}

class _DacSanPageState extends State<DacSanPage> {
  late Future<List<DacSan>> _futureDacSan;
  List<DacSan> _allDacSan = [];
  List<DacSan> _filteredDacSan = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _futureDacSan = fetchDacSan();
    _searchController.addListener(_onSearchChangedDebounced);
  }

  void _onSearchChangedDebounced() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = removeDiacritics(_searchController.text.toLowerCase().trim());
      setState(() {
        _filteredDacSan = _allDacSan.where((item) {
          final name = removeDiacritics(item.tenMon.toLowerCase());
          return name.contains(query);
        }).toList();
      });
    });
  }

  Future<List<DacSan>> fetchDacSan() async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/dacsanw'); // Nên dùng https khi deploy
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        List<DacSan> dacSanList;

        if (jsonData is Map && jsonData.containsKey('data')) {
          dacSanList = (jsonData['data'] as List)
              .map((e) => DacSan.fromJson(e))
              .toList();
        } else if (jsonData is List) {
          dacSanList = jsonData.map((e) => DacSan.fromJson(e)).toList();
        } else {
          throw Exception('Dữ liệu API không đúng định dạng');
        }

        setState(() {
          _allDacSan = dacSanList;
          _filteredDacSan = dacSanList;
        });
        return dacSanList;
      } else {
        throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể kết nối: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget buildDacSanCard(DacSan item, bool isDesktop, bool isTablet) {
    return Hero(
      tag: 'model-${item.id ?? item.tenMon}',
      child: StatefulBuilder(
        builder: (context, setCardState) {
          bool isHovered = false;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setCardState(() => isHovered = true),
            onExit: (_) => setCardState(() => isHovered = false),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DacSanDetailPage(item: item),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade900, Colors.black87],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.greenAccent.shade700.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHovered
                          ? Colors.greenAccent.withOpacity(0.5)
                          : Colors.greenAccent.withOpacity(0.25),
                      blurRadius: isHovered ? 35 : 20,
                      spreadRadius: isHovered ? 5 : 0,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần 3D model
                    Expanded(
                      flex: 5,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                backgroundColor: Colors.black,
                                appBar: AppBar(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  iconTheme: const IconThemeData(color: Colors.white),
                                  title: Text(
                                    item.tenMon,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  centerTitle: true,
                                ),
                                body: Hero(
                                  tag: 'model-${item.id ?? item.tenMon}',
                                  child: ModelViewer(
                                    src: item.modelUrl,
                                    alt: "3D model ${item.tenMon}",
                                    autoRotate: true,
                                    cameraControls: true,
                                    ar: true, // Bật AR nếu thiết bị hỗ trợ
                                    backgroundColor: Colors.transparent,
                                    minCameraOrbit: "auto auto 1m",
                                    maxCameraOrbit: "auto auto 15m",
                                    arModes: const ['webxr', 'quick-look', 'scene-viewer'],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              child: ModelViewer(
                                src: item.modelUrl,
                                alt: "3D model ${item.tenMon}",
                                autoRotate: true,
                                cameraControls: true,
                                backgroundColor: Colors.transparent,
                                minCameraOrbit: "auto auto 1m",
                                maxCameraOrbit: "auto auto 10m",
                                loading: Loading.eager,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.greenAccent.shade400, Colors.green.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      '3D / AR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Thông tin
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 20 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.greenAccent.shade400, Colors.green.shade700],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.tenMon,
                                    style: TextStyle(
                                      fontSize: isDesktop ? 24 : 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.greenAccent.shade400,
                                  size: isDesktop ? 22 : 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.greenAccent.shade700.withOpacity(0.6), Colors.transparent],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                item.moTa,
                                maxLines: isDesktop ? 5 : (isTablet ? 4 : 3),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isDesktop ? 15 : 14,
                                  color: Colors.grey.shade300,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 1200;
        final isTablet = width > 768 && width <= 1200;
        final isMobile = width <= 768;

        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
        final paddingHorizontal = isDesktop ? 80.0 : (isTablet ? 32.0 : 16.0);

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant, color: Colors.greenAccent.shade400, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Đặc Sản An Giang',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.5,
                    color: Colors.tealAccent,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.black.withOpacity(0.4),
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade900.withOpacity(0.8), Colors.black.withOpacity(0.5)],
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
              child: Column(
                children: [
                  // Thanh tìm kiếm
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingHorizontal,
                      vertical: 16,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm đặc sản...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.greenAccent.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade900.withOpacity(0.6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // Danh sách
                  Expanded(
                    child: FutureBuilder<List<DacSan>>(
                      future: _futureDacSan,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                  strokeWidth: 4,
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Đang tải đặc sản...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade300, size: 60),
                                const SizedBox(height: 16),
                                Text(
                                  'Lỗi: ${snapshot.error}',
                                  style: TextStyle(color: Colors.red.shade300, fontSize: 18),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () => setState(() => _futureDacSan = fetchDacSan()),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Thử lại'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent.shade700,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (_filteredDacSan.isEmpty) {
                          return Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Chưa có dữ liệu đặc sản'
                                  : 'Không tìm thấy kết quả phù hợp',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: paddingHorizontal,
                            vertical: 16,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: isDesktop ? 0.82 : (isTablet ? 0.78 : 0.72),
                            crossAxisSpacing: 28,
                            mainAxisSpacing: 32,
                          ),
                          itemCount: _filteredDacSan.length,
                          itemBuilder: (context, index) {
                            final item = _filteredDacSan[index];
                            return buildDacSanCard(item, isDesktop, isTablet);
                          },
                        );
                      },
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
}