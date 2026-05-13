import '../models/player_stats.dart';
import 'api_service.dart';

export '../models/player_stats.dart' show PlayerUidResult;

class PlayerService {
  final ApiService _api;
  PlayerService(this._api);

  Future<ApiResult<PlayerStats>> getPlayerStats(
    String playerName,
    String platform,
  ) async {
    final result = await _api.get(
      '/player',
      params: {'player': playerName.trim(), 'platform': platform},
    );
    return ApiResult(
      PlayerStats.fromJson(result.data),
      staleAt: result.staleAt,
    );
  }

  Future<ApiResult<PlayerStats>> getPlayerStatsByUid(
    String uid,
    String platform,
  ) async {
    final result = await _api.get(
      '/player/uid',
      params: {'uid': uid, 'platform': platform},
    );
    return ApiResult(
      PlayerStats.fromJson(result.data),
      staleAt: result.staleAt,
    );
  }

  // nameToUid is only ever called on user action — no caching needed.
  Future<PlayerUidResult> nameToUid(String playerName, String platform) async {
    final result = await _api.get(
      '/nametouid',
      params: {'player': playerName.trim(), 'platform': platform},
    );
    return PlayerUidResult.fromJson(result.data);
  }
}
