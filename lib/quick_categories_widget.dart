import 'package:flutter/material.dart';
import 'adventure_screen.dart';
import 'bien_screen.dart';
import 'city_tour_screen.dart';
import 'family_screen.dart';
import 'nui_screen.dart';
/*import 'culinary_screen.dart';     // Ẩm thực
import 'culture_screen.dart';       // Văn hóa
import 'history_screen.dart';       // Lịch sử
import 'nature_screen.dart';        // Thiên nhiên
import 'relax_screen.dart';         // Nghỉ dưỡng
*/
final List<Map<String, dynamic>> categories = [
  {"name": "Biển", "icon": Icons.beach_access},
  {"name": "Núi", "icon": Icons.terrain},
  {"name": "City Tour", "icon": Icons.location_city},
  {"name": "Adventure", "icon": Icons.hiking},
  {"name": "Family", "icon": Icons.family_restroom},

  // 5 danh mục mới được thêm
  {"name": "Ẩm thực", "icon": Icons.restaurant_menu},
  {"name": "Văn hóa", "icon": Icons.palette},
  {"name": "Lịch sử", "icon": Icons.account_balance},
  {"name": "Thiên nhiên", "icon": Icons.nature},
  {"name": "Nghỉ dưỡng", "icon": Icons.spa},
];

class QuickCategoriesWidget extends StatefulWidget {
  final Function(String category)? onCategoryTap;
  const QuickCategoriesWidget({super.key, this.onCategoryTap});

  @override
  State<QuickCategoriesWidget> createState() => _QuickCategoriesWidgetState();
}

class _QuickCategoriesWidgetState extends State<QuickCategoriesWidget> {
  String selectedCategory = "";

  // Hàm helper để navigate theo tên category (dễ mở rộng)
  void _navigateToScreen(String name) {
    Widget? screen;
    switch (name) {
      case "Biển":
        screen = const SeaScreen();
        break;
      case "Núi":
        screen = const NuiScreen();
        break;
      case "City Tour":
        screen = const CityTourScreen();
        break;
      case "Adventure":
        screen = const AdventureScreen();
        break;
      case "Family":
        screen = const FamilyScreen();
        break;
    /*  case "Ẩm thực":
        screen = const CulinaryScreen();     // Tạo screen này nếu cần
        break;
      case "Văn hóa":
        screen = const CultureScreen();
        break;
      case "Lịch sử":
        screen = const HistoryScreen();
        break;
      case "Thiên nhiên":
        screen = const NatureScreen();
        break;
      case "Nghỉ dưỡng":
        screen = const RelaxScreen();
        break;*/
    // Có thể thêm default fallback
    }

    if (screen != null && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final String name = category["name"];
          final isSelected = name == selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() => selectedCategory = name);

              _navigateToScreen(name);

              widget.onCategoryTap?.call(name);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
                border: isSelected ? Border.all(color: Colors.teal, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category["icon"],
                    size: 36,
                    color: isSelected ? Colors.teal : Colors.grey[700],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.teal[800] : Colors.grey[800],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}