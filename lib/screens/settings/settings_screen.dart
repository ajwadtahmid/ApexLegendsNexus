import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../constants/api_constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/background_service.dart';
import '../../services/notification_service.dart';
import '../../utils/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(playerSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.md),
        children: [
          // ── Account ─────────────────────────────────────────────
          _SectionLabel(label: 'ACCOUNT', icon: Icons.person_outline),
          _SettingsCard(
            child: settings.isPlayerSet
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  ApiConstants.platformLabels[settings
                                          .platform] ??
                                      settings.platform,
                                  style: const TextStyle(
                                    color: AppTheme.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.sm),
                      const Divider(color: AppTheme.surface2),
                      const SizedBox(height: AppTheme.sm),
                      // UID row — full value, tap to copy
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: settings.uid));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('UID copied to clipboard'),
                              backgroundColor: AppTheme.surface2,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Text(
                              'UID',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: AppTheme.sm),
                            Expanded(
                              child: Text(
                                settings.uid,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.sm),
                            const Icon(
                              Icons.copy,
                              size: 14,
                              color: AppTheme.muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.sm),
                      const Divider(color: AppTheme.surface2),
                      const SizedBox(height: 4),
                      const Text(
                        'To change your player, go to the Stats tab.',
                        style: TextStyle(color: AppTheme.muted, fontSize: 12),
                      ),
                    ],
                  )
                : const Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: AppTheme.muted,
                        size: 20,
                      ),
                      SizedBox(width: AppTheme.sm),
                      Text(
                        'No player set up',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      Spacer(),
                      Text(
                        'Go to Stats →',
                        style: TextStyle(color: AppTheme.accent, fontSize: 13),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: AppTheme.md),

          // ── Preferences ──────────────────────────────────────────
          _SectionLabel(label: 'PREFERENCES', icon: Icons.tune),
          _SettingsCard(
            child: Column(
              children: [
                // Stats auto-refresh
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickRefreshInterval(
                    context,
                    ref,
                    settings.statsRefreshMinutes,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.update,
                        color: AppTheme.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.sm),
                      const Expanded(
                        child: Text(
                          'Stats auto-refresh',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        _refreshLabel(settings.statsRefreshMinutes),
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                // Compact legend cards
                Row(
                  children: [
                    const Icon(
                      Icons.view_list_outlined,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    const Expanded(
                      child: Text(
                        'Compact legend cards',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: settings.compactLegendCards,
                      onChanged: (v) => ref
                          .read(playerSettingsProvider.notifier)
                          .setCompactLegendCards(v),
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withAlpha(120),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                // Helpful tips
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    const Expanded(
                      child: Text(
                        'Helpful tips',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: settings.helpfulTipsEnabled,
                      onChanged: (v) => ref
                          .read(playerSettingsProvider.notifier)
                          .setHelpfulTipsEnabled(v),
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withAlpha(120),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                // Default tab on launch
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      _pickDefaultTab(context, ref, settings.defaultTab),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tab_outlined,
                        color: AppTheme.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.sm),
                      const Expanded(
                        child: Text(
                          'Default tab',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        _tabLabel(settings.defaultTab),
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.sm),

          // ── Notifications ────────────────────────────────────────
          _SectionLabel(
            label: 'NOTIFICATIONS',
            icon: Icons.notifications_outlined,
          ),
          _SettingsCard(
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickNotifyBefore(
                    context,
                    ref,
                    settings.mapNotifyMinutesBefore,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.sm),
                      const Expanded(
                        child: Text(
                          'Map rotation alerts',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        _notifyLabel(settings.mapNotifyMinutesBefore),
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                // Pubs notifications
                Row(
                  children: [
                    const Icon(
                      Icons.public,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    const Expanded(
                      child: Text('Pubs', style: TextStyle(fontSize: 14)),
                    ),
                    Switch(
                      value: settings.notifyPubsMapRotation,
                      onChanged: (v) async {
                        if (v) await _enableNotificationMode(context);
                        ref
                            .read(playerSettingsProvider.notifier)
                            .setNotifyPubsMapRotation(v);
                      },
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withAlpha(120),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                // Ranked notifications
                Row(
                  children: [
                    const Icon(
                      Icons.leaderboard_outlined,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    const Expanded(
                      child: Text('Ranked', style: TextStyle(fontSize: 14)),
                    ),
                    Switch(
                      value: settings.notifyRankedMapRotation,
                      onChanged: (v) async {
                        if (v) await _enableNotificationMode(context);
                        ref
                            .read(playerSettingsProvider.notifier)
                            .setNotifyRankedMapRotation(v);
                      },
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withAlpha(120),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                // Mixtape notifications
                Row(
                  children: [
                    const Icon(
                      Icons.music_note_outlined,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    const Expanded(
                      child: Text('Mixtape', style: TextStyle(fontSize: 14)),
                    ),
                    Switch(
                      value: settings.notifyMixtapeMapRotation,
                      onChanged: (v) async {
                        if (v) await _enableNotificationMode(context);
                        ref
                            .read(playerSettingsProvider.notifier)
                            .setNotifyMixtapeMapRotation(v);
                      },
                      activeThumbColor: AppTheme.accent,
                      activeTrackColor: AppTheme.accent.withAlpha(120),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.md),

          // ── Data ─────────────────────────────────────────────────
          _SectionLabel(label: 'DATA', icon: Icons.storage),
          _SettingsCard(
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.star_border,
                  label: 'Clear favorites',
                  onTap: () => _confirm(
                    context,
                    title: 'Clear favorites?',
                    body: 'Your saved favorite players will be removed.',
                    onConfirm: () =>
                        ref.read(searchStateProvider.notifier).clearFavorites(),
                  ),
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                _ActionRow(
                  icon: Icons.delete_outline,
                  label: 'Clear all data',
                  color: AppTheme.red,
                  onTap: () => _confirm(
                    context,
                    title: 'Clear all data?',
                    body:
                        'Your linked player and saved favorites will be removed.',
                    onConfirm: () async {
                      await ref.read(playerSettingsProvider.notifier).clear();
                      ref.read(searchStateProvider.notifier).clearFavorites();
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.md),

          // ── About & Resources ───────────────────────────────────
          _SectionLabel(label: 'ABOUT & RESOURCES', icon: Icons.info_outline),
          _SettingsCard(
            child: Column(
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (ctx, snap) {
                    final version = snap.data?.version ?? '—';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: 'Version', value: version),
                        const SizedBox(height: AppTheme.sm),
                        const Text(
                          'Apex Legends Nexus is an unofficial companion app. Not made by, affiliated with, or endorsed by Electronic Arts or Respawn Entertainment.',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                _LinkRow(
                  label: 'apexlegendsstatus.com',
                  subtitle:
                      'Server status. You can check this website for more information.',
                  url: 'https://apexlegendsstatus.com',
                ),
                const Divider(color: AppTheme.surface2, height: 24),
                _LinkRow(
                  label: 'apexlegendsapi.com',
                  subtitle:
                      'Player stats & legend data are provided by this API.',
                  url: 'https://apexlegendsapi.com',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.xl),
        ],
      ),
    );
  }

  static const _tabOptions = [
    (0, 'Home'),
    (1, 'My Stats'),
    (2, 'Search'),
    (3, 'Settings'),
  ];

  String _tabLabel(int tab) =>
      _tabOptions.firstWhere((t) => t.$1 == tab, orElse: () => (0, 'Home')).$2;

  Future<void> _pickDefaultTab(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Default tab'),
        children: _tabOptions.map((option) {
          final (tab, label) = option;
          final selected = tab == current;
          return SimpleDialogOption(
            onPressed: () {
              ref.read(playerSettingsProvider.notifier).setDefaultTab(tab);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: AppTheme.accent, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static const _refreshOptions = [0, 5, 15, 30];

  String _refreshLabel(int minutes) => switch (minutes) {
    0 => 'Manual',
    5 => 'Every 5 min',
    15 => 'Every 15 min',
    30 => 'Every 30 min',
    _ => 'Every $minutes min',
  };

  static const _notifyOptions = [0, 5, 10, 15];

  String _notifyLabel(int minutes) => switch (minutes) {
    0 => 'Off',
    _ => '$minutes min before',
  };

  Future<void> _pickNotifyBefore(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Map rotation alert'),
        children: _notifyOptions.map((minutes) {
          final selected = minutes == current;
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              if (minutes > 0 && current == 0) {
                await NotificationService.requestPermissions();
              }
              ref
                  .read(playerSettingsProvider.notifier)
                  .setMapNotifyMinutesBefore(minutes);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _notifyLabel(minutes),
                    style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: AppTheme.accent, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickRefreshInterval(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Stats auto-refresh'),
        children: _refreshOptions.map((minutes) {
          final selected = minutes == current;
          return SimpleDialogOption(
            onPressed: () {
              ref
                  .read(playerSettingsProvider.notifier)
                  .setStatsRefreshMinutes(minutes);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _refreshLabel(minutes),
                    style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textPrimary,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check, color: AppTheme.accent, size: 18),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _enableNotificationMode(BuildContext context) async {
    await NotificationService.requestPermissions();
    if (!context.mounted) return;
    final available = await BackgroundService.isAvailable();
    if (!available && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Background Refresh Disabled'),
          content: const Text(
            'Notifications will only fire while the app is open.\n\nTo get alerts when the app is closed, enable Background App Refresh in:\niOS Settings → General → Background App Refresh → Apex Legends Nexus',
            style: TextStyle(color: AppTheme.muted, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppTheme.accent)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title),
        content: Text(body, style: const TextStyle(color: AppTheme.muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.muted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _SectionLabel({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.accent, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: child,
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.sm),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: const TextStyle(color: AppTheme.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final String url;
  const _LinkRow({
    required this.label,
    required this.subtitle,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.blue,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, color: AppTheme.muted, size: 14),
        ],
      ),
    );
  }
}
