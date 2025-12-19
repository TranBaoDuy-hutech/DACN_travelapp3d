import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VanHoaDetailPage extends StatefulWidget {
  final int vanHoaId;
  const VanHoaDetailPage({super.key, required this.vanHoaId});

  @override
  State<VanHoaDetailPage> createState() => _VanHoaDetailPageState();
}

class _VanHoaDetailPageState extends State<VanHoaDetailPage> {
  Map<String, dynamic>? vanHoa;
  YoutubePlayerController? _youtubeController;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVanHoaDetail();
  }

  Future<void> fetchVanHoaDetail() async {
    try {
      final res = await http.get(Uri.parse("http://127.0.0.1:8000/vanhoaw/${widget.vanHoaId}"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final String? videoUrl = data['videoUrl'];
        setState(() {
          vanHoa = data;
          isLoading = false;
        });
        if (videoUrl != null && videoUrl.isNotEmpty) {
          final String? videoId = YoutubePlayerController.convertUrlToId(videoUrl);
          if (videoId != null) {
            _youtubeController = YoutubePlayerController.fromVideoId(
              videoId: videoId,
              autoPlay: false,
              params: const YoutubePlayerParams(
                showControls: true,
                showFullscreenButton: true,
                mute: false,
                enableCaption: true,
                loop: false,
              ),
            );
          } else {
            errorMessage = 'Không thể lấy ID video YouTube từ URL';
          }
        }
      } else {
        setState(() {
          errorMessage = 'Không tải được dữ liệu (mã lỗi: ${res.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final maxWidth = isDesktop ? 1000.0 : double.infinity;

    // Fix padding negative khi size.width < maxWidth
    final horizontalPadding = isDesktop ? ((size.width - maxWidth) / 2).clamp(0.0, double.infinity) : 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          vanHoa?['tieuDe'] ?? 'Chi Tiết Văn Hóa',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isDesktop ? 26 : 22,
            color: Colors.tealAccent,
            letterSpacing: 0.8,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.green.shade900.withOpacity(0.85),
        elevation: 4,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade900.withOpacity(0.9), Colors.black.withOpacity(0.7)],
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
                CircularProgressIndicator(color: Colors.greenAccent.shade400, strokeWidth: 4),
                const SizedBox(height: 24),
                Text(
                  'Đang tải chi tiết...',
                  style: TextStyle(color: Colors.white, fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
              : errorMessage != null
              ? Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
                  const SizedBox(height: 20),
                  Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: fetchVanHoaDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade400),
                  ),
                ],
              ),
            ),
          )
              : SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video YouTube
                  if (_youtubeController != null) ...[
                    Text(
                      'Video giới thiệu',
                      style: TextStyle(fontSize: isDesktop ? 22 : 20, fontWeight: FontWeight.bold, color: Colors.greenAccent.shade200),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                          aspectRatio: 16 / 9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ] else if (vanHoa!['videoUrl'] != null && vanHoa!['videoUrl'].isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.orange.shade900.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade400),
                          const SizedBox(width: 12),
                          Text('Không thể phát video (URL không hợp lệ)', style: TextStyle(color: Colors.orange.shade300, fontSize: 16)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Tiêu đề
                  Text(
                    vanHoa!['tieuDe'],
                    style: TextStyle(fontSize: isDesktop ? 32 : 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3),
                  ),
                  const SizedBox(height: 20),

                  // Mô tả
                  Text(
                    vanHoa!['moTa'],
                    style: TextStyle(fontSize: isDesktop ? 18 : 16, color: Colors.grey.shade300, height: 1.7),
                  ),
                  const SizedBox(height: 32),

                  // Hình ảnh
                  Text(
                    'Hình ảnh',
                    style: TextStyle(fontSize: isDesktop ? 22 : 20, fontWeight: FontWeight.bold, color: Colors.greenAccent.shade200),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        vanHoa!['hinhAnh'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: isDesktop ? 500 : 350,
                        loadingBuilder: (context, child, progress) {
                          return progress == null ? child : Container(height: isDesktop ? 500 : 350, color: Colors.grey[800], child: const Center(child: CircularProgressIndicator(color: Colors.greenAccent)));
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: isDesktop ? 500 : 350,
                            color: Colors.grey[800],
                            child: const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.white)),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}