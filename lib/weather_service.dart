import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather.dart';

class WeatherService {
  final String _apiKey = 'ee576823bbfc3cc9f861134f22664ff9';

  final Map<String, String> _cityNameMapping = {
    'Bà Rịa - Vũng Tàu': 'Vung Tau',
    'TP. Hồ Chí Minh': 'Ho Chi Minh',
    'Hà Nội': 'Hanoi',
    'Đà Nẵng': 'Da Nang',
    'Cần Thơ': 'Can Tho',
    'Hải Phòng': 'Hai Phong',
  };

  final Map<String, String> _reverseCityNameMapping = {
    'Vung Tau': 'Bà Rịa - Vũng Tàu',
    'Ho Chi Minh': 'TP. Hồ Chí Minh',
    'Hanoi': 'Hà Nội',
    'Da Nang': 'Đà Nẵng',
    'Can Tho': 'Cần Thơ',
    'Hai Phong': 'Hải Phòng',
  };

  Future<Weather> fetchCurrentWeatherByCoords(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return Weather.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Lỗi lấy thời tiết theo tọa độ: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Không thể lấy dữ liệu thời tiết: $e');
    }
  }

  Future<Weather> fetchCurrentWeatherByCity(String city) async {
    final apiCityName = _cityNameMapping[city] ?? city;
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$apiCityName&units=metric&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final weather = Weather.fromJson(json.decode(response.body));
        return Weather(
          temperature: weather.temperature,
          description: weather.description,
          icon: weather.icon,
          minTemp: weather.minTemp,
          maxTemp: weather.maxTemp,
          latitude: weather.latitude,
          longitude: weather.longitude,
          locationName: _reverseCityNameMapping[weather.locationName] ?? weather.locationName,
        );
      } else {
        throw Exception(
            'Lỗi lấy thời tiết cho $city: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Không thể lấy dữ liệu thời tiết cho $city: $e');
    }
  }

  Future<String> fetchLocationName(double lat, double lon) async {
    final url =
        'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final name = data[0]['name'] ?? 'Không xác định';
          final country = data[0]['country'] ?? '';
          final state = data[0]['state'] ?? '';
          return state.isNotEmpty ? '$name, $state, $country' : '$name, $country';
        } else {
          return 'Không xác định';
        }
      } else {
        throw Exception(
            'Lỗi lấy tên địa phương: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Không thể lấy tên địa phương: $e');
    }
  }
}