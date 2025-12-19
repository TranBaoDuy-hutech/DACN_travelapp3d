import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'booking_page.dart';

class DiemDuLichPage extends StatefulWidget {
  const DiemDuLichPage({super.key});

  @override
  State<DiemDuLichPage> createState() => _DiemDuLichPageState();
}

class _DiemDuLichPageState extends State<DiemDuLichPage> with TickerProviderStateMixin {
  final String apiBaseUrl = 'http://127.0.0.1:8000';

  // TRẠNG THÁI
  String currentTitle = 'An Giang';
  Map<String, dynamic>? currentTour;
  int currentImageIndex = 0;
  double opacity = 1.0;
  bool showInfo = false;
  bool showControls = true;
  bool isLoading = false;
  bool isAudioPlaying = false;
  late AnimationController _pulseController;
  late AudioPlayer _audioPlayer;

  // ẢNH THEO ĐỊA ĐIỂM
  final Map<String, List<String>> locationImages = {
    'An Giang':               ['assets/test.JPG'],
    'Châu Đốc - Miếu Bà':     ['assets/thoaingochau2.jpg',                     'assets/test3.jpg'],
    'Du Lịch Núi Cấm':        ['assets/dlnuicam1.jpg', 'assets/dlnuicam2.jpg', 'assets/dlnuicam3.jpg'],
    'Du Lịch Núi Sam':        ['assets/dlnuisam1.jpg', 'assets/dlnuisam2.jpg', 'assets/dlnuisam3.jpg'],
    'Hồ Tà Pạ':               ['assets/tapa3.jpg',     'assets/tapa2.jpg',     'assets/tapa1.jpg'],
    'Rừng Tràm Trà Sư':       ['assets/rungtram1.jpg', 'assets/rungtram2.jpg', 'assets/rungtram3.jpg'],
    'Chùa Tà Pạ':             ['assets/tapa1.jpg',     'assets/tapa2.jpg',     'assets/tapa3.jpg'],
    'Tây An Cổ Tự':           ['assets/tayan1.jpg',    'assets/tayan2.jpg',    'assets/tayan3.jpg'],
    'Lăng Thoại Ngọc Hầu':    ['assets/thoaingochau2.jpg',                     'assets/thoaingochau1.jpg'],
  };

  final Map<String, String> locationAudios = {
    'An Giang':               'assets/angiang.mp3',
    'Châu Đốc - Miếu Bà':     'assets/chaudoc.mp3',
    'Du Lịch Núi Cấm':        'assets/nuicam.mp3',
    'Du Lịch Núi Sam':        'assets/nuisam.mp3',
    'Hồ Tà Pạ':               'assets/hotapa.mp3',
    'Rừng Tràm Trà Sư':       'assets/rung.mp3',
    'Chùa Tà Pạ':             'assets/chuatapa.mp3',
    'Tây An Cổ Tự':           'assets/tayan.mp3',
    'Lăng Thoại Ngọc Hầu':    'assets/thoaingochau.mp3',
  };

  final Map<String, int> locationToId = {
    'Châu Đốc - Miếu Bà': 1,
    'Du Lịch Núi Cấm': 26,
    'Du Lịch Núi Sam': 27,
    'Hồ Tà Pạ': 3,
    'Rừng Tràm Trà Sư': 2,
    'Chùa Tà Pạ': 28,
    'Tây An Cổ Tự': 6,
    'Lăng Thoại Ngọc Hầu': 29,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> loadTourByTitle(String title) async {
    final tourId = locationToId[title];
    if (tourId == null) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/tours/$tourId'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        if (data != null) {
          setState(() {
            currentTour = data;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> playAudioForLocation(String title) async {
    final audioPath = locationAudios[title];
    if (audioPath != null) {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(audioPath.replaceFirst('assets/', '')));
      setState(() => isAudioPlaying = true);
    }
  }

  Future<void> changeLocation(String title) async {
    if (currentTitle == title) return;
    setState(() => opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 300));
    await playAudioForLocation(title);
    setState(() {
      currentTitle = title;
      currentImageIndex = 0;
      showInfo = false;
      currentTour = null;
    });
    if (locationToId.containsKey(title)) {
      await loadTourByTitle(title);
    }
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => opacity = 1.0);
  }

  void nextImage() {
    final images = locationImages[currentTitle] ?? [];
    if (images.isEmpty) return;
    setState(() {
      currentImageIndex = (currentImageIndex + 1) % images.length;
    });
  }

  void previousImage() {
    final images = locationImages[currentTitle] ?? [];
    if (images.isEmpty) return;
    setState(() {
      currentImageIndex = (currentImageIndex - 1 + images.length) % images.length;
    });
  }

  String get currentImage {
    final images = locationImages[currentTitle];
    if (images == null || images.isEmpty) return 'assets/test.JPG';
    final idx = currentImageIndex.clamp(0, images.length - 1);
    return images[idx];
  }

  String getLocationDescription() {
    const info = {
      'An Giang': 'Khám phá An Giang – viên ngọc xanh của miền Tây Nam Bộ, nơi hội tụ vẻ đẹp sông nước hữu tình, văn hóa đa sắc và ẩm thực đậm đà bản sắc dân tộc.',
      'Châu Đốc - Miếu Bà': 'Châu Đốc – thành phố linh thiêng bên dòng sông Hậu, nổi tiếng với Miếu Bà Chúa Xứ huyền thoại, lễ hội tấp nập và bầu không khí tâm linh đầy cuốn hút.',
      'Du Lịch Núi Cấm': 'Núi Cấm – nóc nhà của miền Tây, nơi du khách chinh phục độ cao 710m để chiêm ngưỡng toàn cảnh đồng bằng và tận hưởng không khí trong lành giữa núi rừng bát ngát.',
      'Du Lịch Núi Sam': 'Núi Sam – điểm đến tâm linh bậc nhất miền Tây, nơi quy tụ nhiều ngôi chùa cổ kính và lưu giữ những câu chuyện huyền bí qua bao thế kỷ.',
      'Hồ Tà Pạ': 'Hồ Tà Pạ – "tuyệt tình cốc" giữa lòng An Giang, mặt nước xanh biếc soi bóng núi non hùng vĩ, mang đến không gian yên bình và thơ mộng khó quên.',
      'Rừng Tràm Trà Sư': 'Rừng Tràm Trà Sư – thiên đường xanh của miền sông nước, nơi bạn có thể len lỏi trên xuồng giữa thảm bèo xanh và lắng nghe bản hòa ca của thiên nhiên.',
      'Chùa Tà Pạ': 'Chùa Tà Pạ – ngôi chùa nằm trên đồi cao, ẩn mình giữa mây trời, là nơi du khách tìm về sự tĩnh lặng và bình an trong tâm hồn.',
      'Tây An Cổ Tự': 'Tây An Cổ Tự – kiệt tác kiến trúc giao hòa giữa Việt và Ấn, nằm uy nghi dưới chân Núi Sam, thu hút hàng vạn phật tử hành hương mỗi năm.',
      'Lăng Thoại Ngọc Hầu': 'Lăng Thoại Ngọc Hầu – công trình lịch sử trang nghiêm, tưởng nhớ vị danh tướng đã khai mở vùng đất An Giang trù phú và sông núi hữu tình ngày nay.',
    };
    return info[currentTitle] ?? '';
  }

  List<Map<String, dynamic>> getHotspots() {
    if (currentTitle == 'An Giang') return [];

    switch (currentTitle) {
      case 'Châu Đốc - Miếu Bà':
        return [
          {'x': 0.7, 'y': 0.7, 'label': 'Du Lịch Núi Cấm', 'title': 'Du Lịch Núi Cấm'},
          {'x': 0.3, 'y': 0.68, 'label': 'Du Lịch Núi Sam', 'title': 'Du Lịch Núi Sam'},
          {'x': 0.5, 'y': 0.72, 'label': 'Rừng Tràm Trà Sư', 'title': 'Rừng Tràm Trà Sư'},
          {'x': 0.6, 'y': 0.75, 'label': 'Chùa Tà Pạ', 'title': 'Chùa Tà Pạ'},
          {'x': 0.45, 'y': 0.77, 'label': 'Tây An Cổ Tự', 'title': 'Tây An Cổ Tự'},
          {'x': 0.55, 'y': 0.8, 'label': 'Lăng Thoại Ngọc Hầu', 'title': 'Lăng Thoại Ngọc Hầu'},
        ];
      case 'Du Lịch Núi Cấm':
        return [
          {'x': 0.25, 'y': 0.72, 'label': 'Châu Đốc - Miếu Bà', 'title': 'Châu Đốc - Miếu Bà'},
          {'x': 0.7, 'y': 0.7, 'label': 'Hồ Tà Pạ', 'title': 'Hồ Tà Pạ'},
          {'x': 0.5, 'y': 0.75, 'label': 'Rừng Tràm Trà Sư', 'title': 'Rừng Tràm Trà Sư'},
        ];
      case 'Du Lịch Núi Sam':
        return [
          {'x': 0.3, 'y': 0.7, 'label': 'Châu Đốc - Miếu Bà', 'title': 'Châu Đốc - Miếu Bà'},
          {'x': 0.75, 'y': 0.7, 'label': 'Hồ Tà Pạ', 'title': 'Hồ Tà Pạ'},
          {'x': 0.6, 'y': 0.75, 'label': 'Tây An Cổ Tự', 'title': 'Tây An Cổ Tự'},
          {'x': 0.55, 'y': 0.8, 'label': 'Lăng Thoại Ngọc Hầu', 'title': 'Lăng Thoại Ngọc Hầu'},
        ];
      case 'Hồ Tà Pạ':
        return [
          {'x': 0.25, 'y': 0.7, 'label': 'Du Lịch Núi Sam', 'title': 'Du Lịch Núi Sam'},
          {'x': 0.75, 'y': 0.7, 'label': 'Du Lịch Núi Cấm', 'title': 'Du Lịch Núi Cấm'},
          {'x': 0.5, 'y': 0.75, 'label': 'Chùa Tà Pạ', 'title': 'Chùa Tà Pạ'},
        ];
      case 'Rừng Tràm Trà Sư':
        return [
          {'x': 0.5, 'y': 0.72, 'label': 'Châu Đốc - Miếu Bà', 'title': 'Châu Đốc - Miếu Bà'},
          {'x': 0.6, 'y': 0.75, 'label': 'Chùa Tà Pạ', 'title': 'Chùa Tà Pạ'},
          {'x': 0.75, 'y': 0.7, 'label': 'Hồ Tà Pạ', 'title': 'Hồ Tà Pạ'},
        ];
      case 'Chùa Tà Pạ':
        return [
          {'x': 0.6, 'y': 0.75, 'label': 'Rừng Tràm', 'title': 'Rừng Tràm Trà Sư'},
          {'x': 0.5, 'y': 0.72, 'label': 'Châu Đốc - Miếu Bà', 'title': 'Châu Đốc - Miếu Bà'},
          {'x': 0.4, 'y': 0.78, 'label': 'Hồ Tà Pạ', 'title': 'Hồ Tà Pạ'},
        ];
      case 'Tây An Cổ Tự':
        return [
          {'x': 0.45, 'y': 0.72, 'label': 'Du Lịch Núi Sam', 'title': 'Du Lịch Núi Sam'},
          {'x': 0.55, 'y': 0.75, 'label': 'Lăng Thoại Ngọc Hầu', 'title': 'Lăng Thoại Ngọc Hầu'},
          {'x': 0.5, 'y': 0.7, 'label': 'Châu Đốc - Miếu Bà', 'title': 'Châu Đốc - Miếu Bà'},
        ];
      case 'Lăng Thoại Ngọc Hầu':
        return [
          {'x': 0.45, 'y': 0.72, 'label': 'Tây An Cổ Tự', 'title': 'Tây An Cổ Tự'},
          {'x': 0.5, 'y': 0.7, 'label': 'Du Lịch Núi Sam', 'title': 'Du Lịch Núi Sam'},
          {'x': 0.6, 'y': 0.75, 'label': 'Châu Đốc - Miếu Bà', 'title': 'Châu Đốc - Miếu Bà'},
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final hotspots = getHotspots();
    final locationDescription = getLocationDescription();

    // Responsive breakpoints
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isMobile = screenWidth <= 768;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: Colors.greenAccent.shade400, size: isDesktop ? 28 : 24),
            const SizedBox(width: 8),
            Text(
              'Virtual Tour',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isDesktop ? 22 : 18,
                color: Colors.greenAccent,
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
              colors: [Colors.green.shade900.withOpacity(0.8), Colors.black.withOpacity(0.6)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isAudioPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.greenAccent.shade400,
              size: isDesktop ? 24 : 20,
            ),
            tooltip: isAudioPlaying ? 'Tắt âm thanh' : 'Bật âm thanh',
            onPressed: () async {
              if (isAudioPlaying) {
                await _audioPlayer.pause();
                setState(() => isAudioPlaying = false);
              } else {
                await playAudioForLocation(currentTitle);
                setState(() => isAudioPlaying = true);
              }
            },
          ),
          if (isDesktop || isTablet)
            IconButton(
              icon: Icon(
                showControls ? Icons.visibility_off : Icons.visibility,
                color: Colors.greenAccent.shade400,
              ),
              onPressed: () => setState(() => showControls = !showControls),
              tooltip: 'Ẩn/Hiện điều khiển',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.green.shade900, Colors.black],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isDesktop) {
                return _buildDesktopLayout(constraints, hotspots, locationDescription);
              } else if (isTablet) {
                return _buildTabletLayout(constraints, hotspots, locationDescription);
              } else {
                return _buildMobileLayout(constraints, hotspots, locationDescription);
              }
            },
          ),
        ),
      ),
    );
  }

  // DESKTOP LAYOUT - 2 CỘT
  Widget _buildDesktopLayout(BoxConstraints constraints, List<Map<String, dynamic>> hotspots, String locationDescription) {
    return Row(
      children: [
        // CỘT TRÁI - PANORAMA
        Expanded(
          flex: 7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: _buildPanoramaViewer(constraints.maxWidth * 0.7, constraints.maxHeight, hotspots, true),
              ),
            ],
          ),
        ),

        // CỘT PHẢI - INFO & CONTROLS
        Container(
          width: constraints.maxWidth * 0.3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.black, Colors.green.shade900.withOpacity(0.5)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationHeader(true),
                const SizedBox(height: 20),
                _buildLocationDescription(locationDescription, true),
                if (currentTour != null) ...[
                  const SizedBox(height: 20),
                  _buildTourInfo(true),
                  const SizedBox(height: 20),
                  _buildBookingButton(true),
                ],
                const SizedBox(height: 30),
                _buildLocationGrid(true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TABLET LAYOUT
  Widget _buildTabletLayout(BoxConstraints constraints, List<Map<String, dynamic>> hotspots, String locationDescription) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          flex: 6,
          child: _buildPanoramaViewer(constraints.maxWidth, constraints.maxHeight * 0.6, hotspots, false),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLocationHeader(false),
                const SizedBox(height: 16),
                _buildLocationDescription(locationDescription, false),
                if (currentTour != null) ...[
                  const SizedBox(height: 16),
                  _buildTourInfo(false),
                  const SizedBox(height: 16),
                  _buildBookingButton(false),
                ],
                const SizedBox(height: 16),
                _buildLocationScroll(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // MOBILE LAYOUT
  Widget _buildMobileLayout(BoxConstraints constraints, List<Map<String, dynamic>> hotspots, String locationDescription) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: _buildPanoramaViewer(constraints.maxWidth, constraints.maxHeight, hotspots, false),
        ),
        if (showControls) ...[
          const SizedBox(height: 12),
          if (currentTour != null) _buildBookingButton(false),
          const SizedBox(height: 12),
          _buildLocationScroll(),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // PANORAMA VIEWER
  Widget _buildPanoramaViewer(double width, double height, List<Map<String, dynamic>> hotspots, bool isDesktop) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: opacity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isDesktop ? 32 : 24),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isDesktop ? 32 : 24),
              child: PanoramaViewer(
                sensorControl: SensorControl.none, // Tắt sensor để dùng chuột
                animSpeed: 1.0,
                zoom: 1.0,
                minZoom: 0.8,
                maxZoom: 3.0,
                child: Image.asset(
                  currentImage,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),

          // Navigation arrows - hiển thị cho tất cả khi showControls = true
          if (showControls) ...[
            Positioned(
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                  onPressed: previousImage,
                  tooltip: 'Ảnh trước',
                ),
              ),
            ),
            Positioned(
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 28),
                  onPressed: nextImage,
                  tooltip: 'Ảnh tiếp theo',
                ),
              ),
            ),
          ],

          // Info header - chỉ hiển thị trên mobile/tablet khi showControls = true
          if (showControls && !isDesktop)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildMobileInfoHeader(),
            ),

          // Hotspots - chỉ hiển thị khi showControls = true
          if (showControls)
            ...hotspots.map((spot) {
              final left = width * (spot['x'] as double) - 25;
              final top = (height * 0.5) * (spot['y'] as double) - 25;
              return Positioned(
                left: left,
                top: top,
                child: _buildHotspot(spot, isDesktop),
              );
            }).toList(),

          // Zoom controls
          if (showControls)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                          },
                          tooltip: 'Phóng to (scroll chuột)',
                        ),
                        Container(
                          width: 30,
                          height: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white),
                          onPressed: () {
                          },
                          tooltip: 'Thu nhỏ (scroll chuột)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Kéo để xoay\nScroll để zoom',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // MOBILE INFO HEADER
  Widget _buildMobileInfoHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.green.shade900.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.shade400, width: 2),
          ),
          child: Row(
            children: [
              Icon(Icons.location_city, color: Colors.greenAccent.shade400, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  currentTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  showInfo ? Icons.info : Icons.info_outline,
                  color: Colors.greenAccent.shade400,
                ),
                onPressed: () => setState(() => showInfo = !showInfo),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: showInfo
              ? Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade900.withOpacity(0.9),
                  Colors.black.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.greenAccent.shade700, width: 1.5),
            ),
            child: Text(
              getLocationDescription(),
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // LOCATION HEADER
  Widget _buildLocationHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.greenAccent.shade400, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_city, color: Colors.white, size: isDesktop ? 32 : 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentTitle,
                  style: TextStyle(
                    fontSize: isDesktop ? 24 : 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (getHotspots().isNotEmpty)
                  Text(
                    '${getHotspots().length} điểm kết nối',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // LOCATION DESCRIPTION
  Widget _buildLocationDescription(String description, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade900.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.shade700.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.greenAccent.shade400, size: isDesktop ? 20 : 18),
              const SizedBox(width: 8),
              Text(
                'Giới thiệu',
                style: TextStyle(
                  color: Colors.greenAccent.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 15 : 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // TOUR INFO
  Widget _buildTourInfo(bool isDesktop) {
    if (currentTour == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueAccent.shade700.withOpacity(0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, color: Colors.blueAccent.shade400, size: isDesktop ? 20 : 18),
              const SizedBox(width: 8),
              Text(
                'Lịch trình Tour',
                style: TextStyle(
                  color: Colors.blueAccent.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 16 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: BoxConstraints(maxHeight: isDesktop ? 200 : 150),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                currentTour!['Itinerary'] ?? 'Không có lịch trình.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 14 : 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOOKING BUTTON
  Widget _buildBookingButton(bool isDesktop) {
    if (currentTour == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookingPage(tour: currentTour!)),
          );
        },
        icon: Icon(Icons.calendar_today, size: isDesktop ? 20 : 18),
        label: Text(
          'Đặt Tour Ngay',
          style: TextStyle(
            fontSize: isDesktop ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent.shade400,
          foregroundColor: Colors.black87,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 24,
            vertical: isDesktop ? 18 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: Colors.greenAccent.withOpacity(0.5),
        ),
      ),
    );
  }

  // LOCATION GRID (for Desktop)
  Widget _buildLocationGrid(bool isDesktop) {
    final locations = [
      {'title': 'An Giang', 'icon': Icons.location_city},
      {'title': 'Châu Đốc - Miếu Bà', 'icon': Icons.location_city},
      {'title': 'Du Lịch Núi Cấm', 'icon': Icons.terrain},
      {'title': 'Du Lịch Núi Sam', 'icon': Icons.landscape},
      {'title': 'Hồ Tà Pạ', 'icon': Icons.water},
      {'title': 'Rừng Tràm Trà Sư', 'icon': Icons.forest},
      {'title': 'Chùa Tà Pạ', 'icon': Icons.temple_buddhist},
      {'title': 'Tây An Cổ Tự', 'icon': Icons.temple_buddhist},
      {'title': 'Lăng Thoại Ngọc Hầu', 'icon': Icons.account_balance},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.map, color: Colors.greenAccent, size: isDesktop ? 20 : 18),
            const SizedBox(width: 8),
            Text(
              'Chọn điểm đến',
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: locations.map((location) {
            final isSelected = currentTitle == location['title'];
            return InkWell(
              onTap: () => changeLocation(location['title'] as String),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: isDesktop ? 140 : 100,
                height: isDesktop ? 100 : 80,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [Colors.greenAccent.shade400, Colors.green.shade700],
                  )
                      : LinearGradient(
                    colors: [Colors.grey.shade800, Colors.grey.shade900],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.greenAccent.shade200 : Colors.grey.shade700,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                      : [],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            location['icon'] as IconData,
                            color: isSelected ? Colors.white : Colors.grey.shade400,
                            size: isDesktop ? 32 : 24,
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              location['title'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade300,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: isDesktop ? 12 : 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.green.shade700,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // LOCATION SCROLL (for Mobile & Tablet)
  Widget _buildLocationScroll() {
    final locations = [
      {'title': 'An Giang', 'icon': Icons.location_city},
      {'title': 'Châu Đốc - Miếu Bà', 'icon': Icons.location_city},
      {'title': 'Du Lịch Núi Cấm', 'icon': Icons.terrain},
      {'title': 'Du Lịch Núi Sam', 'icon': Icons.landscape},
      {'title': 'Hồ Tà Pạ', 'icon': Icons.water},
      {'title': 'Rừng Tràm Trà Sư', 'icon': Icons.forest},
      {'title': 'Chùa Tà Pạ', 'icon': Icons.temple_buddhist},
      {'title': 'Tây An Cổ Tự', 'icon': Icons.temple_buddhist},
      {'title': 'Lăng Thoại Ngọc Hầu', 'icon': Icons.account_balance},
    ];

    return Container(
      height: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.map, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  'Chọn điểm đến',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                final isSelected = currentTitle == location['title'];
                return GestureDetector(
                  onTap: () => changeLocation(location['title'] as String),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [Colors.greenAccent.shade400, Colors.green.shade700],
                      )
                          : LinearGradient(
                        colors: [Colors.grey.shade800, Colors.grey.shade900],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.greenAccent.shade200 : Colors.grey.shade700,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                location['icon'] as IconData,
                                color: isSelected ? Colors.white : Colors.grey.shade400,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  location['title'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade300,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.green.shade700,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // HOTSPOT WIDGET
  Widget _buildHotspot(Map<String, dynamic> spot, bool isDesktop) {
    return GestureDetector(
      onTap: () => changeLocation(spot['title'] as String),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isDesktop ? 55 : 45,
                  height: isDesktop ? 55 : 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.6 * _pulseController.value),
                        blurRadius: 20,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 10 : 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.greenAccent.shade400, Colors.green.shade600],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.place,
                        color: Colors.white,
                        size: isDesktop ? 30 : 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 14 : 10,
                    vertical: isDesktop ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.green.shade900.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.greenAccent.shade700, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    spot['label'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 13 : 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}