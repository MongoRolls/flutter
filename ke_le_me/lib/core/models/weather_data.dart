class WeatherData {
  final double temperature;
  final double humidity;
  final double apparentTemp;
  final int weatherCode;
  final double uvIndexMax;
  final double tempMax;
  final double tempMin;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.apparentTemp,
    required this.weatherCode,
    required this.uvIndexMax,
    required this.tempMax,
    required this.tempMin,
    required this.fetchedAt,
  });

  bool get isExpired => DateTime.now().difference(fetchedAt).inMinutes > 30;

  String get weatherDescription => _weatherCodeToDesc(weatherCode);

  static String _weatherCodeToDesc(int code) {
    if (code == 0) return '晴';
    if (code == 1) return '少云';
    if (code == 2) return '多云';
    if (code == 3) return '阴';
    if (code == 45 || code == 48) return '雾';
    if (code == 51 || code == 53 || code == 55) return '毛毛雨';
    if (code == 61 || code == 63 || code == 65) return '雨';
    if (code == 71 || code == 73 || code == 75) return '雪';
    if (code == 80 || code == 81 || code == 82) return '阵雨';
    if (code == 95) return '雷暴';
    return '未知';
  }

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'apparentTemp': apparentTemp,
    'weatherCode': weatherCode,
    'uvIndexMax': uvIndexMax,
    'tempMax': tempMax,
    'tempMin': tempMin,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    temperature: (json['temperature'] as num).toDouble(),
    humidity: (json['humidity'] as num).toDouble(),
    apparentTemp: (json['apparentTemp'] as num).toDouble(),
    weatherCode: json['weatherCode'] as int,
    uvIndexMax: (json['uvIndexMax'] as num).toDouble(),
    tempMax: (json['tempMax'] as num).toDouble(),
    tempMin: (json['tempMin'] as num).toDouble(),
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
  );

  /// Parses an Open-Meteo API response.
  ///
  /// Expected structure:
  /// ```json
  /// {
  ///   "current": {
  ///     "temperature_2m": 25.0,
  ///     "relative_humidity_2m": 60,
  ///     "apparent_temperature": 27.0,
  ///     "weather_code": 1
  ///   },
  ///   "daily": {
  ///     "uv_index_max": [5.0],
  ///     "temperature_2m_max": [30.0],
  ///     "temperature_2m_min": [20.0]
  ///   }
  /// }
  /// ```
  factory WeatherData.fromOpenMeteo(Map<String, dynamic> response) {
    final current = response['current'] as Map<String, dynamic>;
    final daily = response['daily'] as Map<String, dynamic>;

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      apparentTemp: (current['apparent_temperature'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      uvIndexMax: ((daily['uv_index_max'] as List).first as num).toDouble(),
      tempMax: ((daily['temperature_2m_max'] as List).first as num).toDouble(),
      tempMin: ((daily['temperature_2m_min'] as List).first as num).toDouble(),
      fetchedAt: DateTime.now(),
    );
  }
}
