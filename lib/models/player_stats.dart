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
    this.legendStats = const [],
  });

  String get presence =>
      isInGame ? 'In Game' : (isOnline ? 'Online' : 'Offline');

  // Parses int from both numeric and string API responses.
  static int _parseInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // Accepts both numeric (0/1) and boolean API responses.
  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v.toInt() == 1;
    return false;
  }

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final global = json['global'] as Map<String, dynamic>? ?? {};
    final legendsBlock = json['legends'] as Map<String, dynamic>? ?? {};
    final selected = legendsBlock['selected'] as Map<String, dynamic>? ?? {};
    final selectedData = selected['data'] as List? ?? [];
    final realtime = json['realtime'] as Map<String, dynamic>? ?? {};

    final trackers = <Tracker>[];

    for (final stat in selectedData) {
      if (stat is! Map) continue;
      final name = stat['name'] as String? ?? '';
      final value = _parseInt(stat['value']);
      trackers.add(Tracker(name: name, value: value));
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
        final val = _parseInt(stat['value']);
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
      level: _parseInt(global['level']),
      rank:
          (global['rank'] as Map<String, dynamic>?)?['rankName'] as String? ??
          'Unranked',
      rankScore:
          _parseInt((global['rank'] as Map<String, dynamic>?)?['rankScore']),
      platform: global['platform'] as String? ?? 'Unknown',
      currentLegend: selected['LegendName'] as String? ?? 'Unknown',
      isOnline: _parseBool(realtime['isOnline']),
      isInGame: _parseBool(realtime['isInGame']),
      trackers: trackers,
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

  int get killCount {
    for (final t in trackers) {
      if (t.key == 'kills') return t.value;
    }
    return 0;
  }

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
  final String platformId;
  final String avatar;

  PlayerUidResult({
    required this.name,
    required this.uid,
    required this.platformId,
    required this.avatar,
  });

  factory PlayerUidResult.fromJson(Map<String, dynamic> json) {
    return PlayerUidResult(
      name: json['name'] as String? ?? 'Unknown',
      uid: json['uid']?.toString() ?? '',
      platformId: json['pid']?.toString() ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }
}
