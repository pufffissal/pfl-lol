import '../logic/item_stats_parser.dart';
import 'stat.dart';

enum ItemTier { starter, consumable, boots, basic, epic, legendary }

class Item {
  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.plaintext,
    required this.from,
    required this.into,
    required this.imageFull,
    required this.goldBase,
    required this.goldTotal,
    required this.goldSell,
    required this.purchasable,
    required this.tags,
    required this.maps,
    required this.depth,
    required this.requiredChampion,
    required this.inStore,
    required this.hideFromAll,
    required this.consumed,
    required this.stats,
  });

  factory Item.fromJson(String id, Map<String, dynamic> j) {
    final gold = (j['gold'] as Map?) ?? const {};
    final description = j['description'] as String? ?? '';
    return Item(
      id: id,
      name: j['name'] as String? ?? id,
      description: description,
      plaintext: j['plaintext'] as String? ?? '',
      from: List<String>.from(j['from'] as List? ?? const []),
      into: List<String>.from(j['into'] as List? ?? const []),
      imageFull: (j['image'] as Map?)?['full'] as String? ?? '$id.png',
      goldBase: (gold['base'] as num?)?.toInt() ?? 0,
      goldTotal: (gold['total'] as num?)?.toInt() ?? 0,
      goldSell: (gold['sell'] as num?)?.toInt() ?? 0,
      purchasable: gold['purchasable'] as bool? ?? false,
      tags: List<String>.from(j['tags'] as List? ?? const []),
      maps: {for (final e in ((j['maps'] as Map?) ?? const {}).entries) e.key.toString(): e.value == true},
      depth: (j['depth'] as num?)?.toInt() ?? 1,
      requiredChampion: j['requiredChampion'] as String? ?? '',
      inStore: j['inStore'] as bool? ?? true,
      hideFromAll: j['hideFromAll'] as bool? ?? false,
      consumed: j['consumed'] as bool? ?? false,
      stats: ItemStatsParser.parse(description, (j['stats'] as Map?)?.cast<String, dynamic>()),
    );
  }

  final String id, name, description, plaintext;
  final List<String> from, into;
  final String imageFull;
  final int goldBase, goldTotal, goldSell;
  final bool purchasable;
  final List<String> tags;
  final Map<String, bool> maps;
  final int depth;
  final String requiredChampion;
  final bool inStore, hideFromAll, consumed;
  final StatBag stats;

  /// Summoner's Rift map id.
  static const summonersRift = '11';

  bool get isOnSummonersRift => maps[summonersRift] ?? false;

  /// Items a player can actually buy on Summoner's Rift.
  bool get isShopItem =>
      isOnSummonersRift && purchasable && inStore && !hideFromAll && requiredChampion.isEmpty;

  ItemTier get tier {
    if (consumed || tags.contains('Consumable')) return ItemTier.consumable;
    if (tags.contains('Boots')) return ItemTier.boots;
    if (from.isEmpty && into.isEmpty) return ItemTier.starter;
    if (from.isEmpty) return ItemTier.basic;
    if (into.isNotEmpty) return ItemTier.epic;
    return ItemTier.legendary;
  }
}
