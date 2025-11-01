import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PromoBannerWidget extends StatefulWidget {
  const PromoBannerWidget({super.key});

  @override
  State<PromoBannerWidget> createState() => _PromoBannerWidgetState();
}

class _PromoBannerWidgetState extends State<PromoBannerWidget> {
  final List<Map<String, String>> banners = [
    {
      "image": "assets/b7.jpg",
      "title": "Khám phá Núi Cấm - An Giang",
      "subtitle": "Trải nghiệm cảnh quan thiên nhiên tuyệt đẹp trên núi"
    },
    {
      "image": "assets/b4.jpg",
      "title": "Khám phá Tri Tôn - An Giang",
      "subtitle": "Trải nghiệm văn hóa và cảnh quan tuyệt đẹp miền Tây An Giang"
    },
    {
      "image": "assets/b8.jpg",
      "title": "Khám phá Cồn Én - An Giang",
      "subtitle": "Thưởng ngoạn cảnh sông nước và trải nghiệm cuộc sống dân dã miền Tây An Giang"
    },
    {
      "image": "assets/b9.jpg",
      "title": "Rừng Tràm Trà Sư - An Giang",
      "subtitle": "Tham quan rừng ngập nước và thưởng ngoạn chim thú An Giang"
    },
    {
      "image": "assets/t1.jpg",
      "title": "Miếu Bà Chúa Xứ - An Giang",
      "subtitle": "Hành hương và khám phá truyền thuyết nổi tiếng An Giang"
    },
    {
      "image": "assets/b2.jpg",
      "title": "Hồ Tà Pạ - Núi Sam - An Giang",
      "subtitle": "Ngắm bình minh và cảnh quan tuyệt đẹp An Giang"
    },
    {
      "image": "assets/t11.jpg",
      "title": "Cây thốt nốt tình yêu - An Giang",
      "subtitle": "Trải nghiệm không gian yên bình, lãng mạn An Giang"
    },
    {
      "image": "assets/b1.jpg",
      "title": "Thiền viện Trúc Lâm - An Giang",
      "subtitle": "Trải nghiệm không gian thanh tịnh và kiến trúc Phật giáo độc đáo An Giang"
    },
    {
      "image": "assets/b3.jpg",
      "title": "Chùa Khmer Tân Châu - An Giang",
      "subtitle": "Khám phá kiến trúc Khmer độc đáo và nét văn hóa truyền thống miền Tây An Giang"
    },
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 180,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: banners.map((banner) {
            return GestureDetector(
              onTap: () {
                debugPrint("Clicked on ${banner['title']}");
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      banner['image']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner['title']!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner['subtitle']!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == entry.key ? Colors.blue : Colors.grey,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
