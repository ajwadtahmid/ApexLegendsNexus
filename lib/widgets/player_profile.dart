import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../constants/legend_constants.dart';
import '../constants/rank_constants.dart';
import '../models/player_stats.dart';
import '../providers/predator_provider.dart';
import '../utils/format.dart';
import '../utils/theme.dart';
import 'status_dot.dart';

// ── Player info card ──────────────────────────────────────────────────────────

class PlayerInfoCard extends StatelessWidget {
  final PlayerStats stats;
  final int? rpDelta;
  const PlayerInfoCard({super.key, required this.stats, this.rpDelta});

  @override
  Widget build(BuildContext context) {
    final delta = rpDelta;
    final showDelta = delta != null && delta != 0;
    final deltaColor = (delta ?? 0) >= 0 ? AppTheme.green : AppTheme.red;
    final deltaText = (delta ?? 0) >= 0
        ? '+$delta RP last 24h'
        : '$delta RP last 24h';

    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.accent.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusDot(
                color: AppTheme.statusColor(
                  stats.isInGame ? 'UP' : (stats.isOnline ? 'SLOW' : 'DOWN'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stats.presence,
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level ${stats.level}  •  ${stats.rank}  •  ${fmtRp(stats.rankScore)} RP',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
              ),
              if (showDelta) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    deltaText,
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Playing: ${stats.currentLegend}',
            style: const TextStyle(color: AppTheme.accent2, fontSize: 13),
          ),
          const SizedBox(height: AppTheme.md),
          if (stats.trackers.isNotEmpty)
            ...stats.trackers
                .take(3)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          fmtRp(t.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
          else
            const Text(
              'No trackers equipped',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

// ── Ranked info card ──────────────────────────────────────────────────────────

class RankedInfoCard extends ConsumerWidget {
  final int myRp;
  final String platform;
  const RankedInfoCard({super.key, required this.myRp, required this.platform});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predAsync = ref.watch(predatorProvider);
    final predVal = predAsync.when(
      data: (result) => result.data.forPlatform(platform)?.minRp,
      loading: () => null,
      error: (e, _) => null,
    );

    final isPred = predVal != null && myRp >= predVal;
    final idx = rankIdx(myRp);
    final current = kRankLadder[idx];
    final currentColor = isPred ? kPredatorColor : current.color;
    final currentLabel = isPred ? kApexPredatorRank : current.label;

    int? nextRp;
    String? nextLabel;
    if (!isPred) {
      if (idx < kRankLadder.length - 1) {
        nextRp = kRankLadder[idx + 1].rp;
        nextLabel = kRankLadder[idx + 1].label;
      } else if (predVal != null) {
        nextRp = predVal;
        nextLabel = kApexPredatorRank;
      }
    }

    final curRp = current.rp;
    final progress = nextRp != null && nextRp > curRp
        ? ((myRp - curRp) / (nextRp - curRp)).clamp(0.0, 1.0)
        : 1.0;
    final gap = nextRp != null ? (nextRp - myRp).clamp(0, nextRp) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ranked',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.sm),
        Container(
          padding: const EdgeInsets.all(AppTheme.md),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: currentColor.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: currentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        isPred ? 'PR' : (current.div ?? 'M'),
                        style: TextStyle(
                          color: currentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLabel,
                        style: TextStyle(
                          color: currentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${fmtRp(myRp)} RP',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isPred && nextRp != null) ...[
                const SizedBox(height: AppTheme.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.surface2,
                    color: currentColor,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${fmtRp(curRp)} RP',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '$gap RP to $nextLabel',
                      style: TextStyle(
                        color: currentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${fmtRp(nextRp)} RP',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ] else if (isPred)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.sm),
                  child: Text(
                    'Top 750 on ${ApiConstants.platformLabels[platform] ?? platform}',
                    style: const TextStyle(color: kPredatorColor, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Legend stats section ──────────────────────────────────────────────────────

class LegendStatsSection extends StatelessWidget {
  final List<LegendStat> legends;
  final bool compact;
  const LegendStatsSection({
    super.key,
    required this.legends,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Legend Stats',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.sm),
        if (compact)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: legends.asMap().entries.map((entry) {
                final l = entry.value;
                final isLast = entry.key == legends.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.md,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            l.killCount > 0
                                ? '${fmtRp(l.killCount)} kills'
                                : 'No kills',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        color: AppTheme.surface2,
                        height: 1,
                        indent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          )
        else
          ...legends.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.sm),
              child: _LegendCard(legend: l),
            ),
          ),
      ],
    );
  }
}

class _LegendCard extends StatelessWidget {
  final LegendStat legend;
  const _LegendCard({required this.legend});

  String get _imageKey => legend.name.toLowerCase().replaceAll(' ', '_');

  Color _roleColor(LegendRole role) => switch (role) {
    LegendRole.assault => const Color(0xFFEF5350),
    LegendRole.controller => const Color(0xFF42A5F5),
    LegendRole.recon => const Color(0xFF26C6DA),
    LegendRole.skirmisher => const Color(0xFFAB47BC),
    LegendRole.support => const Color(0xFF66BB6A),
  };

  @override
  Widget build(BuildContext context) {
    final info = kLegendsByName[legend.name.toLowerCase()];

    // Deduplicate trackers by display name, keeping the highest value.
    // The API can return the same stat under different keys (e.g. "kills"
    // and "br_kills" both labelled "BR Kills") — show only the latest one.
    final deduped = <String, LegendTracker>{};
    for (final t in legend.trackers) {
      final key = t.displayName.toLowerCase();
      if (!deduped.containsKey(key) || t.value > deduped[key]!.value) {
        deduped[key] = t;
      }
    }
    final trackers = deduped.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 100,
              child: Image.asset(
                'assets/legends/$_imageKey.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (ctx, err, trace) => Image.asset(
                  'assets/legends/placeholder.png',
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, trace) => Container(
                    color: AppTheme.surface2,
                    child: Center(
                      child: Text(
                        legend.name.isNotEmpty ? legend.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            legend.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (info != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _roleColor(info.role).withAlpha(35),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: Text(
                              info.role.displayName,
                              style: TextStyle(
                                color: _roleColor(info.role),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: trackers
                            .map((t) => _StatTile(tracker: t))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final LegendTracker tracker;
  const _StatTile({required this.tracker});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tracker.displayName,
            style: const TextStyle(color: AppTheme.muted, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            fmtRp(tracker.value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
