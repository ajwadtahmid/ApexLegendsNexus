import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/api_constants.dart';
import '../../constants/rank_constants.dart';
import '../../models/player_stats.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/error_messages.dart';
import '../../utils/format.dart';
import '../../utils/storage.dart';
import '../../utils/uid_search.dart';
import '../../utils/theme.dart';
import '../../widgets/graph_card.dart';
import '../../widgets/platform_picker.dart';
import '../../widgets/player_profile.dart';
import '../../widgets/stale_banner.dart';
import '../../widgets/status_dot.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _platform = ApiConstants.defaultPlatform;
  bool _searchByUid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleUidSearch(bool value) async {
    if (value && !_searchByUid) {
      await showUidWarningIfNeeded(context, ref);
    }
    if (mounted) setState(() => _searchByUid = value);
  }

  void _search([String? query, String? platform]) {
    final q = (query ?? _controller.text).trim();
    if (q.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PlayerResultPage(query: q, platform: platform ?? _platform, searchByUid: _searchByUid),
      ),
    );
  }

  void _pickFavorite(PlayerRef fav) {
    _controller.text = fav.query;
    setState(() => _platform = fav.platform);
    _search(fav.query, fav.platform);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          _SearchBar(
            controller: _controller,
            platform: _platform,
            searchByUid: _searchByUid,
            onPlatformChanged: (p) => setState(() => _platform = p),
            onSearchByUidChanged: _toggleUidSearch,
            onSearch: _search,
          ),
          Expanded(child: _FavoritesPane(onPick: _pickFavorite)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String platform;
  final bool searchByUid;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<bool> onSearchByUidChanged;
  final VoidCallback onSearch;

  const _SearchBar({
    required this.controller,
    required this.platform,
    required this.searchByUid,
    required this.onPlatformChanged,
    required this.onSearchByUidChanged,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.md,
        AppTheme.sm,
        AppTheme.md,
        AppTheme.md,
      ),
      color: AppTheme.surface,
      child: Column(
        children: [
          TextField(
            controller: controller,
            onSubmitted: (_) => onSearch(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Name or UID…',
              prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: AppTheme.accent),
                onPressed: onSearch,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          PlatformPicker(selected: platform, onChanged: onPlatformChanged),
          const SizedBox(height: AppTheme.sm),
          Row(
            children: [
              const Icon(Icons.numbers, size: 16, color: AppTheme.muted),
              const SizedBox(width: AppTheme.sm),
              const Expanded(
                child: Text(
                  'Search by UID',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ),
              Switch(
                value: searchByUid,
                onChanged: onSearchByUidChanged,
                activeThumbColor: AppTheme.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Player result page ────────────────────────────────────────────────────────

class _PlayerResultPage extends ConsumerStatefulWidget {
  final String query;
  final String platform;
  final bool searchByUid;

  const _PlayerResultPage({
    required this.query,
    required this.platform,
    this.searchByUid = false,
  });

  @override
  ConsumerState<_PlayerResultPage> createState() => _PlayerResultPageState();
}

class _PlayerResultPageState extends ConsumerState<_PlayerResultPage> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    ref.invalidate(
      searchPlayerProvider((widget.query, widget.platform, widget.searchByUid)),
    );
    try {
      await ref.read(
        searchPlayerProvider(
          (widget.query, widget.platform, widget.searchByUid),
        ).future,
      );
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(
      searchPlayerProvider(
        (widget.query, widget.platform, widget.searchByUid),
      ),
    );
    final stats = statsAsync.whenOrNull(data: (result) => result.data);
    final favorites = ref.watch(searchStateProvider).favorites;
    final isFav = favorites.any(
      (f) => f.query == widget.query && f.platform == widget.platform,
    );
    final myStats = ref
        .watch(myPlayerStatsProvider)
        .whenOrNull(data: (result) => result.data);
    final canCompare =
        stats != null &&
        myStats != null &&
        myStats.uid.isNotEmpty &&
        myStats.uid != stats.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(stats?.name ?? widget.query),
        actions: [
          if (canCompare)
            TextButton.icon(
              onPressed: () => _showComparePicker(context, myStats, stats),
              icon: const Icon(Icons.compare_arrows, size: 16),
              label: const Text('Compare'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            ),
          if (stats != null)
            IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? AppTheme.accent : AppTheme.muted,
              ),
              onPressed: () {
                ref
                    .read(searchStateProvider.notifier)
                    .toggleFavorite(
                      PlayerRef(
                        query: widget.query,
                        platform: widget.platform,
                        uid: stats.uid,
                      ),
                    );
              },
            ),
          _refreshing
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
        ],
      ),
      body: statsAsync.when(
        data: (result) => _PlayerResultBody(
          stats: result.data,
          staleAt: result.staleAt,
          onRefresh: _refresh,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
        error: (e, _) => _SearchError(
          message: friendlyError(e),
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showComparePicker(
    BuildContext context,
    PlayerStats me,
    PlayerStats them,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.md,
                  AppTheme.md,
                  AppTheme.md,
                  AppTheme.sm,
                ),
                child: Text(
                  'Compare with ${them.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const Divider(color: AppTheme.surface2, height: 1),
              ListTile(
                leading: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppTheme.accent,
                ),
                title: const Text('Ranked'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  showDialog(
                    context: context,
                    builder: (_) =>
                        _CompareDialog(me: me, them: them, selection: 'Ranked'),
                  );
                },
              ),
              const Divider(color: AppTheme.surface2, height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: them.legendStats.length,
                  separatorBuilder: (_, i) =>
                      const Divider(color: AppTheme.surface2, height: 1),
                  itemBuilder: (_, i) {
                    final legend = them.legendStats[i];
                    return ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppTheme.muted,
                      ),
                      title: Text(legend.name),
                      subtitle: legend.killCount > 0
                          ? Text(
                              '${formatNumber(legend.killCount)} kills',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        showDialog(
                          context: context,
                          builder: (_) => _CompareDialog(
                            me: me,
                            them: them,
                            selection: legend.name,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerResultBody extends StatefulWidget {
  final PlayerStats stats;
  final DateTime? staleAt;
  final Future<void> Function() onRefresh;
  const _PlayerResultBody({
    required this.stats,
    required this.onRefresh,
    this.staleAt,
  });

  @override
  State<_PlayerResultBody> createState() => _PlayerResultBodyState();
}

class _PlayerResultBodyState extends State<_PlayerResultBody> {
  List<StatSnapshot> _snapshots = [];
  int? _rpDelta;

  @override
  void initState() {
    super.initState();
    _loadAndAppend();
  }

  @override
  void didUpdateWidget(_PlayerResultBody old) {
    super.didUpdateWidget(old);
    if (old.stats.uid != widget.stats.uid) _loadAndAppend();
  }

  Future<void> _loadAndAppend() async {
    await appendSnapshot(
      widget.stats,
      uid: widget.stats.uid,
      deduplicateRp: false,
    );
    final snaps = await loadSnapshots(uid: widget.stats.uid);
    if (mounted) {
      setState(() {
        _snapshots = snaps;
        _rpDelta = computeDelta(snaps, widget.stats.rankScore);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: () async {
        await widget.onRefresh();
        await _loadAndAppend();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.md),
        children: [
          if (widget.staleAt != null) ...[
            StaleBanner(staleAt: widget.staleAt!),
            const SizedBox(height: AppTheme.sm),
          ],
          PlayerInfoCard(stats: widget.stats, rpDelta: _rpDelta),
          const SizedBox(height: AppTheme.md),
          RankedInfoCard(
            myRp: widget.stats.rankScore,
            platform: widget.stats.platform,
          ),
          const SizedBox(height: AppTheme.md),
          if (_snapshots.length >= 2) ...[
            GraphCard(snapshots: _snapshots, title: 'Ranked Points (RP)'),
            const SizedBox(height: AppTheme.md),
          ],
          if (widget.stats.legendStats.isNotEmpty) ...[
            LegendStatsSection(legends: widget.stats.legendStats),
            const SizedBox(height: AppTheme.md),
          ],
          const SizedBox(height: AppTheme.lg),
        ],
      ),
    );
  }
}

// ── Compare dialog ────────────────────────────────────────────────────────────

class _CompareDialog extends StatelessWidget {
  final PlayerStats me;
  final PlayerStats them;
  final String selection; // 'Ranked' or a legend name

  const _CompareDialog({
    required this.me,
    required this.them,
    required this.selection,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    selection,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.muted,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sm),
            const Divider(color: AppTheme.surface2, height: 1),
            const SizedBox(height: AppTheme.sm),

            if (selection == 'Ranked')
              _RankedCompare(me: me, them: them)
            else
              _LegendCompare(me: me, them: them, legendName: selection),
          ],
        ),
      ),
    );
  }
}

// ── Ranked compare content ────────────────────────────────────────────────────

class _RankedCompare extends StatelessWidget {
  final PlayerStats me;
  final PlayerStats them;

  const _RankedCompare({required this.me, required this.them});

  bool get _meIsPred => me.rank == kApexPredatorRank;
  bool get _themIsPred => them.rank == kApexPredatorRank;

  String _rankLabel(PlayerStats s) {
    if (s.rank == kApexPredatorRank) return kApexPredatorRank;
    return kRankLadder[rankIndex(s.rankScore)].label;
  }

  Color _rankColor(PlayerStats s) {
    if (s.rank == kApexPredatorRank) return kPredatorColor;
    return kRankLadder[rankIndex(s.rankScore)].color;
  }

  String? _nextLabel(PlayerStats s) {
    if (s.rank == kApexPredatorRank) return null;
    final idx = rankIndex(s.rankScore);
    if (idx < kRankLadder.length - 1) return kRankLadder[idx + 1].label;
    return null;
  }

  int? _rpToNext(PlayerStats s) {
    if (s.rank == kApexPredatorRank) return null;
    final idx = rankIndex(s.rankScore);
    if (idx < kRankLadder.length - 1) {
      return kRankLadder[idx + 1].rp - s.rankScore;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final myNext = _nextLabel(me);
    final theirNext = _nextLabel(them);
    final myRpNeeded = _rpToNext(me);
    final theirRpNeeded = _rpToNext(them);

    final higherRp = me.rankScore > them.rankScore;

    // RP needed is only colored when both players share the same rank tier
    final sameRankTier =
        !_meIsPred &&
        !_themIsPred &&
        kRankLadder[rankIndex(me.rankScore)].tier ==
            kRankLadder[rankIndex(them.rankScore)].tier;
    final myNeededColor =
        sameRankTier &&
            myRpNeeded != null &&
            theirRpNeeded != null &&
            myRpNeeded != theirRpNeeded
        ? (myRpNeeded < theirRpNeeded ? AppTheme.green : AppTheme.red)
        : AppTheme.textPrimary;
    final theirNeededColor =
        sameRankTier &&
            myRpNeeded != null &&
            theirRpNeeded != null &&
            myRpNeeded != theirRpNeeded
        ? (theirRpNeeded < myRpNeeded ? AppTheme.green : AppTheme.red)
        : AppTheme.textPrimary;

    return Column(
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sm),
          child: Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(
                child: Text(
                  'You',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  them.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rank row
        _RankedRow(
          label: 'Rank',
          myChild: Text(
            _rankLabel(me),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _rankColor(me),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          theirChild: Text(
            _rankLabel(them),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _rankColor(them),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          shaded: false,
        ),

        // RP row
        _RankedRow(
          label: 'RP',
          myChild: Text(
            formatNumber(me.rankScore),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: higherRp ? FontWeight.bold : FontWeight.normal,
              color: higherRp ? AppTheme.green : AppTheme.textPrimary,
            ),
          ),
          theirChild: Text(
            formatNumber(them.rankScore),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: !higherRp && me.rankScore != them.rankScore
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: !higherRp && me.rankScore != them.rankScore
                  ? AppTheme.red
                  : AppTheme.textPrimary,
            ),
          ),
          shaded: true,
        ),

        // Next rank row
        if (myNext != null || theirNext != null)
          _RankedRow(
            label: 'Next rank',
            myChild: Text(
              myNext ?? (_meIsPred ? '—' : 'Master'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            theirChild: Text(
              theirNext ?? (_themIsPred ? '—' : 'Master'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            shaded: false,
          ),

        // RP needed row
        if (myRpNeeded != null || theirRpNeeded != null)
          _RankedRow(
            label: 'RP needed',
            myChild: Text(
              myRpNeeded != null ? '${formatNumber(myRpNeeded)} RP' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: myNeededColor != AppTheme.textPrimary
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: myNeededColor,
              ),
            ),
            theirChild: Text(
              theirRpNeeded != null ? '${formatNumber(theirRpNeeded)} RP' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: theirNeededColor != AppTheme.textPrimary
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: theirNeededColor,
              ),
            ),
            shaded: true,
          ),
      ],
    );
  }
}

class _RankedRow extends StatelessWidget {
  final String label;
  final Widget myChild;
  final Widget theirChild;
  final bool shaded;

  const _RankedRow({
    required this.label,
    required this.myChild,
    required this.theirChild,
    required this.shaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: shaded ? AppTheme.surface2.withAlpha(60) : null,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Expanded(child: myChild),
          Expanded(child: theirChild),
        ],
      ),
    );
  }
}

// ── Legend compare content ────────────────────────────────────────────────────

class _LegendCompare extends StatelessWidget {
  final PlayerStats me;
  final PlayerStats them;
  final String legendName;

  const _LegendCompare({
    required this.me,
    required this.them,
    required this.legendName,
  });

  Map<String, int> _deduped(LegendStat legend) {
    final out = <String, int>{};
    for (final t in legend.trackers) {
      final key = t.displayName.toLowerCase();
      if (!out.containsKey(key) || t.value > out[key]!) {
        out[key] = t.value;
      }
    }
    return out;
  }

  Map<String, int> _statsFor(PlayerStats player) {
    final matches = player.legendStats.where((l) => l.name == legendName);
    return matches.isEmpty ? {} : _deduped(matches.first);
  }

  @override
  Widget build(BuildContext context) {
    final myStats = _statsFor(me);
    final theirStats = _statsFor(them);

    final allKeys = {...myStats.keys, ...theirStats.keys}.toList();

    if (allKeys.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
        child: Text(
          'No $legendName stats available for either player',
          style: const TextStyle(color: AppTheme.muted, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sm),
          child: Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              const Expanded(
                child: Text(
                  'You',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  them.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...allKeys.asMap().entries.map((entry) {
          final statName = entry.value;
          final myVal = myStats[statName];
          final theirVal = theirStats[statName];
          final myWins = myVal != null && theirVal != null && myVal > theirVal;
          final theyWin = myVal != null && theirVal != null && theirVal > myVal;

          return Container(
            color: entry.key.isOdd ? AppTheme.surface2.withAlpha(60) : null,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _capitalize(statName),
                    style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    myVal != null ? formatNumber(myVal) : '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: myWins ? FontWeight.bold : FontWeight.normal,
                      color: myWins ? AppTheme.green : AppTheme.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    theirVal != null ? formatNumber(theirVal) : '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: theyWin ? FontWeight.bold : FontWeight.normal,
                      color: theyWin ? AppTheme.red : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ── Error ─────────────────────────────────────────────────────────────────────

class _SearchError extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _SearchError({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.muted),
            const SizedBox(height: AppTheme.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.md),
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Back',
                style: TextStyle(color: AppTheme.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Favorites pane ────────────────────────────────────────────────────────────

class _FavoritesPane extends ConsumerWidget {
  final ValueChanged<PlayerRef> onPick;
  const _FavoritesPane({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(searchStateProvider).favorites;

    if (favorites.isEmpty) {
      return const Center(
        child: Text(
          'Search for a player above to get started',
          style: TextStyle(color: AppTheme.muted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.md),
      children: [
        const _ListHeader(title: 'Favorites'),
        ...favorites.map(
          (r) => _FavoriteTile(playerRef: r, onTap: () => onPick(r)),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final String title;
  const _ListHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  final PlayerRef playerRef;
  final VoidCallback onTap;

  const _FavoriteTile({required this.playerRef, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      searchPlayerProvider((playerRef.query, playerRef.platform, false)),
    );
    final stats = statsAsync.whenOrNull(data: (result) => result.data);

    Color statusColor = AppTheme.muted;
    String rankLabel =
        ApiConstants.platformLabels[playerRef.platform] ?? playerRef.platform;
    String rpText = '';

    if (stats != null) {
      statusColor = playerPresenceColor(stats);
      final idx = rankIndex(stats.rankScore);
      rankLabel = kRankLadder[idx].label;
      rpText = '${formatNumber(stats.rankScore)} RP';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: StatusDot(color: statusColor),
      title: Text(stats?.name ?? playerRef.query),
      subtitle: Text(
        rpText.isNotEmpty ? '$rankLabel · $rpText' : rankLabel,
        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
      ),
      onTap: onTap,
    );
  }
}
