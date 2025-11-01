import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'diem_du_lich_page.dart';
import 'dac_san_page.dart';
import 'van_hoa_page.dart';
import 'package:flutter/services.dart';

class Tours3DPage extends StatefulWidget {
  const Tours3DPage({super.key});

  @override
  State<Tours3DPage> createState() => _Tours3DPageState();
}

class _Tours3DPageState extends State<Tours3DPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;

  // Màu sắc đồng bộ
  final Color deepOcean = const Color(0xFF005A8C);
  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color accentOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/intro.mp4')
        ..setLooping(true)
        ..setVolume(1.0);

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('Lỗi khi tải video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải video giới thiệu.')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isInitialized) {
      if (state == AppLifecycleState.paused) {
        _controller.pause();
      } else if (state == AppLifecycleState.resumed && _isPlaying) {
        _controller.play();
      }
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        children: [
          // Video nền
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Pattern nen.png trên cùng
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/nen.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Progress bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                backgroundColor: deepOcean.withOpacity(0.3),
                playedColor: oceanBlue,
                bufferedColor: lightOcean.withOpacity(0.5),
              ),
            ),
          ),

          // Icon Play khi video dừng
          if (!_isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Icon(Icons.play_arrow, size: 70, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required Widget page,
    required Color color,
    required String imagePath,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          _controller.pause();
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.asset(
                      imagePath,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.image_not_supported_rounded, color: color, size: 36),
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(_getSubtitle(title),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(String title) {
    switch (title) {
      case 'Điểm du lịch':
        return 'Khám phá các địa danh nổi tiếng';
      case 'Đặc sản':
        return 'Ẩm thực đặc trưng An Giang';
      case 'Văn hóa':
        return 'Di sản và lễ hội truyền thống';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // Video giới thiệu
              Container(
                margin: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildVideoPlayer(),
                ),
              ),

              const SizedBox(height: 20),

              // Thông tin giới thiệu
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/dl.jpg'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "An Giang – vùng đất miền Tây hiền hòa, nổi tiếng với những cảnh đẹp thiên nhiên hùng vĩ như Núi Cấm, Rừng Tràm Trà Sư, cùng nền văn hóa đa dạng và ẩm thực phong phú.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Các card navigation
              _buildNavigationCard(
                title: "Điểm du lịch",
                page: const DiemDuLichPage(),
                color: oceanBlue,
                imagePath: 'assets/dl.jpg',
              ),
              _buildNavigationCard(
                title: "Đặc sản",
                page: const DacSanPage(),
                color: accentOrange,
                imagePath: 'assets/ds.jpg',
              ),
              _buildNavigationCard(
                title: "Văn hóa",
                page: const VanHoaPage(),
                color: deepOcean,
                imagePath: 'assets/vh.jpg',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
