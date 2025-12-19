import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'booking_page.dart';

class TourDetailPage extends StatefulWidget {
  final Map<String, dynamic> tour;

  const TourDetailPage({Key? key, required this.tour}) : super(key: key);

  @override
  State<TourDetailPage> createState() => _TourDetailPageState();
}

class _TourDetailPageState extends State<TourDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  // Colors
  final Color oceanBlue = const Color(0xFF0077BE);
  final Color lightOcean = const Color(0xFF00A6ED);
  final Color deepOcean = const Color(0xFF005A8C);
  final Color accentOrange = const Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showFloatingButton) {
        setState(() => _showFloatingButton = true);
      } else if (_scrollController.offset <= 300 && _showFloatingButton) {
        setState(() => _showFloatingButton = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String formatPrice(dynamic price) {
    if (price == null) return "Liên hệ";
    final formatter = NumberFormat("#,##0", "vi_VN");
    final parsed = double.tryParse(price.toString()) ?? 0;
    if (parsed <= 0) return "Liên hệ";
    return "${formatter.format(parsed)} ₫";
  }

  Widget buildTourImage(String? img, bool isWeb) {
    final height = isWeb ? 500.0 : 300.0;

    return Hero(
      tag: 'tour_${widget.tour["TourID"]}_image',
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: oceanBlue.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              img == null || img.isEmpty
                  ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      oceanBlue.withOpacity(0.3),
                      lightOcean.withOpacity(0.3)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.landscape_rounded,
                  size: 100,
                  color: oceanBlue,
                ),
              )
                  : img.startsWith("http")
                  ? Image.network(
                img,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(oceanBlue),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                ),
              )
                  : Image.asset(
                "assets/${img.replaceFirst("/assets/", "")}",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // Hot badge
              if (widget.tour["IsHot"] == true)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentOrange, accentOrange.withOpacity(0.9)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: accentOrange.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "HOT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
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
    );
  }

  Widget buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget buildItinerarySection() {
    final itinerary = widget.tour["Itinerary"];
    if (itinerary == null || itinerary.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    final days = _splitItineraryByDay(itinerary.toString());

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: oceanBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [oceanBlue, lightOcean],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "Lịch trình chi tiết",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...days.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            final regex = RegExp(r'^(Ngày\s*\d+:?)', caseSensitive: false);
            final match = regex.firstMatch(line);

            if (match != null) {
              String day = match.group(0)!;
              String rest = line.substring(match.end).trim();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            oceanBlue.withOpacity(0.2),
                            lightOcean.withOpacity(0.2)
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: oceanBlue,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: oceanBlue,
                        fontSize: 18,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          rest,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWeb = width > 900;
    final isMedium = width > 600 && width <= 900;
    final maxWidth = width > 1400 ? 1200.0 : (isWeb ? width * 0.85 : width);
    final horizontalPadding = isWeb ? 80.0 : (isMedium ? 40.0 : 24.0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: oceanBlue),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.share_rounded, color: oceanBlue),
                onPressed: () {
                  // Share functionality
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero Image Section
                Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    100,
                    horizontalPadding,
                    40,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: buildTourImage(
                        widget.tour["ImageUrl"],
                        isWeb || isMedium,
                      ),
                    ),
                  ),
                ),

                // Main Content
                Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.tour["TourName"] ?? "Tour không tên",
                          style: TextStyle(
                            fontSize: isWeb ? 42 : (isMedium ? 36 : 28),
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[900],
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Location
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: accentOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.tour["Location"] ?? "Chưa rõ",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Price Banner
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [deepOcean, oceanBlue, lightOcean],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: oceanBlue.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Giá tour",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatPrice(widget.tour["Price"]),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isWeb)
                                ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingPage(
                                            tour: widget.tour),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: oceanBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Đặt ngay",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Info Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = isWeb
                                ? 3
                                : (isMedium ? 2 : 2);

                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isWeb ? 1.5 : 1.3,
                              children: [
                                buildInfoCard(
                                  icon: Icons.calendar_today_rounded,
                                  label: "Ngày khởi hành",
                                  value: widget.tour["StartDate"] ?? "Liên hệ",
                                  color: oceanBlue,
                                ),
                                buildInfoCard(
                                  icon: Icons.access_time_rounded,
                                  label: "Thời gian",
                                  value: "${widget.tour["DurationDays"] ?? "-"} ngày",
                                  color: lightOcean,
                                ),
                                buildInfoCard(
                                  icon: Icons.directions_bus_rounded,
                                  label: "Điểm xuất phát",
                                  value: widget.tour["DepartureLocation"] ?? "Chưa rõ",
                                  color: deepOcean,
                                ),
                                buildInfoCard(
                                  icon: Icons.hotel_rounded,
                                  label: "Khách sạn",
                                  value: widget.tour["HotelName"] ?? "Chưa rõ",
                                  color: accentOrange,
                                ),
                                buildInfoCard(
                                  icon: Icons.directions_car_rounded,
                                  label: "Phương tiện",
                                  value: widget.tour["Transportation"] ?? "Chưa rõ",
                                  color: oceanBlue,
                                ),
                                buildInfoCard(
                                  icon: Icons.group_rounded,
                                  label: "Hướng dẫn viên",
                                  value: "Có",
                                  color: lightOcean,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Itinerary
                        buildItinerarySection(),

                        const SizedBox(height: 40),

                        // Desktop Booking Button
                        if (isWeb)
                          Center(
                            child: SizedBox(
                              width: 400,
                              child: ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingPage(
                                          tour: widget.tour),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: oceanBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                  shadowColor: oceanBlue.withOpacity(0.5),
                                ),
                                child: const Text(
                                  "Đặt Tour Ngay",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Button (Mobile only)
          if (_showFloatingButton && !isWeb)
            Positioned(
              bottom: 24,
              left: horizontalPadding,
              right: horizontalPadding,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(30),
                shadowColor: oceanBlue.withOpacity(0.5),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingPage(tour: widget.tour),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [oceanBlue, lightOcean],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        "Đặt Tour Ngay",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _splitItineraryByDay(String itinerary) {
  final regex = RegExp(r'(Ngày\s*\d+:?)', caseSensitive: false);
  final matches = regex.allMatches(itinerary).toList();

  if (matches.isEmpty) return [itinerary];

  List<String> result = [];
  for (int i = 0; i < matches.length; i++) {
    int start = matches[i].start;
    int end = (i + 1 < matches.length) ? matches[i + 1].start : itinerary.length;
    result.add(itinerary.substring(start, end).trim());
  }
  return result;
}