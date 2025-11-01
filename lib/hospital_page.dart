import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HospitalPage extends StatefulWidget {
  const HospitalPage({super.key});

  @override
  State<HospitalPage> createState() => _HospitalPageState();
}

class _HospitalPageState extends State<HospitalPage> {
  final List<Map<String, dynamic>> hospitals = [
    {
      "name": "Bệnh viện Bạch Mai",
      "image": "https://isofhcare-backup.s3-ap-southeast-1.amazonaws.com/images/bv-bach-mai-ha-noi-isofhcare_52e0d9a8_c8ea_4cc0_91ab_07afe3f77543.jpg",
      "rating": 4.9,
      "price": 50,
      "location": "Hà Nội, Vietnam",
      "services": ["Emergency", "Surgery", "Cardiology"],
      "status": "Open 24/7",
    },
    {
      "name": "Bệnh viện Chợ Rẫy",
      "image": "https://images2.thanhnien.vn/528068263637045248/2023/8/18/img9538-16923539714192021645154.jpg",
      "rating": 4.8,
      "price": 60,
      "location": "TP. HCM, Vietnam",
      "services": ["Trauma", "Neurology", "Pediatrics"],
      "status": "Open 24/7",
    },
    {
      "name": "Bệnh viện Đà Nẵng",
      "image": "https://storage.googleapis.com/digital-platform/hinh_anh_vinmec_da_nang_benh_vien_quoc_te_lon_nhat_thanh_pho_bien_so_1_cedbaf0f63/hinh_anh_vinmec_da_nang_benh_vien_quoc_te_lon_nhat_thanh_pho_bien_so_1_cedbaf0f63.jpg",
      "rating": 4.3,
      "price": 45,
      "location": "Đà Nẵng, Vietnam",
      "services": ["General Medicine", "Radiology", "Emergency"],
      "status": "Open 24/7",
    },
    {
      "name": "Bệnh viện Việt Pháp",
      "image": "https://th.bing.com/th/id/R.81c11011c7ee07eef1488f1c0e0549bd?rik=9pjjPXzLmmb87g&riu=http%3a%2f%2fsigma.net.vn%2fuploaded%2f014(1).jpg&ehk=pCzVbN89YS8Jr0u8EIC7i2j0ZHQFMy%2bJrSYBMTTUbKs%3d&risl=&pid=ImgRaw&r=0",
      "rating": 4.5,
      "price": 100,
      "location": "Hà Nội, Vietnam",
      "services": ["International Clinic", "Surgery", "Maternity"],
      "status": "Open",
    },
    {
      "name": "Bệnh viện Huế",
      "image": "https://cdn-healthcare.hellohealthgroup.com/hospitals/vn/benh-vien-trung-uong-hue-1.png",
      "rating": 4.4,
      "price": 55,
      "location": "Huế, Vietnam",
      "services": ["Cardiology", "Orthopedics", "Emergency"],
      "status": "Open 24/7",
    },
  ];

  String search = "";
  String sortBy = "rating";
  bool isLoading = false;
  double? selectedRatingFilter;

  List<Map<String, dynamic>> _getFilteredAndSortedHospitals() {
    var filteredHospitals = hospitals.where((hospital) {
      if (selectedRatingFilter != null) {
        return hospital["rating"] >= selectedRatingFilter!;
      }
      return hospital["name"].toLowerCase().contains(search.toLowerCase()) ||
          hospital["location"].toLowerCase().contains(search.toLowerCase());
    }).toList();

    filteredHospitals.sort((a, b) {
      if (sortBy == "price") {
        return a["price"].compareTo(b["price"]);
      }
      return b["rating"].compareTo(a["rating"]);
    });

    return filteredHospitals;
  }

  @override
  Widget build(BuildContext context) {
    final filteredHospitals = _getFilteredAndSortedHospitals();
    final ratingFilters = [4.0, 4.5, 5.0];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cứu trợ y tế"),
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
                hintText: "Search by hospital name or location...",
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
                : filteredHospitals.isEmpty
                ? const Center(child: Text("No hospitals found"))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredHospitals.length,
              itemBuilder: (context, index) {
                final hospital = filteredHospitals[index];
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
                          hospital["image"],
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
                              hospital["name"],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hospital["location"],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: hospital["services"].map<Widget>((service) {
                                return Chip(
                                  label: Text(
                                    service,
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
                                      "${hospital["rating"]}",
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
                                  ).format(hospital["price"]),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text("/visit"),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Status: ${hospital["status"]}",
                              style: TextStyle(
                                fontSize: 14,
                                color: hospital["status"] == "Open 24/7"
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
                                  debugPrint("Contacting ${hospital["name"]}");
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
                                  "Contact Hospital",
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