import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton HTTP client for KeLeME backend.
///
/// Handles device auth, JWT token persistence, and automatic refresh.
class BackendApiService {
  BackendApiService._();
  static final BackendApiService instance = BackendApiService._();

  static const _baseUrlKey = 'backend_base_url';
  static const _accessTokenKey = 'backend_access_token';
  static const _refreshTokenKey = 'backend_refresh_token';
  static const _deviceIdKey = 'backend_device_id';

  static const _defaultBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  String? _deviceId;
  bool _initialized = false;

  String get baseUrl => _dio.options.baseUrl;
  bool get isAuthenticated => _accessToken != null;
  String? get deviceId => _deviceId;

  /// Must be called once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);

    _dio = Dio(BaseOptions(
      baseUrl: savedUrl ?? _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));

    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _deviceId = prefs.getString(_deviceIdKey);
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 && _refreshToken != null) {
      try {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $_accessToken';
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }
    }
    handler.next(error);
  }

  // ── Auth ───────────────────────────────────────────────────

  /// Anonymous device login. Creates user on first call.
  Future<Map<String, dynamic>> deviceLogin() async {
    final response = await _dio.post('/auth/device', data: {
      if (_deviceId != null) 'deviceId': _deviceId,
    });
    final data = response.data as Map<String, dynamic>;

    _accessToken = data['accessToken'] as String;
    _refreshToken = data['refreshToken'] as String;
    _deviceId = data['deviceId'] as String;

    await _saveTokens();
    debugPrint('BackendApiService: deviceLogin OK (new=${data['isNewUser']})');
    return data;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: _dio.options.baseUrl))
          .post('/auth/refresh', data: {'refreshToken': _refreshToken});
      _accessToken = (response.data as Map)['accessToken'] as String;
      await _saveTokens();
      return true;
    } on DioException {
      _accessToken = null;
      _refreshToken = null;
      await _saveTokens();
      return false;
    }
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString(_accessTokenKey, _accessToken!);
    } else {
      await prefs.remove(_accessTokenKey);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
    if (_deviceId != null) {
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  /// Ensure we have a valid session. Call on app startup.
  Future<void> ensureAuthenticated() async {
    if (_accessToken != null) {
      try {
        await _dio.get('/health');
        return;
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          final ok = await _refreshAccessToken();
          if (ok) return;
        }
      }
    }
    await deviceLogin();
  }

  /// Update base URL (e.g. from settings).
  Future<void> setBaseUrl(String url) async {
    _dio.options.baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }

  /// Create a Dio instance pre-configured with backend base URL and JWT auth.
  /// Used by AiService in proxy mode.
  Dio createDio({
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 60),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: '${_dio.options.baseUrl}/api/ai/',
      headers: {'Content-Type': 'application/json'},
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
    return dio;
  }

  // ── Generic request helpers ────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  /// Stream request for SSE (AI proxy).
  Future<Response<ResponseBody>> postStream(
    String path, {
    required Map<String, dynamic> data,
  }) =>
      _dio.post<ResponseBody>(
        path,
        data: data,
        options: Options(responseType: ResponseType.stream),
      );

  // ── Convenience API methods ────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final r = await get('/api/profile');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> fields) async {
    final r = await put('/api/profile', data: fields);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createDrinkLog({
    required int ml,
    String icon = '💧',
    String description = '喝水',
    DateTime? loggedAt,
  }) async {
    final r = await post('/api/drink-logs', data: {
      'ml': ml,
      'icon': icon,
      'description': description,
      if (loggedAt != null) 'loggedAt': loggedAt.toUtc().toIso8601String(),
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDrinkLogs({String? date}) async {
    final r = await get(
      '/api/drink-logs',
      queryParameters: {if (date case final d?) 'date': d},
    );
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkSyncDrinkLogs(
      List<Map<String, dynamic>> logs) async {
    final r = await post('/api/drink-logs/bulk-sync', data: {'logs': logs});
    return r.data as Map<String, dynamic>;
  }
}
