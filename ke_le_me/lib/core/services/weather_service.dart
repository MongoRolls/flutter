import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_data.dart';

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  WeatherData? _cache;
  Completer<WeatherData>? _pendingRequest;

  static const _cacheKey = 'weather_cache';

  Future<WeatherData> getWeather(double lat, double lon) async {
    if (_cache != null && !_cache!.isExpired) return _cache!;

    if (_pendingRequest != null) return _pendingRequest!.future;

    final diskCache = await _loadFromCache();
    if (diskCache != null && !diskCache.isExpired) {
      _cache = diskCache;
      return diskCache;
    }

    _pendingRequest = Completer<WeatherData>();
    try {
      final data = await _fetchFromOpenMeteo(lat, lon);
      _cache = data;
      await _saveToCache(data);
      _pendingRequest!.complete(data);
      return data;
    } catch (e) {
      if (diskCache != null) {
        _pendingRequest!.complete(diskCache);
        return diskCache;
      }
      _pendingRequest!.completeError(e);
      rethrow;
    } finally {
      _pendingRequest = null;
    }
  }

  Future<WeatherData> _fetchFromOpenMeteo(double lat, double lon) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code',
      'daily': 'uv_index_max,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Status ${response.statusCode}', uri: uri);
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      return WeatherData.fromOpenMeteo(json);
    } finally {
      client.close();
    }
  }

  /// 城市名 → 坐标（使用 Open-Meteo geocoding API，免费无 key）
  Future<({double lat, double lon})> geocodeCity(String city) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city,
      'count': '1',
      'language': 'zh',
      'format': 'json',
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Status ${response.statusCode}', uri: uri);
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final results = json['results'] as List?;
      if (results == null || results.isEmpty) {
        throw Exception('城市"$city"未找到');
      }
      final first = results[0] as Map<String, dynamic>;
      return (
        lat: (first['latitude'] as num).toDouble(),
        lon: (first['longitude'] as num).toDouble(),
      );
    } finally {
      client.close();
    }
  }

  Future<void> _saveToCache(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data.toJson()));
    } catch (e) {
      debugPrint('WeatherService: failed to save cache: $e');
    }
  }

  Future<WeatherData?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return WeatherData.fromJson(json);
    } catch (e) {
      debugPrint('WeatherService: failed to load cache: $e');
      return null;
    }
  }
}
