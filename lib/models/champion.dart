/// Champion models parsed from Data Dragon `champion.json` and
/// `champion/{id}.json`.
library;

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Base stats and per-level growth, exactly as Data Dragon ships them.
class BaseStats {
  const BaseStats({
    required this.hp,
    required this.hpPerLevel,
    required this.mp,
    required this.mpPerLevel,
    required this.moveSpeed,
    required this.armor,
    required this.armorPerLevel,
    required this.spellBlock,
    required this.spellBlockPerLevel,
    required this.attackRange,
    required this.hpRegen,
    required this.hpRegenPerLevel,
    required this.mpRegen,
    required this.mpRegenPerLevel,
    required this.crit,
    required this.critPerLevel,
    required this.attackDamage,
    required this.attackDamagePerLevel,
    required this.attackSpeedPerLevel,
    required this.attackSpeed,
  });

  factory BaseStats.fromJson(Map<String, dynamic> j) => BaseStats(
    hp: _d(j['hp']),
    hpPerLevel: _d(j['hpperlevel']),
    mp: _d(j['mp']),
    mpPerLevel: _d(j['mpperlevel']),
    moveSpeed: _d(j['movespeed']),
    armor: _d(j['armor']),
    armorPerLevel: _d(j['armorperlevel']),
    spellBlock: _d(j['spellblock']),
    spellBlockPerLevel: _d(j['spellblockperlevel']),
    attackRange: _d(j['attackrange']),
    hpRegen: _d(j['hpregen']),
    hpRegenPerLevel: _d(j['hpregenperlevel']),
    mpRegen: _d(j['mpregen']),
    mpRegenPerLevel: _d(j['mpregenperlevel']),
    crit: _d(j['crit']),
    critPerLevel: _d(j['critperlevel']),
    attackDamage: _d(j['attackdamage']),
    attackDamagePerLevel: _d(j['attackdamageperlevel']),
    attackSpeedPerLevel: _d(j['attackspeedperlevel']),
    attackSpeed: _d(j['attackspeed']),
  );

  final double hp, hpPerLevel;
  final double mp, mpPerLevel;
  final double moveSpeed;
  final double armor, armorPerLevel;
  final double spellBlock, spellBlockPerLevel;
  final double attackRange;
  final double hpRegen, hpRegenPerLevel;
  final double mpRegen, mpRegenPerLevel;
  final double crit, critPerLevel;
  final double attackDamage, attackDamagePerLevel;

  /// Bonus attack speed gained per level, in percent (e.g. 2.5 = 2.5%).
  final double attackSpeedPerLevel;

  /// Base attacks per second at level 1.
  final double attackSpeed;
}

/// Riot's 0-10 ratings shown on the champion select screen.
class ChampionInfo {
  const ChampionInfo(this.attack, this.defense, this.magic, this.difficulty);

  factory ChampionInfo.fromJson(Map<String, dynamic>? j) => ChampionInfo(
    (j?['attack'] as num?)?.toInt() ?? 0,
    (j?['defense'] as num?)?.toInt() ?? 0,
    (j?['magic'] as num?)?.toInt() ?? 0,
    (j?['difficulty'] as num?)?.toInt() ?? 0,
  );

  final int attack, defense, magic, difficulty;
}

/// Lightweight champion entry used for lists and the build calculator.
class ChampionSummary {
  const ChampionSummary({
    required this.id,
    required this.key,
    required this.name,
    required this.title,
    required this.blurb,
    required this.tags,
    required this.partype,
    required this.imageFull,
    required this.stats,
    required this.info,
  });

  factory ChampionSummary.fromJson(Map<String, dynamic> j) => ChampionSummary(
    id: j['id'] as String,
    key: j['key'] as String,
    name: j['name'] as String,
    title: j['title'] as String? ?? '',
    blurb: j['blurb'] as String? ?? '',
    tags: List<String>.from(j['tags'] as List? ?? const []),
    partype: j['partype'] as String? ?? '',
    imageFull: (j['image'] as Map?)?['full'] as String? ?? '${j['id']}.png',
    stats: BaseStats.fromJson(Map<String, dynamic>.from(j['stats'] as Map)),
    info: ChampionInfo.fromJson(j['info'] as Map<String, dynamic>?),
  );

  /// String id used in URLs, e.g. `MonkeyKing`.
  final String id;

  /// Numeric key as string, e.g. `62`.
  final String key;
  final String name;
  final String title;
  final String blurb;

  /// Roles such as `Fighter`, `Mage`, `Marksman`.
  final List<String> tags;

  /// Resource type: `Mana`, `Energy`, `None`, `Fury`...
  final String partype;
  final String imageFull;
  final BaseStats stats;
  final ChampionInfo info;

  /// Whether adaptive force should resolve to AD when bonus AD == bonus AP.
  bool get prefersAd => tags.isNotEmpty && const {'Marksman', 'Fighter', 'Assassin'}.contains(tags.first);
}

class ChampionSpell {
  const ChampionSpell({
    required this.id,
    required this.name,
    required this.description,
    required this.tooltip,
    required this.maxRank,
    required this.cooldownBurn,
    required this.costBurn,
    required this.rangeBurn,
    required this.resource,
    required this.imageFull,
  });

  factory ChampionSpell.fromJson(Map<String, dynamic> j) => ChampionSpell(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    tooltip: j['tooltip'] as String? ?? '',
    maxRank: (j['maxrank'] as num?)?.toInt() ?? 0,
    cooldownBurn: j['cooldownBurn'] as String? ?? '',
    costBurn: j['costBurn'] as String? ?? '',
    rangeBurn: j['rangeBurn'] as String? ?? '',
    resource: j['resource'] as String? ?? '',
    imageFull: (j['image'] as Map?)?['full'] as String? ?? '',
  );

  final String id, name, description, tooltip;
  final int maxRank;
  final String cooldownBurn, costBurn, rangeBurn, resource;
  final String imageFull;
}

class ChampionPassive {
  const ChampionPassive(this.name, this.description, this.imageFull);

  factory ChampionPassive.fromJson(Map<String, dynamic>? j) => ChampionPassive(
    j?['name'] as String? ?? '',
    j?['description'] as String? ?? '',
    (j?['image'] as Map?)?['full'] as String? ?? '',
  );

  final String name, description, imageFull;
}

class ChampionSkin {
  const ChampionSkin(this.id, this.number, this.name, this.hasChromas);

  factory ChampionSkin.fromJson(Map<String, dynamic> j) => ChampionSkin(
    j['id'] as String? ?? '',
    (j['num'] as num?)?.toInt() ?? 0,
    j['name'] as String? ?? '',
    j['chromas'] as bool? ?? false,
  );

  final String id;

  /// Skin number used in splash art URLs (0 = default skin).
  final int number;
  final String name;
  final bool hasChromas;
}

/// Full champion data from `champion/{id}.json`.
class ChampionDetail {
  const ChampionDetail({
    required this.summary,
    required this.lore,
    required this.allyTips,
    required this.enemyTips,
    required this.skins,
    required this.spells,
    required this.passive,
  });

  factory ChampionDetail.fromJson(Map<String, dynamic> j) => ChampionDetail(
    summary: ChampionSummary.fromJson(j),
    lore: j['lore'] as String? ?? '',
    allyTips: List<String>.from(j['allytips'] as List? ?? const []),
    enemyTips: List<String>.from(j['enemytips'] as List? ?? const []),
    skins: [
      for (final s in (j['skins'] as List? ?? const []))
        ChampionSkin.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    spells: [
      for (final s in (j['spells'] as List? ?? const []))
        ChampionSpell.fromJson(Map<String, dynamic>.from(s as Map)),
    ],
    passive: ChampionPassive.fromJson(j['passive'] as Map<String, dynamic>?),
  );

  final ChampionSummary summary;
  final String lore;
  final List<String> allyTips, enemyTips;
  final List<ChampionSkin> skins;

  /// Q, W, E, R in order.
  final List<ChampionSpell> spells;
  final ChampionPassive passive;
}
