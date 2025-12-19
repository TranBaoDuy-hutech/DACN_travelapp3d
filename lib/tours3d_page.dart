import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'diem_du_lich_page.dart';
import 'dac_san_page.dart';
import 'van_hoa_page.dart';

class Tours3DPage extends StatefulWidget {
  const Tours3DPage({super.key});

  @override
  State<Tours3DPage> createState() => _Tours3DPageState();
}

class _Tours3DPageState extends State<Tours3DPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _hoveredCardIndex = -1;

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
        ..setVolume(0.0);

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _isPlaying = true;
      }
    } catch (e) {
      debugPrint('Lỗi tải video: $e');
      if (mounted) {
        setState(() => _isInitialized = true);
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

  void _toggleMute() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.volume > 0) {
        _controller.setVolume(0.0);
      } else {
        _controller.setVolume(1.0);
      }
    });
  }

  Widget _buildVideoPlayer(bool isLargeScreen) {
    if (!_isInitialized) {
      return Container(
        height: isLargeScreen ? 600 : 400,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(oceanBlue),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: oceanBlue.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Pattern overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Image.asset(
                    'assets/nen.png',
                    repeat: ImageRepeat.repeat,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              // Controls
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      // Play/Pause button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Mute/Unmute
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: _toggleMute,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _controller.value.volume > 0
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Progress bar
                      Expanded(
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: lightOcean,
                            backgroundColor: Colors.white30,
                            bufferedColor: Colors.white60,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Play icon when paused
              if (!_isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required Widget page,
    required Color color,
    required String imagePath,
    required int index,
    required bool isLargeScreen,
  }) {
    final isHovered = _hoveredCardIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredCardIndex = index),
      onExit: (_) => setState(() => _hoveredCardIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, isHovered ? -8.0 : 0.0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              HapticFeedback.mediumImpact();
              _controller.pause();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: Container(
              padding: EdgeInsets.all(isLargeScreen ? 32 : 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    isHovered ? color.withOpacity(0.08) : color.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isHovered ? color.withOpacity(0.3) : Colors.grey[200]!,
                  width: isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isHovered
                        ? color.withOpacity(0.2)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isHovered ? 30 : 20,
                    offset: Offset(0, isHovered ? 15 : 10),
                  ),
                ],
              ),
              child: isLargeScreen
                  ? _buildCardContentRow(
                title,
                subtitle,
                color,
                imagePath,
                isHovered,
                isLargeScreen,
              )
                  : _buildCardContentColumn(
                title,
                subtitle,
                color,
                imagePath,
                isHovered,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContentRow(
      String title,
      String subtitle,
      Color color,
      String imagePath,
      bool isHovered,
      bool isLargeScreen,
      ) {
    return Row(
      children: [
        // Image
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isLargeScreen ? 140 : 120,
          height: isLargeScreen ? 140 : 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: isHovered ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                  ),
                ),
                child: Icon(Icons.image_not_supported, color: color, size: 50),
              ),
            ),
          ),
        ),
        SizedBox(width: isLargeScreen ? 40 : 24),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isLargeScreen ? 32 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[900],
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  color: Colors.grey[600],
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHovered
                        ? [color, color.withOpacity(0.8)]
                        : [color.withOpacity(0.1), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Khám phá ngay",
                      style: TextStyle(
                        color: isHovered ? Colors.white : color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isHovered ? 0.0 : -0.125,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: isHovered ? Colors.white : color,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardContentColumn(
      String title,
      String subtitle,
      Color color,
      String imagePath,
      bool isHovered,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            imagePath,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                ),
              ),
              child: Icon(Icons.image_not_supported, color: color, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Khám phá ngay",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: color, size: 20),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width > 1000;
    final isMediumScreen = width > 600 && width <= 1000;

    // Giới hạn chiều rộng tối đa
    final maxWidth = width > 1600 ? 1400.0 : (isLargeScreen ? width * 0.85 : width);
    final horizontalPadding = isLargeScreen ? 80.0 : (isMediumScreen ? 60.0 : 24.0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                // Hero Section
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isLargeScreen ? 80 : 40,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isLargeScreen ? 40 : 20),

                      // Tiêu đề chính
                      Text(
                        "Khám Phá An Giang",
                        style: TextStyle(
                          fontSize: isLargeScreen ? 64 : (isMediumScreen ? 48 : 36),
                          fontWeight: FontWeight.w900,
                          color: deepOcean,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isLargeScreen ? 24 : 16),

                      // Subtitle
                      Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Text(
                          "Hành trình trải nghiệm 3D sống động",
                          style: TextStyle(
                            fontSize: isLargeScreen ? 28 : (isMediumScreen ? 22 : 18),
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "Điểm du lịch • Đặc sản • Văn hóa",
                        style: TextStyle(
                          fontSize: isLargeScreen ? 20 : 16,
                          color: oceanBlue,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isLargeScreen ? 60 : 40),

                      // Video Player
                      _buildVideoPlayer(isLargeScreen),
                    ],
                  ),
                ),

                SizedBox(height: isLargeScreen ? 100 : 60),

                // Giới thiệu
                Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: oceanBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "VỀ AN GIANG",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: oceanBlue,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "An Giang – vùng đất miền Tây Nam Bộ giàu bản sắc, nổi bật với thiên nhiên hùng vĩ, văn hóa đa dạng và nền ẩm thực đặc trưng, là điểm đến hấp dẫn cho du khách trong và ngoài nước.",
                        style: TextStyle(
                          fontSize: isLargeScreen ? 22 : (isMediumScreen ? 19 : 17),
                          color: Colors.grey[700],
                          height: 1.8,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isLargeScreen ? 120 : 80),

                // Navigation Cards
                Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      _buildNavigationCard(
                        title: "Điểm du lịch",
                        subtitle: "Khám phá các địa danh nổi tiếng bằng công nghệ 360° sống động",
                        page: const DiemDuLichPage(),
                        color: oceanBlue,
                        imagePath: 'assets/dl.jpg',
                        index: 0,
                        isLargeScreen: isLargeScreen || isMediumScreen,
                      ),
                      SizedBox(height: isLargeScreen ? 32 : 24),
                      _buildNavigationCard(
                        title: "Đặc sản",
                        subtitle: "Thưởng thức hương vị đặc trưng của vùng đất miền Tây sông nước",
                        page: const DacSanPage(),
                        color: accentOrange,
                        imagePath: 'assets/ds.jpg',
                        index: 1,
                        isLargeScreen: isLargeScreen || isMediumScreen,
                      ),
                      SizedBox(height: isLargeScreen ? 32 : 24),
                      _buildNavigationCard(
                        title: "Văn hóa",
                        subtitle: "Tìm hiểu di sản, lễ hội và đời sống văn hóa đa dạng của An Giang",
                        page: const VanHoaPage(),
                        color: deepOcean,
                        imagePath: 'assets/vh.jpg',
                        index: 2,
                        isLargeScreen: isLargeScreen || isMediumScreen,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isLargeScreen ? 120 : 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
