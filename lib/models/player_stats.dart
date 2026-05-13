class PlayerStats {
  final String name;
  final String uid;
  final int level;
  final String rank;
  final int rankScore;
  final String platform;
  final String currentLegend;
  final bool isOnline;
  final bool isInGame;
  final List<Tracker> trackers;
  final int kills;
  final int gamesPlayed;
  final List<LegendStat> legendStats;

  PlayerStats({
    required this.name,
    required this.uid,
    required this.level,
    required this.rank,
    required this.rankScore,
    required this.platform,
    required this.currentLegend,
    required this.isOnline,
    required this.isInGame,
    required this.trackers,
    required this.kills,
    required this.gamesPlayed,
    this.legendStats = const [],
  });

  String get presence =>
      isInGame ? 'In Game' : (isOnline ? 'Online' : 'Offline');

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final global = json['global'] as Map<String, dynamic>? ?? {};
    final legendsBlock = json['legends'] as Map<String, dynamic>? ?? {};
    final selected = legendsBlock['selected'] as Map<String, dynamic>? ?? {};
    final selectedData = selected['data'] as List? ?? [];
    final realtime = json['realtime'] as Map<String, dynamic>? ?? {};

    int kills = 0;
    int gamesPlayed = 0;
    final trackers = <Tracker>[];

    for (final stat in selectedData) {
      final key = stat['key'] as String?;
      final value = (stat['value'] as num?)?.toInt() ?? 0;
      final name = stat['name'] as String? ?? '';
      trackers.add(Tracker(name: name, value: value));
      if (key == 'kills') kills = value;
      if (key == 'games_played') gamesPlayed = value;
    }

    // Parse per-legend stats from legends.all
    final allLegends = legendsBlock['all'] as Map<String, dynamic>? ?? {};
    final legendStats = <LegendStat>[];
    allLegends.forEach((legendName, legendData) {
      if (legendData is! Map<String, dynamic>) return;
      final data = legendData['data'] as List? ?? [];
      final legendTrackers = <LegendTracker>[];
      for (final stat in data) {
        if (stat is! Map) continue;
        final key = stat['key'] as String? ?? '';
        final displayName = stat['name'] as String? ?? key;
        final val = (stat['value'] as num?)?.toInt() ?? 0;
        if (key.isNotEmpty) {
          legendTrackers.add(
            LegendTracker(key: key, displayName: displayName, value: val),
          );
        }
      }
      if (legendTrackers.isNotEmpty) {
        legendStats.add(LegendStat(name: legendName, trackers: legendTrackers));
      }
    });
    legendStats.sort((a, b) => b.killCount.compareTo(a.killCount));

    return PlayerStats(
      name: global['name'] as String? ?? 'Unknown',
      uid: global['uid']?.toString() ?? '',
      level: (global['level'] as num?)?.toInt() ?? 0,
      rank:
          (global['rank'] as Map<String, dynamic>?)?['rankName'] as String? ??
          'Unranked',
      rankScore:
          ((global['rank'] as Map<String, dynamic>?)?['rankScore'] as num?)
              ?.toInt() ??
          0,
      platform: global['platform'] as String? ?? 'Unknown',
      currentLegend: selected['LegendName'] as String? ?? 'Unknown',
      isOnline: ((realtime['isOnline'] as num?)?.toInt() ?? 0) == 1,
      isInGame: ((realtime['isInGame'] as num?)?.toInt() ?? 0) == 1,
      trackers: trackers,
      kills: kills,
      gamesPlayed: gamesPlayed,
      legendStats: legendStats,
    );
  }
}

class Tracker {
  final String name;
  final int value;
  const Tracker({required this.name, required this.value});
}

// ── Per-legend tracker (one stat, e.g. "BR Kills: 6743") ─────────────────────

class LegendTracker {
  final String key;
  final String displayName;
  final int value;

  const LegendTracker({
    required this.key,
    required this.displayName,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': displayName,
    'value': value,
  };

  factory LegendTracker.fromJson(Map<String, dynamic> json) => LegendTracker(
    key: json['key'] as String? ?? '',
    displayName: json['name'] as String? ?? json['key'] as String? ?? '',
    value: (json['value'] as num?)?.toInt() ?? 0,
  );
}

// ── Aggregated stats for one legend ──────────────────────────────────────────

class LegendStat {
  final String name;
  final List<LegendTracker> trackers;

  const LegendStat({required this.name, required this.trackers});

  int get killCount => trackers
      .firstWhere(
        (t) => t.key == 'kills',
        orElse: () => const LegendTracker(key: '', displayName: '', value: 0),
      )
      .value;

  // Update existing tracker values and append any new keys.
  LegendStat merge(LegendStat incoming) {
    final map = <String, LegendTracker>{for (final t in trackers) t.key: t};
    for (final t in incoming.trackers) {
      map[t.key] = t;
    }
    return LegendStat(name: name, trackers: map.values.toList());
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'trackers': trackers.map((t) => t.toJson()).toList(),
  };

  factory LegendStat.fromJson(Map<String, dynamic> json) => LegendStat(
    name: json['name'] as String? ?? '',
    trackers: (json['trackers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LegendTracker.fromJson)
        .toList(),
  );
}

class PlayerUidResult {
  final String name;
  final String uid;
  final String pid;
  final String avatar;

  PlayerUidResult({
    required this.name,
    required this.uid,
    required this.pid,
    required this.avatar,
  });

  factory PlayerUidResult.fromJson(Map<String, dynamic> json) {
    return PlayerUidResult(
      name: json['name'] as String? ?? 'Unknown',
      uid: json['uid']?.toString() ?? '',
      pid: json['pid']?.toString() ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}
