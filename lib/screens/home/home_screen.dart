import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/map_rotation.dart';
import '../../models/predator.dart';
import '../../models/server_status.dart';
import '../../models/news_article.dart';
import '../../providers/map_provider.dart';
import '../../providers/predator_provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../constants/api_constants.dart';
import '../../utils/format.dart' show formatNumber, timeAgo;
import '../../utils/theme.dart';
import '../../utils/error_messages.dart';
import '../../widgets/shimmer.dart';
import '../../widgets/status_dot.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _modeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(playerSettingsProvider);
    final mapAsync = ref.watch(mapRotationProvider);
    final serverAsync = ref.watch(serverStatusProvider);
    final newsAsync = ref.watch(newsProvider);
    final predatorAsync = ref.watch(predatorProvider);
    final playerName = settings.name.isNotEmpty ? settings.name : 'Guest';

    ref.listen(mapRotationProvider, (_, next) {
      next.whenData((result) => _scheduleNotifications(ref, result.data));
    });

    ref.listen(playerSettingsProvider, (prev, next) {
      final changed =
          prev?.mapNotifyMinutesBefore != next.mapNotifyMinutesBefore ||
          prev?.notifyPubsMapRotation != next.notifyPubsMapRotation ||
          prev?.notifyRankedMapRotation != next.notifyRankedMapRotation ||
          prev?.notifyMixtapeMapRotation != next.notifyMixtapeMapRotation;
      if (!changed) return;
      ref
          .read(mapRotationProvider)
          .whenData((result) => _scheduleNotifications(ref, result.data));
    });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: () async {
            ref.invalidate(mapRotationProvider);
            ref.invalidate(serverStatusProvider);
            ref.invalidate(newsProvider);
            ref.invalidate(predatorProvider);
            await Future.wait([
              ref
                  .read(mapRotationProvider.future)
                  .then((_) {}, onError: (_) {}),
              ref
                  .read(serverStatusProvider.future)
                  .then((_) {}, onError: (_) {}),
              ref.read(newsProvider.future).then((_) {}, onError: (_) {}),
              ref.read(predatorProvider.future).then((_) {}, onError: (_) {}),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.md,
              AppTheme.lg,
              AppTheme.md,
              AppTheme.lg,
            ),
            children: [
              // ── Header ──────────────────────────────────────────
              _Header(playerName: playerName),
              const SizedBox(height: AppTheme.xl),

              // ── Map rotation ─────────────────────────────────────
              mapAsync.when(
                data: (result) {
                  final modes = _buildModes(result.data);
                  final idx = _modeIndex.clamp(0, modes.length - 1);
                  return Column(
                    children: [
                      _ModePicker(
                        modes: modes.map((m) => m.label).toList(),
                        selected: idx,
                        onSelect: (i) => setState(() => _modeIndex = i),
                      ),
                      const SizedBox(height: AppTheme.md),
                      _MapCard(mode: modes[idx]),
                    ],
                  );
                },
                loading: () => const _MapCardSkeleton(),
                error: (e, _) => _InlineError(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(mapRotationProvider),
                ),
              ),
              const SizedBox(height: AppTheme.md),

              // ── Predator cutoff ──────────────────────────────────
              predatorAsync.when(
                data: (result) => _PredatorSummaryCard(
                  data: result.data,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _PredatorPage(data: result.data),
                    ),
                  ),
                ),
                loading: () => const _SummaryTileSkeleton(),
                error: (e, _) => _SummaryErrorCard(
                  title: 'Pred Cutoff',
                  onRetry: () => ref.invalidate(predatorProvider),
                ),
              ),
              const SizedBox(height: AppTheme.sm),

              // ── News summary ─────────────────────────────────────
              newsAsync.when(
                data: (result) => _NewsSummaryCard(
                  articles: result.data,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _NewsPage(articles: result.data),
                    ),
                  ),
                ),
                loading: () => const _SummaryTileSkeleton(),
                error: (e, _) => _SummaryErrorCard(
                  title: 'Latest News',
                  onRetry: () => ref.invalidate(newsProvider),
                ),
              ),
              const SizedBox(height: AppTheme.sm),

              // ── Server status summary ────────────────────────────
              serverAsync.when(
                data: (result) => _ServerSummaryCard(
                  status: result.data,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ServerStatusPage(status: result.data),
                    ),
                  ),
                ),
                loading: () => const _SummaryTileSkeleton(),
                error: (e, _) => _SummaryErrorCard(
                  title: 'Server Status',
                  onRetry: () => ref.invalidate(serverStatusProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleNotifications(WidgetRef ref, MapRotation data) {
    final s = ref.read(playerSettingsProvider);
    if (s.mapNotifyMinutesBefore > 0) {
      NotificationService.scheduleAll(
        data,
        s.mapNotifyMinutesBefore,
        notifyRanked: s.notifyRankedMapRotation,
        notifyPubs: s.notifyPubsMapRotation,
        notifyMixtape: s.notifyMixtapeMapRotation,
      );
    } else {
      NotificationService.cancelAll();
    }
  }

  List<_ModeData> _buildModes(MapRotation r) => [
    _ModeData(label: 'Ranked', current: r.rankedCurrent, next: r.rankedNext),
    _ModeData(
      label: 'Pubs',
      current: r.battleRoyaleCurrent,
      next: r.battleRoyaleNext,
    ),
    if (r.ltmCurrent != null)
      _ModeData(label: 'Mixtape', current: r.ltmCurrent!, next: r.ltmNext),
  ];
}

class _ModeData {
  final String label;
  final MapMode current;
  final MapMode? next;
  const _ModeData({required this.label, required this.current, this.next});
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String playerName;
  const _Header({required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WELCOME',
          style: TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          playerName,
          style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ── Mode picker ───────────────────────────────────────────────────────────────

class _ModePicker extends StatelessWidget {
  final List<String> modes;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ModePicker({
    required this.modes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: List.generate(modes.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppTheme.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  modes[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.muted,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Map card ──────────────────────────────────────────────────────────────────

class _MapCard extends StatefulWidget {
  final _ModeData mode;
  const _MapCard({required this.mode});

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard> {
  late int _remaining;
  late DateTime _startedAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reset(widget.mode.current.remainingSecs);
  }

  @override
  void didUpdateWidget(_MapCard old) {
    super.didUpdateWidget(old);
    if (old.mode.label != widget.mode.label ||
        old.mode.current.map != widget.mode.current.map ||
        old.mode.current.remainingSecs != widget.mode.current.remainingSecs) {
      _reset(widget.mode.current.remainingSecs);
    }
  }

  void _reset(int secs) {
    _timer?.cancel();
    _remaining = secs;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(_startedAt).inSeconds;
      final newRemaining = (secs - elapsed).clamp(0, secs);
      setState(() => _remaining = newRemaining);
      if (newRemaining == 0) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatEndTime(int remainingSecs) {
    final end = DateTime.now().add(Duration(seconds: remainingSecs));
    return DateFormat('h:mm a').format(end);
  }

  String _formatMapDisplay(String mapName, String? eventName, bool isMixtape) {
    if (isMixtape && eventName != null && eventName.isNotEmpty) {
      return '$mapName - $eventName';
    }
    return mapName;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.mode.current;
    final next = widget.mode.next;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          SizedBox(
            height: 180,
            width: double.infinity,
            child: current.asset.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: current.asset,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: AppTheme.surface2,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: AppTheme.surface2,
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppTheme.muted,
                          size: 48,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surface2,
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        color: AppTheme.muted,
                        size: 48,
                      ),
                    ),
                  ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(AppTheme.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode.label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMapDisplay(
                    current.map,
                    current.eventName,
                    widget.mode.label == 'Mixtape',
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: AppTheme.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatCountdown(_remaining)} remaining',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppTheme.surface2, height: 1),
                const SizedBox(height: 10),
                if (next != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'UP NEXT',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Starts at ${_formatEndTime(_remaining)}',
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '→  ${_formatMapDisplay(next.map, next.eventName, widget.mode.label == 'Mixtape')}',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                ] else
                  const Text(
                    'No next map info',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Server status summary card ────────────────────────────────────────────────

class _ServerSummaryCard extends StatelessWidget {
  final ServerStatus status;
  final VoidCallback onTap;

  const _ServerSummaryCard({required this.status, required this.onTap});

  static const _priorityKeys = {
    'Origin_login',
    'EA_novafusion',
    'EA_accounts',
    'ApexOauth_Crossplay',
  };

  String get _level {
    final priority = status.services.entries
        .where((e) => _priorityKeys.contains(e.key))
        .map((e) => e.value.overallStatus)
        .toList();
    if (priority.isEmpty) return 'UP';
    final downCount = priority.where((s) => s == 'DOWN').length;
    final slowCount = priority.where((s) => s == 'SLOW').length;
    if (downCount >= 2) return 'DOWN';
    if (downCount >= 1 || slowCount >= 1) return 'PARTIAL';
    return 'UP';
  }

  Color get _statusColor => switch (_level) {
    'DOWN' => AppTheme.red,
    'PARTIAL' => AppTheme.orange,
    _ => AppTheme.green,
  };

  String get _subtitle => switch (_level) {
    'DOWN' => 'Major outage',
    'PARTIAL' => 'Partial outage',
    _ => 'All systems operational',
  };

  @override
  Widget build(BuildContext context) {
    return _SummaryTile(
      leading: StatusDot(color: _statusColor),
      title: 'Server Status',
      subtitle: _subtitle,
      onTap: onTap,
    );
  }
}

// ── News summary card ─────────────────────────────────────────────────────────

class _NewsSummaryCard extends StatelessWidget {
  final List<NewsArticle> articles;
  final VoidCallback onTap;

  const _NewsSummaryCard({required this.articles, required this.onTap});

  String get _subtitle {
    if (articles.isEmpty) return 'No recent updates';
    return articles.first.title.isNotEmpty
        ? articles.first.title
        : '${articles.length} article${articles.length == 1 ? "" : "s"}';
  }

  @override
  Widget build(BuildContext context) {
    return _SummaryTile(
      leading: const Icon(
        Icons.newspaper_outlined,
        color: AppTheme.accent,
        size: 22,
      ),
      title: 'Latest News',
      subtitle: _subtitle,
      onTap: onTap,
    );
  }
}

// ── Shared summary tile ───────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Center(child: leading)),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton widgets ──────────────────────────────────────────────────────────

class _MapCardSkeleton extends StatelessWidget {
  const _MapCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(height: 180, borderRadius: BorderRadius.zero),
            Padding(
              padding: const EdgeInsets.all(AppTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 60, height: 14),
                  const SizedBox(height: 4),
                  const ShimmerBox(width: 180, height: 29),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const ShimmerBox(width: 140, height: 17),
                      const Spacer(),
                      ShimmerBox(
                        width: 90,
                        height: 17,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppTheme.surface2, height: 1),
                  const SizedBox(height: 10),
                  const ShimmerBox(width: 50, height: 12),
                  const SizedBox(height: 4),
                  const ShimmerBox(width: 160, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTileSkeleton extends StatelessWidget {
  const _SummaryTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            const ShimmerBox(
              width: 28,
              height: 28,
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 110, height: 18),
                  SizedBox(height: 2),
                  ShimmerBox(width: 170, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.orange,
            size: 32,
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryErrorCard extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;
  const _SummaryErrorCard({required this.title, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_outlined,
              color: AppTheme.orange,
              size: 22,
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    'Failed to load',
                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppTheme.accent, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Predator cutoff summary card ──────────────────────────────────────────────

class _PredatorSummaryCard extends StatelessWidget {
  final PredatorResponse data;
  final VoidCallback onTap;

  const _PredatorSummaryCard({required this.data, required this.onTap});

  String get _subtitle {
    final count = data.rp.values.fold(0, (s, p) => s + p.totalMastersAndPreds);
    return '$count Masters & Preds across all platforms';
  }

  @override
  Widget build(BuildContext context) {
    return _SummaryTile(
      leading: const FaIcon(
        FontAwesomeIcons.skull,
        color: AppTheme.accent,
        size: 20,
      ),
      title: 'Pred Cutoff',
      subtitle: _subtitle,
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Predator cutoff detail page (pushed from home)
// ═══════════════════════════════════════════════════════════════════════════════

class _PredatorPage extends StatelessWidget {
  final PredatorResponse data;
  const _PredatorPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = ApiConstants.platforms
        .map((key) => (key, ApiConstants.platformLabels[key]!, data.forPlatform(key)))
        .where((e) => e.$3 != null)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pred Cutoff')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.md),
        children: [
          ...entries.map((e) => _PlatformCard(platformKey: e.$1, name: e.$2, info: e.$3!)),
          const SizedBox(height: AppTheme.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.sm),
            child: Text(
              'All Masters have a hidden ladder ranking that is only displayed when being a Predator (you can still see it on the website on your profile page). The total amount of masters is guessed using the highest ranking found in the ALS database. The number found is very likely to be under-estimated, as all masters players are not in the ALS database. However, if the last master is in our database, the ranking will be 100% accurate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String platformKey;
  final String name;
  final PlatformPredator info;

  const _PlatformCard({
    required this.platformKey,
    required this.name,
    required this.info,
  });

  static Widget _icon(String platformKey) => switch (platformKey) {
    'PS4' => const FaIcon(FontAwesomeIcons.playstation, color: AppTheme.blue, size: 16),
    'X1'  => const FaIcon(FontAwesomeIcons.xbox, color: AppTheme.green, size: 16),
    'SWITCH' => const FaIcon(FontAwesomeIcons.gamepad, color: AppTheme.red, size: 16),
    _ => const FaIcon(FontAwesomeIcons.desktop, color: AppTheme.muted, size: 16),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sm),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _icon(platformKey),
              const SizedBox(width: AppTheme.xs),
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                info.updatedAt != null ? timeAgo(info.updatedAt!) : '—',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatNumber(info.minRp),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'RP',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatNumber(info.totalMastersAndPreds)} Masters + Preds',
            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

Color _latencyColor(int ms) {
  if (ms < 50) return AppTheme.green;
  if (ms < 200) return AppTheme.orange;
  return AppTheme.red;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Server Status detail page (pushed from home)
// ═══════════════════════════════════════════════════════════════════════════════

class _ServerStatusPage extends StatelessWidget {
  final ServerStatus status;
  const _ServerStatusPage({required this.status});

  @override
  Widget build(BuildContext context) {
    final services = status.services.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Server Status')),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.md),
        itemCount: services.length + 1,
        itemBuilder: (context, i) {
          if (i == services.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://apexlegendsstatus.com'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  'Data from apexlegendsstatus.com',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.blue,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            );
          }
          final svc = services[i];
          final color = AppTheme.statusColor(svc.overallStatus);
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.sm),
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusDot(color: color),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      svc.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        svc.overallStatus,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (svc.regions.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.sm),
                  Wrap(
                    spacing: AppTheme.sm,
                    runSpacing: 4,
                    children: svc.regions.entries.map((e) {
                      final rc = _latencyColor(e.value.responseTime);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusDot(color: rc, size: 6),
                          const SizedBox(width: 4),
                          Text(
                            '${e.key}  ${e.value.responseTime}ms',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// News detail page (pushed from home)
// ═══════════════════════════════════════════════════════════════════════════════

class _NewsPage extends StatelessWidget {
  final List<NewsArticle> articles;
  const _NewsPage({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latest News')),
      body: articles.isEmpty
          ? const Center(
              child: Text(
                'No news right now.',
                style: TextStyle(color: AppTheme.muted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTheme.md),
              itemCount: articles.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppTheme.sm),
              itemBuilder: (context, i) {
                final a = articles[i];
                return Material(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: () async {
                      if (a.link.isNotEmpty) {
                        final uri = Uri.tryParse(a.link);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (a.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusMd),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: a.imageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Container(
                                height: 160,
                                color: AppTheme.surface2,
                              ),
                              errorWidget: (ctx, url, err) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(AppTheme.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (a.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  a.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              if (a.link.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'Read more →',
                                  style: TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
