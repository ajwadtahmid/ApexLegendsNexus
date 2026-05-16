import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiResult<T> {
  final T data;
  final DateTime? staleAt;
  const ApiResult(this.data, {this.staleAt});
}

class CachedEntry {
  final dynamic data;
  final DateTime savedAt;
  const CachedEntry({required this.data, required this.savedAt});
}

class ApiCache {
  final SharedPreferences _prefs;
  static const _prefix = 'api_cache:';
  static const _tsPrefix = 'api_cache_ts:';
  static const _maxAgeHours = 24;

  ApiCache(this._prefs);

  Future<void> save(String key, dynamic data) async {
    await _prefs.setString('$_prefix$key', jsonEncode(data));
    await _prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  CachedEntry? load(String key) {
    final raw = _prefs.getString('$_prefix$key');
    final ts = _prefs.getInt('$_tsPrefix$key');
    if (raw == null || ts == null) return null;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(savedAt).inHours > _maxAgeHours) return null;
    try {
      return CachedEntry(data: jsonDecode(raw), savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }
}
