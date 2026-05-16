import 'dart:ui';

class RankDivision {
  final String tier;
  final String? division;
  final int rp;
  final Color color;

  const RankDivision(this.tier, this.division, this.rp, this.color);

  String get label => division != null ? '$tier $division' : tier;
}

const _rookieColor = Color(0xFF9E9E9E);
const _bronzeColor = Color(0xFFCD853F);
const _silverColor = Color(0xFFB0BEC5);
const _goldColor = Color(0xFFFFD54F);
const _platinumColor = Color(0xFF26C6DA);
const _diamondColor = Color(0xFF7986CB);
const _masterColor = Color(0xFFAB47BC);

const kPredatorColor = Color(0xFFFF4500);
const kApexPredatorRank = 'Apex Predator';

const List<RankDivision> kRankLadder = [
  RankDivision('Rookie', 'IV', 0, _rookieColor),
  RankDivision('Rookie', 'III', 250, _rookieColor),
  RankDivision('Rookie', 'II', 500, _rookieColor),
  RankDivision('Rookie', 'I', 750, _rookieColor),
  RankDivision('Bronze', 'IV', 1000, _bronzeColor),
  RankDivision('Bronze', 'III', 1500, _bronzeColor),
  RankDivision('Bronze', 'II', 2000, _bronzeColor),
  RankDivision('Bronze', 'I', 2500, _bronzeColor),
  RankDivision('Silver', 'IV', 3000, _silverColor),
  RankDivision('Silver', 'III', 3500, _silverColor),
  RankDivision('Silver', 'II', 4000, _silverColor),
  RankDivision('Silver', 'I', 4750, _silverColor),
  RankDivision('Gold', 'IV', 5500, _goldColor),
  RankDivision('Gold', 'III', 6250, _goldColor),
  RankDivision('Gold', 'II', 7000, _goldColor),
  RankDivision('Gold', 'I', 7750, _goldColor),
  RankDivision('Platinum', 'IV', 8500, _platinumColor),
  RankDivision('Platinum', 'III', 9250, _platinumColor),
  RankDivision('Platinum', 'II', 10000, _platinumColor),
  RankDivision('Platinum', 'I', 11000, _platinumColor),
  RankDivision('Diamond', 'IV', 12000, _diamondColor),
  RankDivision('Diamond', 'III', 13000, _diamondColor),
  RankDivision('Diamond', 'II', 14000, _diamondColor),
  RankDivision('Diamond', 'I', 15000, _diamondColor),
  RankDivision('Master', null, 16000, _masterColor),
];
