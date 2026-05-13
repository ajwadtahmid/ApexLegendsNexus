import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_stats.dart';
import '../services/api_service.dart';
import 'api_provider.dart';
import 'settings_provider.dart';

final _uidPattern = RegExp(r'^\d+$');

final searchPlayerProvider =
    FutureProvider.family<ApiResult<PlayerStats>, (String, String)>((
      ref,
      params,
    ) async {
      final (query, platform) = params;
      final service = ref.watch(playerServiceProvider);
      final isUid = _uidPattern.hasMatch(query.trim());
      if (isUid) {
        return service.getPlayerStatsByUid(query.trim(), platform);
      }
      return service.getPlayerStats(query.trim(), platform);
    });

final myPlayerStatsProvider = FutureProvider<ApiResult<PlayerStats?>>((
  ref,
) async {
  final settings = ref.watch(playerSettingsProvider);
  if (!settings.isPlayerSet) return const ApiResult(null);
  return ref
      .watch(playerServiceProvider)
      .getPlayerStatsByUid(settings.uid, settings.platform);
});
