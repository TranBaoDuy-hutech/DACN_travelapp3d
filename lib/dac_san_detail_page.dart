import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'dacsan.dart';

class DacSanDetailPage extends StatelessWidget {
  final DacSan item;

  const DacSanDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          item.tenMon,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade900.withOpacity(0.8),
                Colors.black.withOpacity(0.6),
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
            colors: [
              Colors.black,
              Colors.green.shade900,
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Mô hình 3D
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade900.withOpacity(0.3),
                        Colors.black.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ModelViewer(
                    src: item.modelUrl,
                    alt: "3D model ${item.tenMon}",
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Tên món
              Text(
                item.tenMon,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 12),

              // 🔹 Mô tả ngắn
              Text(
                item.moTa,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade300,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Quá trình hình thành
              const Text(
                "📜 Quá trình hình thành:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.quaTrinhHinhThanh,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade300,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
