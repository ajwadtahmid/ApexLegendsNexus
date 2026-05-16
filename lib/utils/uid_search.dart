import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/prefs_keys.dart';
import '../providers/settings_provider.dart';

/// Shows the UID search warning dialog the first time a user enables UID search.
/// Marks the pref after the dialog is dismissed so it only ever shows once.
Future<void> showUidWarningIfNeeded(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(PrefsKeys.uidSearchWarningShown) ?? false) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Finding Your UID'),
      content: const Text(
        'You can find the UID from deep search on apexlegendsstatus.com',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
  await prefs.setBool(PrefsKeys.uidSearchWarningShown, true);
}
