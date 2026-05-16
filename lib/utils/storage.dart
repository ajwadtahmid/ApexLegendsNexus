import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/prefs_keys.dart';
import '../models/player_stats.dart';

// ── Stat snapshots (RP history for graph) ─────────────────────────────────────

class StatSnapshot {
  final DateTime timestamp;
  final int rp;

  const StatSnapshot({required this.timestamp, required this.rp});

  Map<String, dynamic> toJson() => {
    'ts': timestamp.millisecondsSinceEpoch,
    'rp': rp,
  };

  factory StatSnapshot.fromJson(Map<String, dynamic> json) => StatSnapshot(
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['ts'] as int),
    rp: json['rp'] as int,
  );
}

const _minSnapshotIntervalMinutes = 30;
const _maxSnapshots = 30;

String _snapshotKeyFor(String? uid) =>
    (uid != null && uid.isNotEmpty) ? 'stat_snapshots_$uid' : 'stat_snapshots';

List<StatSnapshot> _parseSnapshots(String? raw) {
  try {
    final list = jsonDecode(raw ?? '[]') as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(StatSnapshot.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

Future<List<StatSnapshot>> loadSnapshots({String? uid}) async {
  final prefs = await SharedPreferences.getInstance();
  return _parseSnapshots(prefs.getString(_snapshotKeyFor(uid)));
}

Future<void> appendSnapshot(
  PlayerStats stats, {
  String? uid,
  bool deduplicateRp = true,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final snapshots = _parseSnapshots(prefs.getString(_snapshotKeyFor(uid)));
  final now = DateTime.now();

  if (snapshots.isNotEmpty) {
    final diff = now.difference(snapshots.last.timestamp).inMinutes;
    if (diff < _minSnapshotIntervalMinutes) return;
    if (deduplicateRp && snapshots.last.rp == stats.rankScore) return;
  }

  snapshots.add(StatSnapshot(timestamp: now, rp: stats.rankScore));

  final trimmed = snapshots.length > _maxSnapshots
      ? snapshots.sublist(snapshots.length - _maxSnapshots)
      : snapshots;

  await prefs.setString(
    _snapshotKeyFor(uid),
    jsonEncode(trimmed.map((s) => s.toJson()).toList()),
  );
}

/// Returns the RP gained over the last 24 hours.
/// Uses the most recent snapshot from 24+ hours ago as baseline; falls back
/// to the first available snapshot if all data is within the last 24 hours.
int? computeDelta(List<StatSnapshot> snaps, int currentRp) {
  if (snaps.isEmpty) return null;
  final last24Hours = DateTime.now().subtract(const Duration(hours: 24));
  final before24h = snaps.where((s) => s.timestamp.isBefore(last24Hours)).toList();
  if (before24h.isNotEmpty) return currentRp - before24h.last.rp;
  return currentRp - snaps.first.rp;
}

// ── Legend stats persistence (merge on each API refresh) ──────────────────────

List<LegendStat> _parseLegendStats(String? raw) {
  try {
    final list = jsonDecode(raw ?? '[]') as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(LegendStat.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

Future<List<LegendStat>> loadLegendStats() async {
  final prefs = await SharedPreferences.getInstance();
  return _parseLegendStats(prefs.getString(PrefsKeys.legendStats));
}

// Merges incoming legend data into stored data:
// - existing legend + existing tracker → update value
// - existing legend + new tracker → append tracker
// - new legend → add it
Future<List<LegendStat>> mergeLegendStats(List<LegendStat> incoming) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = _parseLegendStats(prefs.getString(PrefsKeys.legendStats));

  if (incoming.isEmpty) return stored;

  final map = <String, LegendStat>{for (final s in stored) s.name: s};
  for (final legend in incoming) {
    final existing = map[legend.name];
    map[legend.name] = existing != null ? existing.merge(legend) : legend;
  }

  final merged = map.values.toList()
    ..sort((a, b) => b.killCount.compareTo(a.killCount));

  await prefs.setString(
    PrefsKeys.legendStats,
    jsonEncode(merged.map((s) => s.toJson()).toList()),
  );
  return merged;
}
