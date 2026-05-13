import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/map_rotation.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

final mapRotationProvider = FutureProvider<ApiResult<MapRotation>>((ref) async {
  return ref.watch(mapServiceProvider).getMapRotation();
});
