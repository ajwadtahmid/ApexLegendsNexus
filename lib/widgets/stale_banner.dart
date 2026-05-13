import 'package:flutter/material.dart';
import '../utils/theme.dart';

class StaleBanner extends StatelessWidget {
  final DateTime staleAt;
  const StaleBanner({super.key, required this.staleAt});

  String get _ago {
    final diff = DateTime.now().difference(staleAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.sm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.orange.withAlpha(25),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 14,
            color: AppTheme.orange,
          ),
          const SizedBox(width: 6),
          Text(
            'Offline · cached $_ago',
            style: const TextStyle(color: AppTheme.orange, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
