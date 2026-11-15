import '../models/build.dart';
import '../models/champion.dart';
import '../models/item.dart';
import '../models/stat.dart';
import 'stat_calculator.dart';
import 'stat_shards.dart';

class BuildResult {
  const BuildResult({
    required this.stats,
    required this.bonus,
    required this.totalGold,
    required this.warnings,
  });

  final ComputedStats stats;

  /// Raw bonus stats from items and shards (before adaptive conversion).
  final StatBag bonus;
  final int totalGold;
  final List<String> warnings;
}

/// Turns a [SavedBuild] into final champion stats.
class BuildEvaluator {
  static BuildResult evaluate({
    required SavedBuild build,
    required ChampionSummary champion,
    required Map<String, Item> items,
  }) {
    final bonus = StatBag();
    var gold = 0;
    final warnings = <String>[];
    final seen = <String>{};
    var boots = 0;

    for (final id in build.items) {
      if (id == null) continue;
      final item = items[id];
      if (item == null) {
        warnings.add('Item $id is not in this patch');
        continue;
      }
      bonus.addAll(item.stats);
      gold += item.goldTotal;
      if (item.tier == ItemTier.boots) boots++;
      if (item.tier == ItemTier.legendary && !seen.add(id)) {
        warnings.add('${item.name} is listed more than once');
      }
    }
    if (boots > 1) warnings.add('Only one pair of boots can be bought');

    for (var row = 0; row < build.shards.length; row++) {
      final shard = findShard(row, build.shards[row]);
      if (shard != null) bonus.addAll(shard.statsAt(build.level));
    }

    final stats = StatCalculator.compute(
      base: champion.stats,
      level: build.level,
      bonus: bonus,
      prefersAd: champion.prefersAd,
    );
    return BuildResult(stats: stats, bonus: bonus, totalGold: gold, warnings: warnings);
  }
}
