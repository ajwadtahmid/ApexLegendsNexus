import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main',
  );
});

// ── Player settings ───────────────────────────────────────────────────────────

class PlayerSettings {
  final String name;
  final String uid;
  final String platform;
  final int statsRefreshMinutes; // 0 = manual only
  final bool compactLegendCards;
  final int mapNotifyMinutesBefore; // 0 = off, else minutes before rotation
  final int defaultTab; // 0=Home 1=Stats 2=Search 3=Settings

  const PlayerSettings({
    this.name = '',
    this.uid = '',
    this.platform = ApiConstants.defaultPlatform,
    this.statsRefreshMinutes = 0,
    this.compactLegendCards = false,
    this.mapNotifyMinutesBefore = 0,
    this.defaultTab = 0,
  });

  bool get isPlayerSet => uid.isNotEmpty;

  PlayerSettings copyWith({
    String? name,
    String? uid,
    String? platform,
    int? statsRefreshMinutes,
    bool? compactLegendCards,
    int? mapNotifyMinutesBefore,
    int? defaultTab,
  }) {
    return PlayerSettings(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      platform: platform ?? this.platform,
      statsRefreshMinutes: statsRefreshMinutes ?? this.statsRefreshMinutes,
      compactLegendCards: compactLegendCards ?? this.compactLegendCards,
      mapNotifyMinutesBefore:
          mapNotifyMinutesBefore ?? this.mapNotifyMinutesBefore,
      defaultTab: defaultTab ?? this.defaultTab,
    );
  }
}

class PlayerSettingsNotifier extends Notifier<PlayerSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  PlayerSettings build() {
    return PlayerSettings(
      name: _prefs.getString('player_name') ?? '',
      uid: _prefs.getString('player_uid') ?? '',
      platform: _prefs.getString('player_platform') ?? ApiConstants.defaultPlatform,
      statsRefreshMinutes: _prefs.getInt('stats_refresh_minutes') ?? 0,
      compactLegendCards: _prefs.getBool('compact_legend_cards') ?? false,
      mapNotifyMinutesBefore: _prefs.getInt('map_notify_minutes') ?? 0,
      defaultTab: _prefs.getInt('default_tab') ?? 0,
    );
  }

  Future<void> setPlayer(String name, String uid, String platform) async {
    await Future.wait([
      _prefs.setString('player_name', name),
      _prefs.setString('player_uid', uid),
      _prefs.setString('player_platform', platform),
    ]);
    state = state.copyWith(name: name, uid: uid, platform: platform);
  }

  void setStatsRefreshMinutes(int minutes) {
    _prefs.setInt('stats_refresh_minutes', minutes);
    state = state.copyWith(statsRefreshMinutes: minutes);
  }

  void setCompactLegendCards(bool compact) {
    _prefs.setBool('compact_legend_cards', compact);
    state = state.copyWith(compactLegendCards: compact);
  }

  void setMapNotifyMinutesBefore(int minutes) {
    _prefs.setInt('map_notify_minutes', minutes);
    state = state.copyWith(mapNotifyMinutesBefore: minutes);
  }

  void setDefaultTab(int tab) {
    _prefs.setInt('default_tab', tab);
    state = state.copyWith(defaultTab: tab);
  }

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove('player_name'),
      _prefs.remove('player_uid'),
      _prefs.remove('player_platform'),
    ]);
    state = state.copyWith(name: '', uid: '', platform: ApiConstants.defaultPlatform);
  }
}

final playerSettingsProvider =
    NotifierProvider<PlayerSettingsNotifier, PlayerSettings>(
      PlayerSettingsNotifier.new,
    );

// ── Search state (recents + favorites) ───────────────────────────────────────

class PlayerRef {
  final String query;
  final String platform;
  final String? uid;

  const PlayerRef({required this.query, required this.platform, this.uid});

  Map<String, dynamic> toJson() => {
    'query': query,
    'platform': platform,
    'uid': uid,
  };

  factory PlayerRef.fromJson(Map<String, dynamic> json) => PlayerRef(
    query: json['query'] as String? ?? '',
    platform: json['platform'] as String? ?? 'PC',
    uid: json['uid'] as String?,
  );
}

class SearchState {
  final List<PlayerRef> favorites;

  const SearchState({this.favorites = const []});

  SearchState copyWith({List<PlayerRef>? favorites}) {
    return SearchState(favorites: favorites ?? this.favorites);
  }
}

class SearchNotifier extends Notifier<SearchState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SearchState build() {
    return SearchState(favorites: _load(_prefs, 'search_favorites'));
  }

  static List<PlayerRef> _load(SharedPreferences prefs, String key) {
    try {
      final raw = prefs.getString(key) ?? '[]';
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(PlayerRef.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _save(String key, List<PlayerRef> list) {
    _prefs.setString(key, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  void clearFavorites() {
    _prefs.remove('search_favorites');
    state = state.copyWith(favorites: []);
  }

  void toggleFavorite(PlayerRef ref) {
    final favorites = List<PlayerRef>.from(state.favorites);
    final idx = favorites.indexWhere(
      (f) => f.query == ref.query && f.platform == ref.platform,
    );
    if (idx >= 0) {
      favorites.removeAt(idx);
    } else {
      favorites.insert(0, ref);
    }
    _save('search_favorites', favorites);
    state = state.copyWith(favorites: favorites);
  }
}

final searchStateProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
