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
  final String apiBaseUrl = 'http://10.0.2.2:8000';

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
    'Châu Đốc - Miếu Bà':     ['assets/thoaingochau2.jpg','assets/test3.jpg'],
    'Du Lịch Núi Cấm':        ['assets/dlnuicam1.jpg', 'assets/dlnuicam2.jpg', 'assets/dlnuicam3.jpg'],
    'Du Lịch Núi Sam':        ['assets/dlnuisam1.jpg', 'assets/dlnuisam2.jpg', 'assets/dlnuisam3.jpg'],
    'Hồ Tà Pạ':               ['assets/tapa3.jpg', 'assets/tapa2.jpg', 'assets/tapa1.jpg'],
    'Rừng Tràm Trà Sư':       ['assets/rungtram1.jpg', 'assets/rungtram2.jpg', 'assets/rungtram3.jpg'],
    'Chùa Tà Pạ':             ['assets/tapa1.jpg', 'assets/tapa2.jpg', 'assets/tapa3.jpg'],
    'Tây An Cổ Tự':           ['assets/tayan1.jpg', 'assets/tayan2.jpg', 'assets/tayan3.jpg'],
    'Lăng Thoại Ngọc Hầu':    ['assets/thoaingochau2.jpg', 'assets/thoaingochau1.jpg'],
  };
  final Map<String, String> locationAudios = {
    'An Giang':           'assets/angiang.mp3',
    'Châu Đốc - Miếu Bà': 'assets/chaudoc.mp3',
    'Du Lịch Núi Cấm':    'assets/nuicam.mp3',
    'Du Lịch Núi Sam':    'assets/nuisam.mp3',
    'Hồ Tà Pạ':           'assets/hotapa.mp3',
    'Rừng Tràm Trà Sư':   'assets/rung.mp3',
    'Chùa Tà Pạ':         'assets/chuatapa.mp3',
    'Tây An Cổ Tự':       'assets/tayan.mp3',
    'Lăng Thoại Ngọc Hầu':'assets/thoaingochau.mp3',
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
    super.dispose();
    _audioPlayer.dispose();

  }

  // GỌI API KHI CHUYỂN TOUR
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


  // CHUYỂN ĐỊA ĐIỂM
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

    // Nếu là tour → gọi API
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
      'An Giang': 'An Giang – miền Tây sông nước hiền hòa, nổi tiếng với cảnh quan thiên nhiên tuyệt đẹp và ẩm thực đặc sắc.',
      'Châu Đốc - Miếu Bà': 'Thành phố sôi động bên sông, nổi bật với văn hóa đa dạng, lễ hội đặc trưng và điểm đến linh thiêng như Miếu Bà.',
      'Du Lịch Núi Cấm': 'Ngọn núi linh thiêng cao 710m, điểm đến tâm linh và khám phá thiên nhiên.',
      'Du Lịch Núi Sam': 'Điểm du lịch tâm linh nổi tiếng với nhiều đền chùa cổ kính.',
      'Hồ Tà Pạ': 'Hồ nước ngọt trong xanh giữa khung cảnh núi non hùng vĩ.',
      'Rừng Tràm Trà Sư': 'Khu rừng tràm xanh mát, nơi tận hưởng không gian thiên nhiên yên bình.',
      'Chùa Tà Pạ': 'Ngôi chùa cổ kính, thanh tịnh giữa núi rừng An Giang.',
      'Tây An Cổ Tự': 'Ngôi chùa pha trộn kiến trúc Ấn Độ – Việt Nam, nổi tiếng linh thiêng tại chân Núi Sam.',
      'Lăng Thoại Ngọc Hầu': 'Di tích lịch sử tưởng nhớ danh tướng Thoại Ngọc Hầu, người khai phá vùng đất An Giang.',
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
          {'x': 0.6, 'y': 0.75, 'label': 'Rừng Tràm', 'title': 'Rừng Tràm'},
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
    final hotspots = getHotspots();
    final locationDescription = getLocationDescription();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore, color: Colors.tealAccent.shade400, size: 28),
            const SizedBox(width: 8),
            const Text('Virtual Tour', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal.shade900.withOpacity(0.8), Colors.black.withOpacity(0.6)]),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isAudioPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.tealAccent.shade400,
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
          IconButton(
            icon: Icon(showControls ? Icons.visibility_off : Icons.visibility, color: Colors.tealAccent.shade400),
            onPressed: () => setState(() => showControls = !showControls),
            tooltip: 'Ẩn/Hiện điều khiển',
          ),
        ],

      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, Colors.teal.shade900, Colors.black], stops: const [0.0, 0.5, 1.0]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Panorama
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: opacity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [
                          BoxShadow(color: Colors.tealAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)
                        ]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: PanoramaViewer(
                            sensorControl: SensorControl.orientation,
                            animSpeed: 0.25,
                            zoom: 1.1,
                            minZoom: 1.0,
                            maxZoom: 2.5,
                            child: Image.asset(currentImage, fit: BoxFit.cover, filterQuality: FilterQuality.high),
                          ),
                        ),
                      ),

                      if (showControls) ...[
                        // Prev/Next
                        Positioned(left: 8, child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 40), onPressed: previousImage)),
                        Positioned(right: 8, child: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 40), onPressed: nextImage)),

                        // Tiêu đề + Info
                        Positioned(
                          top: 16, left: 16, right: 16,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.teal.shade900.withOpacity(0.7)]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.tealAccent.shade400, width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_city, color: Colors.tealAccent.shade400, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(currentTitle, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w800)),
                                          if (hotspots.isNotEmpty)
                                            Text('${hotspots.length} điểm kết nối', style: TextStyle(fontSize: 12, color: Colors.tealAccent.shade200)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(showInfo ? Icons.info : Icons.info_outline, color: Colors.tealAccent.shade400),
                                      onPressed: () => setState(() => showInfo = !showInfo),
                                    ),
                                  ],
                                ),
                              ),
                              // Mô tả (giới thiệu + lịch trình)
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                child: showInfo
                                    ? Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [Colors.teal.shade900.withOpacity(0.9), Colors.black.withOpacity(0.9)]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.tealAccent.shade700, width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(locationDescription, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                                      if (currentTour != null) ...[
                                        const SizedBox(height: 12),
                                        const Divider(color: Colors.tealAccent, height: 1),
                                        const SizedBox(height: 8),
                                        Text('Lịch trình:', style: TextStyle(color: Colors.tealAccent.shade200, fontWeight: FontWeight.bold)),
                                        Text(currentTour!['Itinerary'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                                      ],
                                    ],
                                  ),
                                )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),

                        // Hotspots
                        ...hotspots.map((spot) {
                          final left = screenWidth * (spot['x'] as double) - 20;
                          final top = (MediaQuery.of(context).size.height * 0.5) * (spot['y'] as double) - 20;
                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () => changeLocation(spot['title'] as String),
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 + (_pulseController.value * 0.3),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 50, height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.6 * _pulseController.value), blurRadius: 20, spreadRadius: 10)],
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(colors: [Colors.amber.shade400, Colors.orange.shade600]),
                                              ),
                                              child: const Icon(Icons.place, color: Colors.white, size: 32),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.teal.shade900.withOpacity(0.8)]),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.amber.shade700, width: 1.5),
                                          ),
                                          child: Text(
                                            spot['label'] as String,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // NÚT ĐẶT TOUR (chỉ hiện khi có tour)
              if (showControls && currentTour != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BookingPage(tour: currentTour!)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đặt Tour Ngay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

              const SizedBox(height: 16),

              // THANH CHỌN ĐIỂM ĐẾN
              if (showControls)
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.map, color: Colors.tealAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Chọn điểm đến', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            for (final location in [
                              {'title': 'An Giang', 'icon': Icons.location_city},
                              {'title': 'Châu Đốc - Miếu Bà', 'icon': Icons.location_city},
                              {'title': 'Du Lịch Núi Cấm', 'icon': Icons.terrain},
                              {'title': 'Du Lịch Núi Sam', 'icon': Icons.landscape},
                              {'title': 'Hồ Tà Pạ', 'icon': Icons.water},
                              {'title': 'Rừng Tràm Trà Sư', 'icon': Icons.forest},
                              {'title': 'Chùa Tà Pạ', 'icon': Icons.temple_buddhist},
                              {'title': 'Tây An Cổ Tự', 'icon': Icons.temple_buddhist},
                              {'title': 'Lăng Thoại Ngọc Hầu', 'icon': Icons.account_balance},
                            ])
                              GestureDetector(
                                onTap: () => changeLocation(location['title'] as String),
                                child: Container(
                                  width: 140,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    gradient: currentTitle == location['title']
                                        ? LinearGradient(colors: [Colors.tealAccent.shade400, Colors.teal.shade700])
                                        : LinearGradient(colors: [Colors.grey.shade800, Colors.grey.shade900]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: currentTitle == location['title'] ? Colors.tealAccent.shade200 : Colors.grey.shade700,
                                      width: 2,
                                    ),
                                    boxShadow: currentTitle == location['title']
                                        ? [BoxShadow(color: Colors.tealAccent.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)]
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
                                              color: currentTitle == location['title'] ? Colors.white : Colors.grey.shade400,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              location['title'] as String,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: currentTitle == location['title'] ? Colors.white : Colors.grey.shade300,
                                                fontWeight: currentTitle == location['title'] ? FontWeight.w800 : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (currentTitle == location['title'])
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            child: Icon(Icons.check, color: Colors.teal.shade700, size: 16),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
  }
}