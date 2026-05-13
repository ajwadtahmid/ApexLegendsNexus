import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/player_stats.dart';
import '../../providers/api_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/error_messages.dart';
import '../../utils/storage.dart';
import '../../utils/theme.dart';
import '../../widgets/graph_card.dart';
import '../../widgets/platform_picker.dart';
import '../../widgets/player_profile.dart';
import '../../widgets/shimmer.dart';
import '../../widgets/stale_banner.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(playerSettingsProvider);

    if (!settings.isPlayerSet) {
      return const _PlayerSetupView();
    }

    return _StatsView(settings: settings);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Player setup (shown when no player linked)
// ═══════════════════════════════════════════════════════════════════════════════

class _PlayerSetupView extends StatelessWidget {
  const _PlayerSetupView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.xl),
            const Icon(
              Icons.person_search_outlined,
              size: 72,
              color: AppTheme.accent,
            ),
            const SizedBox(height: AppTheme.md),
            const Text(
              'Set Up Your Player',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.sm),
            const Text(
              'Enter your in-game name and platform to start tracking your stats.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, height: 1.5),
            ),
            const SizedBox(height: AppTheme.xl),
            const _PlayerLookupForm(submitLabel: 'Find My Player'),
            const SizedBox(height: AppTheme.sm),
            const Text(
              'Names are case-sensitive on PC. You can also enter a numeric UID.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Stats view (shown when player is linked)
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsView extends ConsumerStatefulWidget {
  final PlayerSettings settings;
  const _StatsView({required this.settings});

  @override
  ConsumerState<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<_StatsView> {
  Timer? _refreshTimer;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _setupTimer(widget.settings.statsRefreshMinutes);
  }

  @override
  void didUpdateWidget(_StatsView old) {
    super.didUpdateWidget(old);
    if (old.settings.statsRefreshMinutes !=
        widget.settings.statsRefreshMinutes) {
      _setupTimer(widget.settings.statsRefreshMinutes);
    }
  }

  void _setupTimer(int minutes) {
    _refreshTimer?.cancel();
    if (minutes <= 0) return;
    _refreshTimer = Timer.periodic(Duration(minutes: minutes), (_) {
      if (mounted) _sync();
    });
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    ref.invalidate(myPlayerStatsProvider);
    try {
      await ref.read(myPlayerStatsProvider.future);
    } catch (_) {}
    if (mounted) setState(() => _syncing = false);
  }

  void _openChangePlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (_) => const _ChangePlayerSheet(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final statsAsync = ref.watch(myPlayerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _openChangePlayer(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(settings.name),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
        actions: [
          _syncing
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
                  tooltip: 'Sync',
                  onPressed: _sync,
                ),
        ],
      ),
      body: statsAsync.when(
        data: (result) => result.data == null
            ? const Center(
                child: Text(
                  'No data.',
                  style: TextStyle(color: AppTheme.muted),
                ),
              )
            : _StatsBody(
                stats: result.data!,
                staleAt: result.staleAt,
                settings: settings,
              ),
        loading: () => const _StatsSkeleton(),
        error: (e, _) => _ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(myPlayerStatsProvider),
        ),
      ),
    );
  }
}

class _StatsBody extends ConsumerStatefulWidget {
  final PlayerStats stats;
  final DateTime? staleAt;
  final PlayerSettings settings;

  const _StatsBody({required this.stats, required this.settings, this.staleAt});

  @override
  ConsumerState<_StatsBody> createState() => _StatsBodyState();
}

class _StatsBodyState extends ConsumerState<_StatsBody> {
  List<StatSnapshot> _snapshots = [];
  List<LegendStat> _mergedLegends = [];
  int? _rpDelta;

  @override
  void initState() {
    super.initState();
    _loadAndAppend();
  }

  @override
  void didUpdateWidget(_StatsBody old) {
    super.didUpdateWidget(old);
    if (old.stats != widget.stats) _loadAndAppend();
  }

  Future<void> _loadAndAppend() async {
    await appendSnapshot(widget.stats);
    // Run both reads in parallel — they are independent after the append.
    final (snaps, legends) = await (
      loadSnapshots(),
      mergeLegendStats(widget.stats.legendStats),
    ).wait;
    if (mounted) {
      setState(() {
        _snapshots = snaps;
        _mergedLegends = legends;
        _rpDelta = _computeTodayDelta(snaps);
      });
    }
  }

  int? _computeTodayDelta(List<StatSnapshot> snaps) {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final beforeToday = snaps
        .where((s) => s.timestamp.isBefore(midnight))
        .toList();
    if (beforeToday.isEmpty) return null;
    return widget.stats.rankScore - beforeToday.last.rp;
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: () async {
        ref.invalidate(myPlayerStatsProvider);
        try {
          await ref.read(myPlayerStatsProvider.future);
        } catch (_) {}
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.md),
        children: [
          if (widget.staleAt != null) ...[
            StaleBanner(staleAt: widget.staleAt!),
            const SizedBox(height: AppTheme.sm),
          ],
          PlayerInfoCard(stats: stats, rpDelta: _rpDelta),
          const SizedBox(height: AppTheme.md),
          RankedInfoCard(
            myRp: stats.rankScore,
            platform: widget.settings.platform,
          ),
          const SizedBox(height: AppTheme.md),
          if (_snapshots.length >= 2) ...[
            GraphCard(snapshots: _snapshots, title: 'Ranked Points (RP)'),
            const SizedBox(height: AppTheme.md),
          ],
          if (_mergedLegends.isNotEmpty) ...[
            LegendStatsSection(
              legends: _mergedLegends,
              compact: widget.settings.compactLegendCards,
            ),
            const SizedBox(height: AppTheme.md),
          ],
          const SizedBox(height: AppTheme.lg),
        ],
      ),
    );
  }
}

// ── Shared player lookup form ─────────────────────────────────────────────────
//
// Handles the name input, platform picker, API lookup, and error display.
// Used by both _PlayerSetupView (first-time) and _ChangePlayerSheet (update).
// Pre-fills from current settings when a player is already linked.

class _PlayerLookupForm extends ConsumerStatefulWidget {
  final String submitLabel;
  final VoidCallback? onSuccess;

  const _PlayerLookupForm({required this.submitLabel, this.onSuccess});

  @override
  ConsumerState<_PlayerLookupForm> createState() => _PlayerLookupFormState();
}

class _PlayerLookupFormState extends ConsumerState<_PlayerLookupForm> {
  final _controller = TextEditingController();
  String _platform = 'PC';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(playerSettingsProvider);
    if (settings.isPlayerSet) {
      _controller.text = settings.name;
      _platform = settings.platform;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a player name.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(playerServiceProvider)
          .nameToUid(name, _platform);
      await ref
          .read(playerSettingsProvider.notifier)
          .setPlayer(result.name, result.uid, _platform);
      widget.onSuccess?.call();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Player not found. Check the name and platform.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onSubmitted: (_) => _submit(),
          textInputAction: TextInputAction.done,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'In-game name',
            prefixIcon: Icon(Icons.person_outline, color: AppTheme.muted),
          ),
        ),
        const SizedBox(height: AppTheme.md),
        PlatformPicker(
          selected: _platform,
          onChanged: (p) => setState(() => _platform = p),
          expanded: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppTheme.sm),
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: AppTheme.red.withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppTheme.red, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppTheme.lg),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}

// ── Change player sheet ───────────────────────────────────────────────────────

class _ChangePlayerSheet extends StatelessWidget {
  const _ChangePlayerSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.md,
        AppTheme.md,
        AppTheme.md,
        AppTheme.md + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.md),
          const Text(
            'Change Player',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.md),
          _PlayerLookupForm(
            submitLabel: 'Update Player',
            onSuccess: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppTheme.sm),
        ],
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.red),
            const SizedBox(height: AppTheme.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.md),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── Stats skeleton ────────────────────────────────────────────────────────────

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.md),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Player info card
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    ShimmerBox(
                      width: 10,
                      height: 10,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerBox(height: 24)),
                    SizedBox(width: 8),
                    ShimmerBox(width: 50, height: 15),
                  ],
                ),
                const SizedBox(height: 6),
                const ShimmerBox(width: 200, height: 16),
                const SizedBox(height: 2),
                const ShimmerBox(width: 140, height: 16),
                const SizedBox(height: AppTheme.md),
                ...List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: ShimmerBox(height: 16)),
                        SizedBox(width: 40),
                        ShimmerBox(width: 60, height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.md),

          // Ranked card — header + icon row + progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 60, height: 18),
              const SizedBox(height: AppTheme.sm),
              Container(
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
                        ShimmerBox(
                          width: 42,
                          height: 42,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 120, height: 24),
                            SizedBox(height: 6),
                            ShimmerBox(width: 80, height: 16),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.md),
                    const ShimmerBox(
                      height: 6,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ShimmerBox(width: 48, height: 14),
                        ShimmerBox(width: 80, height: 15),
                        ShimmerBox(width: 48, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),

          // Legend section header + cards
          const ShimmerBox(width: 100, height: 18),
          const SizedBox(height: AppTheme.sm),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.sm),
              child: ShimmerBox(
                height: 90,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
