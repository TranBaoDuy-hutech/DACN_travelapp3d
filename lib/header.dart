import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:audioplayers/audioplayers.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  _HeaderWidgetState createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  double _gradientOpacity = 0.25;
  final AudioPlayer _player = AudioPlayer();

  // Ma trận làm sáng ảnh
  final brightnessFilter = ColorFilter.matrix([
    1.2, 0, 0, 0, 20,
    0, 1.2, 0, 0, 20,
    0, 0, 1.2, 0, 20,
    0, 0, 0, 1, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _playIntroSound(); // Phát âm thanh khi load
  }

  Future<void> _playIntroSound() async {
    try {
      await _player.play(AssetSource('gioithieu.mp3')); // Phát âm thanh từ asset
    } catch (e) {
      debugPrint('Lỗi phát âm thanh: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose(); // Giải phóng tài nguyên âm thanh
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _gradientOpacity = _gradientOpacity == 0.25 ? 0.4 : 0.25;
              });
              _playIntroSound(); // Phát lại âm thanh khi chạm
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã chạm vào ảnh 360!')),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: ColorFiltered(
                colorFilter: brightnessFilter,
                child: PanoramaViewer(
                  sensorControl: SensorControl.orientation,
                  animSpeed: 0.3,
                  zoom: 1.0,
                  minZoom: 1.0,
                  maxZoom: 2.0,
                  child: Image.asset(
                    'assets/test.JPG',
                    fit: BoxFit.cover,
                    semanticLabel: 'Ảnh panorama Việt Lữ Travel',
                  ),
                ),
              ),
            ),
          ),

          // Gradient động
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(_gradientOpacity),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Logo + Tên
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chuyển đến trang Việt Lữ Travel!')),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo3.jpg',
                      height: 60,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Việt Lữ Travel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24 * MediaQuery.of(context).textScaleFactor,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
