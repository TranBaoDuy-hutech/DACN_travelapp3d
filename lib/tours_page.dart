import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:diacritic/diacritic.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:travelapp/recommend_page.dart';
import 'tour_detail_page.dart';

class ToursPage extends StatefulWidget {
  const ToursPage({super.key});

  @override
  State<ToursPage> createState() => _ToursPageState();
}

class _ToursPageState extends State<ToursPage> with SingleTickerProviderStateMixin {
  List<dynamic> tours = [];
  List<dynamic> filteredTours = [];
  bool loading = true;
  String? errorMessage;
  final NumberFormat currencyFormatter = NumberFormat("#,##0", "vi_VN");
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  Timer? _debounce;

  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color deepOcean = const Color(0xFF005A8C);
  final Color accentOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        filterTours(_searchController.text);
      });
    });
    fetchTours();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchTours({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await http.get(Uri.parse("http://127.0.0.1:8000/tours")).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          tours = data["data"] ?? [];
          filteredTours = tours;
          loading = false;
          errorMessage = null;
          _animationController.forward(from: 0);
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = "Lỗi tải dữ liệu: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Lỗi kết nối: $e";
      });
    }
  }

  void filterTours(String query) {
    final q = removeDiacritics(query.toLowerCase().trim());
    setState(() {
      filteredTours = tours.where((tour) {
        final name = removeDiacritics((tour["TourName"] ?? "").toString().toLowerCase());
        final location = removeDiacritics((tour["Location"] ?? "").toString().toLowerCase());
        return name.contains(q) || location.contains(q);
      }).toList();
    });
  }

  Widget buildTourImage(String? imgUrl, double height) {
    if (imgUrl == null || imgUrl.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [oceanBlue.withOpacity(0.3), lightOcean.withOpacity(0.3)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.landscape_rounded, size: height * 0.4, color: oceanBlue),
      );
    }

    return CachedNetworkImage(
      imageUrl: imgUrl,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: height, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20))),
      ),
      errorWidget: (context, url, error) => Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [oceanBlue.withOpacity(0.3), lightOcean.withOpacity(0.3)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.broken_image_rounded, size: height * 0.4, color: oceanBlue),
      ),
    );
  }

  int _calculateColumns(double width) {
    if (width > 1400) return 4;
    if (width > 1100) return 3;
    if (width > 800) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWeb = screenW > 600;
    final columns = _calculateColumns(screenW);
    final maxWidth = screenW > 1600 ? 1400.0 : screenW * 0.9;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        color: oceanBlue,
        onRefresh: () => fetchTours(isRefresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              expandedHeight: isWeb ? 200 : 180,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: oceanBlue,
              automaticallyImplyLeading: false,
              actions: [
                if (isWeb) const Spacer(),
                Padding(
                  padding: EdgeInsets.only(right: isWeb ? 32 : 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendPage()));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accentOrange, accentOrange.withOpacity(0.9)]),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: accentOrange.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 8),
                            Text("Gợi ý Tour", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [deepOcean, oceanBlue, lightOcean], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(opacity: 0.1, child: Image.asset('assets/nen.png', repeat: ImageRepeat.repeat, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
                      ),
                      Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          padding: EdgeInsets.fromLTRB(isWeb ? 40 : 24, 60, isWeb ? 40 : 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                    child: Icon(Icons.explore_rounded, color: Colors.white, size: isWeb ? 40 : 32),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Khám Phá", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: isWeb ? 18 : 16)),
                                        const SizedBox(height: 6),
                                        Text("Việt Lữ Travel", style: TextStyle(color: Colors.white, fontSize: isWeb ? 36 : 28, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Thanh tìm kiếm + số lượng
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      SizedBox(height: isWeb ? 32 : 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: oceanBlue.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            decoration: InputDecoration(
                              hintText: "Tìm kiếm tour...",
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                              prefixIcon: Padding(padding: const EdgeInsets.all(12), child: Icon(Icons.search_rounded, color: oceanBlue, size: 24)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  filterTours('');
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isWeb ? 32 : 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                        child: Row(
                          children: [
                            Text("${filteredTours.length} tours", style: TextStyle(fontSize: isWeb ? 20 : 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: oceanBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text("Khả dụng", style: TextStyle(fontSize: 13, color: oceanBlue, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isWeb ? 24 : 16),
                    ],
                  ),
                ),
              ),
            ),

            // Loading shimmer
            if (loading)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: 0.75, // Tăng chiều cao card để tránh overflow
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) => _buildShimmerCard(isWeb), childCount: 6),
                ),
              ),

            // Error state
            if (!loading && errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(errorMessage!, style: TextStyle(color: Colors.grey[600], fontSize: 16), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => fetchTours(isRefresh: true),
                        style: ElevatedButton.styleFrom(backgroundColor: oceanBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                        child: const Text("Thử lại"),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty state
            if (!loading && errorMessage == null && filteredTours.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("Không tìm thấy tour", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text("Hãy thử tìm kiếm với từ khóa khác", style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),

            // Grid/List
            if (!loading && errorMessage == null && filteredTours.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(isWeb ? 40 : 20, 0, isWeb ? 40 : 20, isWeb ? 40 : 24),
                sliver: isWeb ? _buildGridView(columns) : _buildListView(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(int columns) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.75, // Fix overflow: tăng chiều cao card
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTourCard(filteredTours[index], index, isGrid: true),
        childCount: filteredTours.length,
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTourCard(filteredTours[index], index, isGrid: false),
        childCount: filteredTours.length,
      ),
    );
  }

  Widget _buildTourCard(dynamic tour, int index, {required bool isGrid}) {
    final tourName = tour["TourName"]?.toString().trim() ?? "Tour không tên";
    final location = tour["Location"]?.toString().trim() ?? "Chưa rõ địa điểm";
    final priceRaw = tour["Price"]?.toString().trim();
    final price = double.tryParse(priceRaw ?? "0") ?? 0;
    final priceStr = price > 0 ? "${currencyFormatter.format(price)} ₫" : "Liên hệ";

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval((index * 0.05).clamp(0.0, 0.7), ((index * 0.05) + 0.3).clamp(0.3, 1.0), curve: Curves.easeOutCubic),
          ),
        );
        return Opacity(opacity: animation.value, child: Transform.translate(offset: Offset(0, 30 * (1 - animation.value)), child: child));
      },
      child: isGrid ? _buildGridCard(tour, index, tourName, location, priceStr) : _buildListCard(tour, index, tourName, location, priceStr),
    );
  }

  Widget _buildGridCard(dynamic tour, int index, String tourName, String location, String priceStr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: oceanBlue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => TourDetailPage(tour: tour)));
          },
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: 'tour_${tour["TourID"] ?? index}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: buildTourImage(tour["ImageUrl"], double.infinity),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), // Giảm bottom padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tourName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 16, color: accentOrange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Chỉ từ", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      priceStr,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: oceanBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded, color: oceanBlue, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(dynamic tour, int index, String tourName, String location, String priceStr) {
    final imgSize = MediaQuery.of(context).size.width * 0.30;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => TourDetailPage(tour: tour)));
          },
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.hardEdge,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[200]!, width: 1),
                boxShadow: [BoxShadow(color: oceanBlue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: 'tour_${tour["TourID"] ?? index}',
                    child: buildTourImage(tour["ImageUrl"], imgSize),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tourName,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 16, color: accentOrange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Chỉ từ", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      priceStr,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: oceanBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [oceanBlue, lightOcean]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: oceanBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("Xem", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isWeb) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}