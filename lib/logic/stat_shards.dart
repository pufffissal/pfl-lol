import '../models/stat.dart';

/// A rune stat shard. Shards are not in Data Dragon, so they live here.
/// Update this table if Riot changes shard values in a patch.
class StatShard {
  const StatShard(this.id, this.label, this.stats, {this.scalingHealth = false});

  final String id;
  final String label;
  final Map<Stat, double> stats;

  /// Scaling health: 10 at level 1 up to 180 at level 18.
  final bool scalingHealth;

  StatBag statsAt(int level) {
    final bag = StatBag(stats);
    if (scalingHealth) bag.add(Stat.health, 10 + 10 * (level - 1).toDouble());
    return bag;
  }
}

const _adaptive = StatShard('adaptive', 'Adaptive Force +9', {Stat.adaptiveForce: 9});
const _attackSpeed = StatShard('as', 'Attack Speed +10%', {Stat.attackSpeed: 10});
const _haste = StatShard('ah', 'Ability Haste +8', {Stat.abilityHaste: 8});
const _moveSpeed = StatShard('ms', 'Move Speed +2%', {Stat.moveSpeedPercent: 2});
const _scalingHp = StatShard('hpscale', 'Health +10–180 (lvl)', {}, scalingHealth: true);
const _flatHp = StatShard('hp', 'Health +65', {Stat.health: 65});
const _tenacity = StatShard('ten', 'Tenacity & Slow Resist +10%', {Stat.tenacity: 10, Stat.slowResist: 10});

/// Rows: offense, flex, defense.
const List<List<StatShard>> statShardRows = [
  [_adaptive, _attackSpeed, _haste],
  [_adaptive, _moveSpeed, _scalingHp],
  [_flatHp, _tenacity, _scalingHp],
];

const statShardRowNames = ['Offense', 'Flex', 'Defense'];

StatShard? findShard(int row, String? id) {
  if (id == null || row < 0 || row >= statShardRows.length) return null;
  for (final s in statShardRows[row]) {
    if (s.id == id) return s;
  }
  return null;
}
