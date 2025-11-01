import 'package:flutter/material.dart';
import 'package:travelapp/restaurant_page.dart';
import 'package:travelapp/weather_screen.dart';
import 'attraction_page.dart';
import 'bus_page.dart';
import 'cruise_page.dart';
import 'experience_page.dart';
import 'flight_page.dart';
import 'hospital_page.dart';
import 'hotel_page.dart';
import 'map_page.dart';
import 'promotion_page.dart';
import 'contact_page.dart';

class FeatureGridWidget extends StatelessWidget {
  const FeatureGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {"icon": Icons.flight, "title": "Chuyến bay", "color": Colors.blue},
      {"icon": Icons.hotel, "title": "Khách sạn", "color": Colors.green},
      {"icon": Icons.explore, "title": "Trải nghiệm", "color": Colors.orange},
      {"icon": Icons.directions_bus, "title": "Xe khách", "color": Colors.red},
      {"icon": Icons.directions_boat, "title": "Du thuyền", "color": Colors.indigo},
      {"icon": Icons.local_offer, "title": "Khuyến mãi", "color": Colors.purple},
      {"icon": Icons.landscape, "title": "Tham quan", "color": Colors.teal},
      {"icon": Icons.phone, "title": "Liên hệ", "color": Colors.brown},
      {"icon": Icons.wb_sunny, "title": "Thời tiết", "color": Colors.cyan},
      {"icon": Icons.map, "title": "Bản đồ", "color": Colors.greenAccent},
      {"icon": Icons.restaurant, "title": "Ẩm thực", "color": Colors.orangeAccent},
      {"icon": Icons.local_hospital, "title": "Cứu trợ y tế", "color": Colors.redAccent},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(2, 4),
          )
        ],
      ),
      child: GridView.builder(
        itemCount: features.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final feature = features[index];
          return _buildFeature(
            context,
            feature["icon"] as IconData,
            feature["title"] as String,
            feature["color"] as Color,
          );
        },
      ),
    );
  }

  static Widget _buildFeature(BuildContext context, IconData icon, String title, Color color) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        switch (title) {
          case "Liên hệ":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactPage()),
            );
            break;
          case "Khuyến mãi":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PromotionPage()),
            );
            break;
          case "Chuyến bay":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FlightPage()),
            );
            break;
          case "Khách sạn":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HotelPage()),
            );
            break;
          case "Xe khách":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BusPage()),
            );
            break;
          case "Du thuyền":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CruisePage()),
            );
            break;
          case "Trải nghiệm":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExperiencePage()),
            );
            break;
          case "Tham quan":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttractionPage()),
            );
            break;
          case "Thời tiết":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WeatherScreen()),
            );
            break;
          case "Bản đồ":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapPage()), // tạo MapPage riêng
            );
            break;
          case "Ẩm thực":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RestaurantPage()), // tạo RestaurantPage riêng
            );
            break;
          case "Cứu trợ y tế":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HospitalPage()), // tạo HospitalPage riêng
            );
            break;
          default:
            debugPrint("Tapped on $title");
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
