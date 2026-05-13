import '../models/map_rotation.dart';
import 'api_service.dart';

class MapService {
  final ApiService _api;
  MapService(this._api);

  Future<ApiResult<MapRotation>> getMapRotation() async {
    // Map rotation contains live countdown timers — always fetch fresh,
    // never fall back to a cached response.
    final result = await _api.get(
      '/maprotation',
      params: {'version': '2'},
      noCache: true,
    );
    return ApiResult(MapRotation.fromJson(result.data));
  }
}
