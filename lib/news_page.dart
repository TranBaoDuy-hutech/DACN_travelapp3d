import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:diacritic/diacritic.dart';
import 'package:shimmer/shimmer.dart';
import 'news_detail_page.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> with SingleTickerProviderStateMixin {
  List<dynamic> news = [];
  List<dynamic> filteredNews = [];
  bool loading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

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
    _searchController.addListener(() => filterNews(_searchController.text));
    fetchNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchNews({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final response = await http.get(Uri.parse("http://127.0.0.1:8000/news")).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          news = data["data"] ?? [];
          filteredNews = news;
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
      debugPrint("❌ Lỗi kết nối: $e");
    }
  }

  void filterNews(String query) {
    final q = removeDiacritics(query.toLowerCase().trim());
    setState(() {
      filteredNews = news.where((item) {
        final title = removeDiacritics((item["Title"] ?? "").toString().toLowerCase());
        final content = removeDiacritics((item["Content"] ?? "").toString().toLowerCase());
        return title.contains(q) || content.contains(q);
      }).toList();
    });
  }

  Widget buildNewsImage(String? img, double size) {
    if (img == null || img.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [oceanBlue.withOpacity(0.3), lightOcean.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.announcement_rounded,
          size: size * 0.5,
          color: oceanBlue,
        ),
      );
    }

    Widget imageWidget;
    if (img.startsWith("http")) {
      imageWidget = CachedNetworkImage(
        imageUrl: img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [oceanBlue.withOpacity(0.3), lightOcean.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.broken_image_rounded,
            size: size * 0.5,
            color: oceanBlue,
          ),
        ),
      );
    } else {
      String assetPath = img.startsWith("/assets/") ? img.replaceFirst("/assets/", "") : img;
      imageWidget = Image.asset(
        "assets/$assetPath",
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [oceanBlue.withOpacity(0.3), lightOcean.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.image_not_supported_rounded,
            size: size * 0.5,
            color: oceanBlue,
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: imageWidget,
        ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // Tính số cột cho grid
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
        onRefresh: () => fetchNews(isRefresh: true),
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
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [deepOcean, oceanBlue, lightOcean],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.1,
                          child: Image.asset(
                            'assets/nen.png',
                            repeat: ImageRepeat.repeat,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          padding: EdgeInsets.fromLTRB(
                            isWeb ? 40 : 24,
                            60,
                            isWeb ? 40 : 24,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.article_rounded,
                                      color: Colors.white,
                                      size: isWeb ? 40 : 32,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Tin Tức",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: isWeb ? 18 : 16,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Việt Lữ Travel",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isWeb ? 36 : 28,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
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

            // Nội dung chính
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      SizedBox(height: isWeb ? 32 : 20),

                      // Thanh tìm kiếm
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: oceanBlue.withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                            decoration: InputDecoration(
                              hintText: "Tìm kiếm tin tức...",
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 15,
                              ),
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: oceanBlue,
                                  size: 24,
                                ),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  filterNews('');
                                },
                              )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: oceanBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isWeb ? 32 : 24),

                      // Số lượng tin tức
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                        child: Row(
                          children: [
                            Text(
                              "${filteredNews.length} tin tức",
                              style: TextStyle(
                                fontSize: isWeb ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: oceanBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Cập nhật",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: oceanBlue,
                                ),
                              ),
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

            // Loading
            if (loading)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    childAspectRatio: isWeb ? 0.85 : 0.9,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildShimmerCard(isWeb),
                    childCount: 6,
                  ),
                ),
              ),

            // Error
            if (!loading && errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => fetchNews(isRefresh: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: oceanBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text("Thử lại"),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty
            if (!loading && errorMessage == null && filteredNews.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "Không tìm thấy tin tức",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Hãy thử tìm kiếm với từ khóa khác",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // News Grid/List
            if (!loading && errorMessage == null && filteredNews.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isWeb ? 40 : 20,
                  0,
                  isWeb ? 40 : 20,
                  isWeb ? 40 : 24,
                ),
                sliver: isWeb
                    ? _buildGridView(columns, maxWidth)
                    : _buildListView(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(int columns, double maxWidth) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.85,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return _buildNewsCard(filteredNews[index], index, isGrid: true);
        },
        childCount: filteredNews.length,
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return _buildNewsCard(filteredNews[index], index, isGrid: false);
        },
        childCount: filteredNews.length,
      ),
    );
  }

  Widget _buildNewsCard(dynamic item, int index, {required bool isGrid}) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index * 0.05).clamp(0.0, 0.7),
              ((index * 0.05) + 0.3).clamp(0.3, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: isGrid ? _buildGridCard(item, index) : _buildListCard(item, index),
    );
  }

  Widget _buildGridCard(dynamic item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: oceanBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsDetailPage(item: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hình ảnh
              Expanded(
                flex: 3,
                child: Hero(
                  tag: 'news_${item["NewsID"]}_$index',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: buildNewsImage(item["ImageUrl"], double.infinity),
                  ),
                ),
              ),

              // Thông tin
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      Text(
                        item["Title"] ?? "Không có tiêu đề",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Ngày đăng
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item["CreatedAt"] ?? "Chưa có ngày",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Button
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Đọc thêm",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: oceanBlue,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: oceanBlue,
                            size: 20,
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
    );
  }

  Widget _buildListCard(dynamic item, int index) {
    final screenW = MediaQuery.of(context).size.width;
    final imgSize = screenW * 0.30;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewsDetailPage(item: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: oceanBlue.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'news_${item["NewsID"]}_$index',
                  child: buildNewsImage(item["ImageUrl"], imgSize),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["Title"] ?? "Không có tiêu đề",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item["Content"] ?? "Chưa có nội dung",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item["CreatedAt"] ?? "Chưa có ngày",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [oceanBlue, lightOcean],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: oceanBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Xem",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
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
    );
  }

  Widget _buildShimmerCard(bool isWeb) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}