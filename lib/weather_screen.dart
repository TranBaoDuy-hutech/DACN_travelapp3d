import 'package:flutter/material.dart';
import 'weather.dart';
import 'weather_service.dart';
import 'location_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService weatherService = WeatherService();
  final LocationService locationService = LocationService();
  Weather? _weather;
  bool _loading = true;
  String? _selectedCity;
  String? _locationInfo;

  final List<String> cities = [
    'An Giang',
    'Bà Rịa - Vũng Tàu',
    'Bạc Liêu',
    'Bắc Giang',
    'Bắc Kạn',
    'Bắc Ninh',
    'Bến Tre',
    'Bình Định',
    'Bình Dương',
    'Bình Phước',
    'Bình Thuận',
    'Cà Mau',
    'Cần Thơ',
    'Cao Bằng',
    'Đà Nẵng',
    'Đắk Lắk',
    'Đắk Nông',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Giang',
    'Hà Nam',
    'Hà Nội',
    'Hà Tĩnh',
    'Hải Dương',
    'Hải Phòng',
    'Hậu Giang',
    'Hòa Bình',
    'Hưng Yên',
    'Khánh Hòa',
    'Kiên Giang',
    'Kon Tum',
    'Lai Châu',
    'Lâm Đồng',
    'Lạng Sơn',
    'Lào Cai',
    'Long An',
    'Nam Định',
    'Nghệ An',
    'Ninh Bình',
    'Ninh Thuận',
    'Phú Thọ',
    'Phú Yên',
    'Quảng Bình',
    'Quảng Nam',
    'Quảng Ngãi',
    'Quảng Ninh',
    'Quảng Trị',
    'Sóc Trăng',
    'Sơn La',
    'Tây Ninh',
    'Thái Bình',
    'Thái Nguyên',
    'Thanh Hóa',
    'Thừa Thiên Huế',
    'Tiền Giang',
    'TP. Hồ Chí Minh',
    'Trà Vinh',
    'Tuyên Quang',
    'Vĩnh Long',
    'Vĩnh Phúc',
    'Yên Bái',
  ]..sort();

  @override
  void initState() {
    super.initState();
    _loadWeatherByDefaultLocation();
  }

  void _loadWeatherByDefaultLocation() async {
    setState(() => _loading = true);
    try {
      const double defaultLat = 10.7769;
      const double defaultLon = 106.7009;
      final weather = await weatherService.fetchCurrentWeatherByCoords(
        defaultLat,
        defaultLon,
      );
      final locationName = await weatherService.fetchLocationName(
        defaultLat,
        defaultLon,
      );
      setState(() {
        _weather = weather;
        _selectedCity = null;
        _locationInfo =
        'Vị trí: TP. Hồ Chí Minh ($locationName, Lat: ${defaultLat.toStringAsFixed(4)}, Lon: ${defaultLon.toStringAsFixed(4)})';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi lấy thời tiết: $e"),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _loadWeatherByLocation() async {
    setState(() => _loading = true);
    try {
      final position = await locationService.getCurrentLocation();
      final weather = await weatherService.fetchCurrentWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      final locationName = await weatherService.fetchLocationName(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _weather = weather;
        _selectedCity = null;
        _locationInfo =
        'Vị trí: $locationName (Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Không thể lấy vị trí GPS: $e. Sử dụng vị trí mặc định TP. Hồ Chí Minh."),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      _loadWeatherByDefaultLocation();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _loadWeatherByCity(String city) async {
    setState(() => _loading = true);
    try {
      final weather = await weatherService.fetchCurrentWeatherByCity(city);
      setState(() {
        _weather = weather;
        _selectedCity = city;
        _locationInfo =
        'Thành phố: $city (Lat: ${weather.latitude.toStringAsFixed(4)}, Lon: ${weather.longitude.toStringAsFixed(4)})';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi khi lấy thời tiết: $e"),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildWeatherInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange.shade700),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Đồng bộ với BusPage
      appBar: AppBar(
        title: const Text(
          'Dự báo thời tiết',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dropdown chọn tỉnh/thành phố
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    hint: Text(
                      'Chọn tỉnh/thành phố',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.orange.shade700),
                    items: cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(
                          city,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (city) {
                      if (city != null) _loadWeatherByCity(city);
                    },
                  ),
                ),
              ),
            ),
            // Weather display
            Expanded(
              child: _loading
                  ? Center(
                child: CircularProgressIndicator(
                  color: Colors.orange.shade700,
                ),
              )
                  : _weather == null
                  ? Center(
                child: Text(
                  'Không có dữ liệu thời tiết',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedCity ?? 'Vị trí hiện tại',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _locationInfo ?? 'Đang tải vị trí...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_weather!.temperature.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                    Text(
                      _weather!.description,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Image.network(
                      'https://openweathermap.org/img/wn/${_weather!.icon}@2x.png',
                      width: 100,
                      height: 100,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator(
                          color: Colors.orange.shade700,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.red,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWeatherInfo(
                          'Min',
                          '${_weather!.minTemp}°C',
                          Icons.arrow_downward,
                        ),
                        const SizedBox(width: 24),
                        _buildWeatherInfo(
                          'Max',
                          '${_weather!.maxTemp}°C',
                          Icons.arrow_upward,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Nút GPS
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _loadWeatherByLocation,
                icon: const Icon(Icons.my_location, color: Colors.white),
                label: const Text('Dùng vị trí GPS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "© 2025 Trần Bảo Duy. All rights reserved.",
                style: TextStyle(
                  color: Colors.blue.shade900.withOpacity(0.7),
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}