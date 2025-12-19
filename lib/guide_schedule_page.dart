import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GuideToursPage extends StatefulWidget {
  final int guideId;
  const GuideToursPage({super.key, required this.guideId});

  @override
  State<GuideToursPage> createState() => _GuideToursPageState();
}

class _GuideToursPageState extends State<GuideToursPage> {
  List tours = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchGuideTours();
  }

  Future<void> fetchGuideTours() async {
    try {
      final res = await http.get(Uri.parse("http://127.0.0.1/guide/${widget.guideId}/tours"));
      if (res.statusCode == 200) {
        setState(() {
          tours = jsonDecode(res.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
        debugPrint("❌ Lỗi backend: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("❌ Lỗi kết nối: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch trình HDV"),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tours.isEmpty
          ? const Center(child: Text("Chưa có tour được phân công"))
          : ListView.builder(
        itemCount: tours.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final tour = tours[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              title: Text(tour["TourName"] ?? "-"),
              subtitle: Text(
                  "${tour["Location"] ?? "-"}\n${tour["StartDate"]} → ${tour["EndDate"]}\nVai trò: ${tour["Role"]}"),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
