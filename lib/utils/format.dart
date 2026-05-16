import 'package:intl/intl.dart';
import '../constants/rank_constants.dart';

final _rpFormat = NumberFormat('#,###');

String formatNumber(int v) => _rpFormat.format(v);

int rankIndex(int rp) {
  for (var i = kRankLadder.length - 1; i >= 0; i--) {
    if (rp >= kRankLadder[i].rp) return i;
  }
  return 0;
}

String timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
