class Weather {
  final double temperature;
  final String description;
  final String icon;
  final double minTemp;
  final double maxTemp;
  final double latitude;
  final double longitude;
  final String locationName;

  Weather({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.minTemp,
    required this.maxTemp,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      minTemp: json['main']['temp_min'].toDouble(),
      maxTemp: json['main']['temp_max'].toDouble(),
      latitude: json['coord']['lat'].toDouble(),
      longitude: json['coord']['lon'].toDouble(),
      locationName: json['name'],
    );
  }
}