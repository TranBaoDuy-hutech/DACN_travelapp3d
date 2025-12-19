import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dacsan.dart';

class DacSanDetailPage extends StatefulWidget {
  final DacSan item;
  const DacSanDetailPage({super.key, required this.item});

  @override
  State<DacSanDetailPage> createState() => _DacSanDetailPageState();
}

class _DacSanDetailPageState extends State<DacSanDetailPage> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final maxWidth = isDesktop ? 1000.0 : double.infinity;

    // Fix padding negative khi màn hình nhỏ hơn maxWidth
    final horizontalPadding = isDesktop
        ? ((size.width - maxWidth) / 2).clamp(0.0, double.infinity)
        : 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.item.tenMon,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isDesktop ? 26 : 22,
            color: Colors.tealAccent,
            letterSpacing: 0.8,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade900.withOpacity(0.9),
                Colors.black.withOpacity(0.7),
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
            colors: [Colors.black, Colors.green.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === MÔ HÌNH 3D (ĐÃ FIX TRIỆT ĐỂ LỖI NEGATIVE VALUE) ===
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      // Thay scale bằng translateY để tránh lỗi layout trên web khi màn hình nhỏ
                      transform: Matrix4.translationValues(0, isHovered ? -12 : 0, 0),
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: isHovered
                                  ? Colors.greenAccent.withOpacity(0.6)
                                  : Colors.greenAccent.withOpacity(0.4),
                              blurRadius: isHovered ? 50 : 30,
                              offset: Offset(0, isHovered ? 20 : 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: SizedBox(
                            height: isDesktop ? 520 : (isTablet ? 420 : 320),
                            width: double.infinity,
                            child: Stack(
                              children: [
                                ModelViewer(
                                  src: widget.item.modelUrl,
                                  alt: "Mô hình 3D ${widget.item.tenMon}",
                                  autoRotate: true,
                                  cameraControls: true,
                                  backgroundColor: Colors.transparent,
                                  disableZoom: false,
                                  loading: Loading.lazy,
                                ),
                                // Nhãn 3D
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.greenAccent.shade400, Colors.green.shade700],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.view_in_ar, color: Colors.white, size: 20),
                                        SizedBox(width: 6),
                                        Text(
                                          '3D MODEL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1,
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // === TÊN MÓN ===
                  Text(
                    widget.item.tenMon,
                    style: TextStyle(
                      fontSize: isDesktop ? 36 : 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === MÔ TẢ NGẮN ===
                  Text(
                    widget.item.moTa,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      color: Colors.grey.shade300,
                      height: 1.7,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // === GIỚI THIỆU CHUNG ===
                  Text(
                    "📜 Giới thiệu chung",
                    style: TextStyle(
                      fontSize: isDesktop ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent.shade200,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.item.quaTrinhHinhThanh,
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      color: Colors.grey.shade300,
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}