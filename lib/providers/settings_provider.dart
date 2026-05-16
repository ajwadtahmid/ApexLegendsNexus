import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/prefs_keys.dart';

// Track when the app was launched (for showing tips once per session)
final appLaunchTimeProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

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
  final bool notifyPubsMapRotation;
  final bool notifyRankedMapRotation;
  final bool notifyMixtapeMapRotation;
  final int defaultTab; // 0=Home 1=Stats 2=Search 3=Settings
  final bool helpfulTipsEnabled;

  const PlayerSettings({
    this.name = '',
    this.uid = '',
    this.platform = ApiConstants.defaultPlatform,
    this.statsRefreshMinutes = 0,
    this.compactLegendCards = false,
    this.mapNotifyMinutesBefore = 0,
    this.notifyPubsMapRotation = false,
    this.notifyRankedMapRotation = false,
    this.notifyMixtapeMapRotation = false,
    this.defaultTab = 0,
    this.helpfulTipsEnabled = true,
  });

  bool get isPlayerSet => uid.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerSettings &&
          other.name == name &&
          other.uid == uid &&
          other.platform == platform &&
          other.statsRefreshMinutes == statsRefreshMinutes &&
          other.compactLegendCards == compactLegendCards &&
          other.mapNotifyMinutesBefore == mapNotifyMinutesBefore &&
          other.notifyPubsMapRotation == notifyPubsMapRotation &&
          other.notifyRankedMapRotation == notifyRankedMapRotation &&
          other.notifyMixtapeMapRotation == notifyMixtapeMapRotation &&
          other.defaultTab == defaultTab &&
          other.helpfulTipsEnabled == helpfulTipsEnabled;

  @override
  int get hashCode => Object.hash(
    name, uid, platform, statsRefreshMinutes, compactLegendCards,
    mapNotifyMinutesBefore, notifyPubsMapRotation, notifyRankedMapRotation,
    notifyMixtapeMapRotation, defaultTab, helpfulTipsEnabled,
  );

  PlayerSettings copyWith({
    String? name,
    String? uid,
    String? platform,
    int? statsRefreshMinutes,
    bool? compactLegendCards,
    int? mapNotifyMinutesBefore,
    bool? notifyPubsMapRotation,
    bool? notifyRankedMapRotation,
    bool? notifyMixtapeMapRotation,
    int? defaultTab,
    bool? helpfulTipsEnabled,
  }) {
    return PlayerSettings(
      name: name ?? this.name,
      uid: uid ?? this.uid,
      platform: platform ?? this.platform,
      statsRefreshMinutes: statsRefreshMinutes ?? this.statsRefreshMinutes,
      compactLegendCards: compactLegendCards ?? this.compactLegendCards,
      mapNotifyMinutesBefore:
          mapNotifyMinutesBefore ?? this.mapNotifyMinutesBefore,
      notifyPubsMapRotation:
          notifyPubsMapRotation ?? this.notifyPubsMapRotation,
      notifyRankedMapRotation:
          notifyRankedMapRotation ?? this.notifyRankedMapRotation,
      notifyMixtapeMapRotation:
          notifyMixtapeMapRotation ?? this.notifyMixtapeMapRotation,
      defaultTab: defaultTab ?? this.defaultTab,
      helpfulTipsEnabled: helpfulTipsEnabled ?? this.helpfulTipsEnabled,
    );
  }
}

class PlayerSettingsNotifier extends Notifier<PlayerSettings> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  PlayerSettings build() {
    return PlayerSettings(
      name: _prefs.getString(PrefsKeys.playerName) ?? '',
      uid: _prefs.getString(PrefsKeys.playerUid) ?? '',
      platform: _prefs.getString(PrefsKeys.playerPlatform) ?? ApiConstants.defaultPlatform,
      statsRefreshMinutes: _prefs.getInt(PrefsKeys.statsRefreshMinutes) ?? 0,
      compactLegendCards: _prefs.getBool(PrefsKeys.compactLegendCards) ?? false,
      mapNotifyMinutesBefore: _prefs.getInt(PrefsKeys.mapNotifyMinutes) ?? 0,
      notifyPubsMapRotation: _prefs.getBool(PrefsKeys.notifyPubsMapRotation) ?? false,
      notifyRankedMapRotation: _prefs.getBool(PrefsKeys.notifyRankedMapRotation) ?? false,
      notifyMixtapeMapRotation: _prefs.getBool(PrefsKeys.notifyMixtapeMapRotation) ?? false,
      defaultTab: _prefs.getInt(PrefsKeys.defaultTab) ?? 0,
      helpfulTipsEnabled: _prefs.getBool(PrefsKeys.helpfulTipsEnabled) ?? true,
    );
  }

  Future<void> setPlayer(String name, String uid, String platform) async {
    await Future.wait([
      _prefs.setString(PrefsKeys.playerName, name),
      _prefs.setString(PrefsKeys.playerUid, uid),
      _prefs.setString(PrefsKeys.playerPlatform, platform),
    ]);
    state = state.copyWith(name: name, uid: uid, platform: platform);
  }

  Future<void> setStatsRefreshMinutes(int minutes) async {
    await _prefs.setInt(PrefsKeys.statsRefreshMinutes, minutes);
    state = state.copyWith(statsRefreshMinutes: minutes);
  }

  Future<void> setCompactLegendCards(bool compact) async {
    await _prefs.setBool(PrefsKeys.compactLegendCards, compact);
    state = state.copyWith(compactLegendCards: compact);
  }

  Future<void> setMapNotifyMinutesBefore(int minutes) async {
    await _prefs.setInt(PrefsKeys.mapNotifyMinutes, minutes);
    state = state.copyWith(mapNotifyMinutesBefore: minutes);
  }

  Future<void> setNotifyPubsMapRotation(bool notify) async {
    await _prefs.setBool(PrefsKeys.notifyPubsMapRotation, notify);
    state = state.copyWith(notifyPubsMapRotation: notify);
  }

  Future<void> setNotifyRankedMapRotation(bool notify) async {
    await _prefs.setBool(PrefsKeys.notifyRankedMapRotation, notify);
    state = state.copyWith(notifyRankedMapRotation: notify);
  }

  Future<void> setNotifyMixtapeMapRotation(bool notify) async {
    await _prefs.setBool(PrefsKeys.notifyMixtapeMapRotation, notify);
    state = state.copyWith(notifyMixtapeMapRotation: notify);
  }

  Future<void> setDefaultTab(int tab) async {
    await _prefs.setInt(PrefsKeys.defaultTab, tab);
    state = state.copyWith(defaultTab: tab);
  }

  Future<void> setHelpfulTipsEnabled(bool enabled) async {
    await _prefs.setBool(PrefsKeys.helpfulTipsEnabled, enabled);
    state = state.copyWith(helpfulTipsEnabled: enabled);
  }

  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(PrefsKeys.playerName),
      _prefs.remove(PrefsKeys.playerUid),
      _prefs.remove(PrefsKeys.playerPlatform),
    ]);
    state = state.copyWith(name: '', uid: '', platform: ApiConstants.defaultPlatform);
  }
}

final playerSettingsProvider =
    NotifierProvider<PlayerSettingsNotifier, PlayerSettings>(
      PlayerSettingsNotifier.new,
    );

// ── Search state (favorites) ──────────────────────────────────────────────────

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerRef &&
          other.query == query &&
          other.platform == platform &&
          other.uid == uid;

  @override
  int get hashCode => Object.hash(query, platform, uid);
}

class SearchState {
  final List<PlayerRef> favorites;

  const SearchState({this.favorites = const []});

  SearchState copyWith({List<PlayerRef>? favorites}) {
    return SearchState(favorites: favorites ?? this.favorites);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchState) return false;
    if (other.favorites.length != favorites.length) return false;
    for (var i = 0; i < favorites.length; i++) {
      if (other.favorites[i] != favorites[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(favorites);
}

class SearchNotifier extends Notifier<SearchState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SearchState build() {
    return SearchState(favorites: _load(_prefs, PrefsKeys.searchFavorites));
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

  Future<void> _save(String key, List<PlayerRef> list) async {
    await _prefs.setString(key, jsonEncode(list.map((r) => r.toJson()).toList()));
  }

  Future<void> clearFavorites() async {
    await _prefs.remove(PrefsKeys.searchFavorites);
    state = state.copyWith(favorites: []);
  }

  Future<void> toggleFavorite(PlayerRef ref) async {
    final favorites = List<PlayerRef>.from(state.favorites);
    final idx = favorites.indexWhere(
      (f) => f.query == ref.query && f.platform == ref.platform,
    );
    if (idx >= 0) {
      favorites.removeAt(idx);
    } else {
      favorites.insert(0, ref);
    }
    await _save(PrefsKeys.searchFavorites, favorites);
    state = state.copyWith(favorites: favorites);
  }
}

final searchStateProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
