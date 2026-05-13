import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_cache.dart';
import '../utils/error_messages.dart';

export '../utils/api_cache.dart' show ApiResult;

class ApiService {
  late final Dio _dio;
  late final ApiCache _cache;

  ApiService(SharedPreferences prefs) {
    final proxyUrl = dotenv.env['PROXY_URL'] ?? '';
    final clientToken = dotenv.env['CLIENT_TOKEN'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: proxyUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: clientToken.isNotEmpty ? {'x-client-token': clientToken} : {},
      ),
    );
    _cache = ApiCache(prefs);
  }

  // Opens the underlying TCP connection so the first real request skips the
  // handshake latency. Failures are silently swallowed — this is best-effort.
  Future<void> warmup() async {
    try {
      await _dio.get('/healthz');
    } catch (_) {}
  }

  Future<ApiResult<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? params,
    bool noCache = false,
  }) async {
    final key = _cacheKey(endpoint, params);
    try {
      final response = await _dio.get(endpoint, queryParameters: params);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : {'_raw': response.data};
      if (!noCache) _cache.save(key, data);
      return ApiResult(data);
    } on DioException catch (e) {
      if (!noCache) {
        final cached = _cache.load(key);
        if (cached != null) {
          return ApiResult(
            cached.data as Map<String, dynamic>,
            staleAt: cached.savedAt,
          );
        }
      }
      throw Exception(friendlyError(e));
    }
  }

  Future<ApiResult<List<dynamic>>> getList(
    String endpoint, {
    Map<String, dynamic>? params,
  }) async {
    final key = _cacheKey(endpoint, params);
    try {
      final response = await _dio.get(endpoint, queryParameters: params);
      final List<dynamic> data;
      if (response.data is List) {
        data = response.data as List<dynamic>;
      } else if (response.data is Map) {
        final map = response.data as Map;
        if (map.containsKey('error')) throw Exception(map['error']);
        data = [];
      } else {
        data = [];
      }
      _cache.save(key, data);
      return ApiResult(data);
    } on DioException catch (e) {
      final cached = _cache.load(key);
      if (cached != null) {
        return ApiResult(cached.data as List<dynamic>, staleAt: cached.savedAt);
      }
      throw Exception(friendlyError(e));
    }
  }

  String _cacheKey(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return endpoint;
    final sorted = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$endpoint?${sorted.map((e) => '${e.key}=${e.value}').join('&')}';
  }
}
