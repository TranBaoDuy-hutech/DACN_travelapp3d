import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  final List<Map<String, dynamic>> restaurants = [
    {
      "name": "Phở Hà Nội",
      "image": "https://tse3.mm.bing.net/th/id/OIP.B02RKb6NI2CB276dKOiejAHaE7?cb=12ucfimg=1&w=2048&h=1365&rs=1&pid=ImgDetMain&o=7&rm=3",
      "rating": 4.5,
      "price": 5,
      "location": "Hà Nội, Vietnam",
      "cuisine": ["Vietnamese", "Phở", "Noodle"],
      "status": "Open",
    },
    {
      "name": "Bánh Mì Sài Gòn",
      "image": "https://tse3.mm.bing.net/th/id/OIP.g05x31m9hv42SDaQQ3amWQHaHZ?cb=12ucfimg=1&rs=1&pid=ImgDetMain&o=7&rm=3",
      "rating": 4.2,
      "price": 3,
      "location": "TP. HCM, Vietnam",
      "cuisine": ["Vietnamese", "Bánh Mì", "Street Food"],
      "status": "Open",
    },
    {
      "name": "Hải Sản Nha Trang",
      "image": "https://vnpay.vn/s1/statics.vnpay.vn/2023/9/0z4ws0ez4vw1694161390986.jpg",
      "rating": 4.8,
      "price": 15,
      "location": "Nha Trang, Vietnam",
      "cuisine": ["Seafood", "Vietnamese"],
      "status": "Open",
    },
    {
      "name": "Bún Bò Huế",
      "image": "https://th.bing.com/th/id/R.50247f9622f9b6364850d97f50f06a88?rik=xSmWCx3vuxeLIA&pid=ImgRaw&r=0",
      "rating": 4.3,
      "price": 6,
      "location": "Huế, Vietnam",
      "cuisine": ["Vietnamese", "Noodle", "Spicy"],
      "status": "Open",
    },
    {
      "name": "Cơm Tấm Sài Gòn",
      "image": "https://giadinh.mediacdn.vn/296230595582509056/2022/12/8/com-tam-suon-bi-cha-anh-delikitchen-16703179459501600612-1670475400971-1670475401247125865720.jpg",
      "rating": 4.6,
      "price": 4,
      "location": "TP. HCM, Vietnam",
      "cuisine": ["Vietnamese", "Rice", "Grilled"],
      "status": "Limited Seats",
    },
  ];

  String search = "";
  String sortBy = "rating";
  bool isLoading = false;
  double? selectedRatingFilter;

  List<Map<String, dynamic>> _getFilteredAndSortedRestaurants() {
    var filteredRestaurants = restaurants.where((restaurant) {
      if (selectedRatingFilter != null) {
        return restaurant["rating"] >= selectedRatingFilter!;
      }
      return restaurant["name"].toLowerCase().contains(search.toLowerCase()) ||
          restaurant["location"].toLowerCase().contains(search.toLowerCase());
    }).toList();

    filteredRestaurants.sort((a, b) {
      if (sortBy == "price") {
        return a["price"].compareTo(b["price"]);
      }
      return b["rating"].compareTo(a["rating"]);
    });

    return filteredRestaurants;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRestaurants = _getFilteredAndSortedRestaurants();
    final ratingFilters = [4.0, 4.5, 5.0];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ẩm thực"),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "rating", child: Text("Sort by Rating")),
              const PopupMenuItem(value: "price", child: Text("Sort by Price")),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() {
                search = value;
                selectedRatingFilter = null;
              }),
              decoration: InputDecoration(
                hintText: "Search by restaurant name or location...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    search = "";
                    selectedRatingFilter = null;
                  }),
                )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ratingFilters.map((rating) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text("${rating}★+"),
                  selected: selectedRatingFilter == rating,
                  onSelected: (selected) {
                    setState(() {
                      selectedRatingFilter = selected ? rating : null;
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRestaurants.isEmpty
                ? const Center(child: Text("No restaurants found"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = filteredRestaurants[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          restaurant["image"],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant["name"],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restaurant["location"],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: restaurant["cuisine"].map<Widget>((cuisine) {
                                return Chip(
                                  label: Text(
                                    cuisine,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${restaurant["rating"]}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'en_US',
                                    symbol: '\$',
                                    decimalDigits: 0,
                                  ).format(restaurant["price"]),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text("/person"),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Status: ${restaurant["status"]}",
                              style: TextStyle(
                                fontSize: 14,
                                color: restaurant["status"] == "Open"
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  debugPrint("Booking ${restaurant["name"]}");
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                child: const Text(
                                  "Reserve Table",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "© 2025 Trần Bảo Duy. All rights reserved.",
              style: TextStyle(
                color: Colors.blue.shade900.withOpacity(0.7),
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}