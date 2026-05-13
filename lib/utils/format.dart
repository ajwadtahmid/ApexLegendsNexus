import '../constants/rank_constants.dart';

String fmtRp(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

int rankIdx(int rp) {
  for (var i = kRankLadder.length - 1; i >= 0; i--) {
    if (rp >= kRankLadder[i].rp) return i;
  }
  return 0;
}
