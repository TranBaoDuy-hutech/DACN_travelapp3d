import 'dart:async';
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
  List<dynamic> _filteredVanHoa = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchVanHoa();
    _searchController.addListener(_onSearchChangedDebounced);
  }

  void _onSearchChangedDebounced() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        _filteredVanHoa = vanHoaList.where((item) {
          final title = (item['tieuDe'] ?? '').toLowerCase();
          return title.contains(query);
        }).toList();
      });
    });
  }

  Future<void> fetchVanHoa() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await http
          .get(Uri.parse("http://127.0.0.1:8000/vanhoaw"))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        setState(() {
          vanHoaList = jsonData["data"] ?? [];
          _filteredVanHoa = vanHoaList;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi tải dữ liệu (mã: ${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Không thể kết nối: $e';
      });
    }
  }

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
                  // Hình ảnh
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        item['hinhAnh'] ?? 'https://via.placeholder.com/400x300/111/eee?text=Loading',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.greenAccent,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[850],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
                          ),
                        ),
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
                                child: const Icon(
                                  Icons.account_balance,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item['tieuDe'] ?? 'Không có tiêu đề',
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
                              item['moTa'] ?? 'Không có mô tả',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 1200;
        final isTablet = width > 768 && width <= 1200;
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
        final paddingHorizontal = isDesktop ? 80.0 : (isTablet ? 32.0 : 16.0);

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance, color: Colors.greenAccent.shade400, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Văn Hóa An Giang',
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
                  // Thanh tìm kiếm (giống DacSan)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingHorizontal,
                      vertical: 16,
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm văn hóa...',
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

                  // Nội dung chính
                  Expanded(
                    child: isLoading
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.greenAccent,
                            strokeWidth: 4,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Đang tải văn hóa...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                        : errorMessage != null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade300, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red.shade300, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: fetchVanHoa,
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
                    )
                        : _filteredVanHoa.isEmpty
                        ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Chưa có dữ liệu văn hóa'
                            : 'Không tìm thấy kết quả phù hợp',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                      ),
                    )
                        : GridView.builder(
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
                      itemCount: _filteredVanHoa.length,
                      itemBuilder: (context, index) {
                        final item = _filteredVanHoa[index];
                        return buildVanHoaCard(item, isDesktop, isTablet);
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}