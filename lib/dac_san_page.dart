import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:diacritic/diacritic.dart';
import 'dacsan.dart';
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

  @override
  void initState() {
    super.initState();
    _futureDacSan = fetchDacSan();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = removeDiacritics(_searchController.text.toLowerCase());
    setState(() {
      _filteredDacSan = _allDacSan.where((item) {
        final name = removeDiacritics(item.tenMon.toLowerCase());
        return name.contains(query);
      }).toList();
    });
  }

  Future<List<DacSan>> fetchDacSan() async {
    final url = Uri.parse('http://10.0.2.2:8000/dacsan');
    final response = await http.get(url);

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
      _allDacSan = dacSanList;
      _filteredDacSan = dacSanList;
      return dacSanList;
    } else {
      throw Exception('Không thể tải dữ liệu (mã lỗi: ${response.statusCode})');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant, color: Colors.greenAccent.shade400, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Đặc Sản An Giang',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
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
            colors: [
              Colors.black,
              Colors.green.shade900,
              Colors.black,
            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm đặc sản...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, color: Colors.greenAccent.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade900.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Danh sách đặc sản
              Expanded(
                child: FutureBuilder<List<DacSan>>(
                  future: _futureDacSan,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.greenAccent.shade400,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Đang tải đặc sản...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '❌ Lỗi: ${snapshot.error}',
                          style: TextStyle(color: Colors.red.shade300),
                        ),
                      );
                    }

                    if (_filteredDacSan.isEmpty) {
                      return Center(
                        child: Text(
                          'Không tìm thấy kết quả',
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDacSan.length,
                      itemBuilder: (context, index) {
                        final item = _filteredDacSan[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DacSanDetailPage(item: item),
                              ),
                            );
                          },
                          child: buildDacSanCard(item),
                        );
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
  }

  Widget buildDacSanCard(DacSan item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 24),
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
            color: Colors.greenAccent.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade900.withOpacity(0.3), Colors.black.withOpacity(0.5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: ModelViewer(
                    src: item.modelUrl,
                    alt: "3D model ${item.tenMon}",
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: Colors.transparent,
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
                          color: Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '3D',
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
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
                      child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.tenMon,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.greenAccent.shade400, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.greenAccent.shade700.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.moTa,
                  style: TextStyle(
                    fontSize: 15,
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
    );
  }
}
