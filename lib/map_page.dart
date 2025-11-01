import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController(
      initPosition: GeoPoint(latitude: 10.7769, longitude: 106.7009),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await mapController.addMarker(
        GeoPoint(latitude: 10.7769, longitude: 106.7009),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 48,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ'),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: OSMFlutter(
              controller: mapController,
              osmOption: const OSMOption(
                zoomOption: ZoomOption(
                  initZoom: 12,
                  minZoomLevel: 8,
                  maxZoomLevel: 18,
                  stepZoom: 1.0,
                ),
                enableRotationByGesture: true,
              ),
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