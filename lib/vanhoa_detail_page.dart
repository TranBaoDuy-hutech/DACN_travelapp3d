import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VanHoaDetailPage extends StatefulWidget {
  final int vanHoaId;
  const VanHoaDetailPage({super.key, required this.vanHoaId});

  @override
  State<VanHoaDetailPage> createState() => _VanHoaDetailPageState();
}

class _VanHoaDetailPageState extends State<VanHoaDetailPage> {
  Map<String, dynamic>? vanHoa;
  YoutubePlayerController? _controller;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVanHoaDetail();
  }

  Future<void> fetchVanHoaDetail() async {
    try {
      final res = await http.get(Uri.parse("http://10.0.2.2:8000/vanhoa/${widget.vanHoaId}"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final videoId = YoutubePlayer.convertUrlToId(data['videoUrl']);
        if (videoId == null) {
          setState(() {
            errorMessage = 'Invalid YouTube URL';
            isLoading = false;
          });
          return;
        }
        setState(() {
          vanHoa = data;
          _controller = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data. Status code: ${res.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          vanHoa?['tieuDe'] ?? 'Văn Hóa',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.green.shade900.withOpacity(0.8),
        elevation: 2,
        centerTitle: true,
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
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : errorMessage != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: fetchVanHoaDetail, child: const Text('Retry')),
              ],
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube Player
                if (_controller != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: YoutubePlayer(
                          controller: _controller!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: Colors.greenAccent.shade400,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Title
                Text(
                  vanHoa!['tieuDe'],
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  vanHoa!['moTa'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade300,
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 24),
                // Image
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      vanHoa!['hinhAnh'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 220,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.greenAccent),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          color: Colors.grey.shade800,
                          child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 60, color: Colors.white)),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
