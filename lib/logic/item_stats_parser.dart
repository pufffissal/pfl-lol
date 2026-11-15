import '../models/stat.dart';

/// Extracts numeric stats from an item.
///
/// Data Dragon's `stats` object only covers a subset of modern stats (it has
/// no Ability Haste, Lethality, Omnivamp, ...). The description, however,
/// contains a `<stats>` block such as:
///
/// ```html
/// <mainText><stats><attention>40</attention> Attack Damage<br>
/// <attention>20</attention> Ability Haste</stats>...
/// ```
///
/// We parse that block first and only fall back to the `stats` object when
/// the description has no parsable stats.
class ItemStatsParser {
  static final _statsBlock = RegExp(r'<stats>(.*?)</stats>', dotAll: true);
  static final _tag = RegExp(r'<[^>]+>');
  static final _line = RegExp(r'^\+?\s*([\d.]+)\s*(%?)\s+(.+)$');

  /// Lower-cased stat name -> (flat stat, percent stat).
  static const Map<String, (Stat?, Stat?)> _names = {
    'health': (Stat.health, null),
    'mana': (Stat.mana, null),
    'attack damage': (Stat.attackDamage, null),
    'ability power': (Stat.abilityPower, null),
    'armor': (Stat.armor, null),
    'magic resist': (Stat.magicResist, null),
    'magic resistance': (Stat.magicResist, null),
    'attack speed': (null, Stat.attackSpeed),
    'critical strike chance': (null, Stat.critChance),
    'critical strike damage': (null, Stat.critDamage),
    'move speed': (Stat.moveSpeedFlat, Stat.moveSpeedPercent),
    'movement speed': (Stat.moveSpeedFlat, Stat.moveSpeedPercent),
    'ability haste': (Stat.abilityHaste, null),
    'lethality': (Stat.lethality, null),
    'armor penetration': (null, Stat.armorPenPercent),
    'magic penetration': (Stat.magicPenFlat, Stat.magicPenPercent),
    'life steal': (null, Stat.lifeSteal),
    'omnivamp': (null, Stat.omnivamp),
    'heal and shield power': (null, Stat.healShieldPower),
    'base health regen': (Stat.healthRegenFlat, Stat.baseHealthRegen),
    'health regen': (Stat.healthRegenFlat, Stat.baseHealthRegen),
    'base mana regen': (Stat.manaRegenFlat, Stat.baseManaRegen),
    'mana regen': (Stat.manaRegenFlat, Stat.baseManaRegen),
    'tenacity': (null, Stat.tenacity),
    'slow resist': (null, Stat.slowResist),
  };

  /// Data Dragon `stats` keys. Percent values there are fractions (0.25).
  static const Map<String, (Stat, double)> _legacy = {
    'FlatHPPoolMod': (Stat.health, 1),
    'FlatMPPoolMod': (Stat.mana, 1),
    'FlatPhysicalDamageMod': (Stat.attackDamage, 1),
    'FlatMagicDamageMod': (Stat.abilityPower, 1),
    'FlatArmorMod': (Stat.armor, 1),
    'FlatSpellBlockMod': (Stat.magicResist, 1),
    'PercentAttackSpeedMod': (Stat.attackSpeed, 100),
    'FlatCritChanceMod': (Stat.critChance, 100),
    'FlatMovementSpeedMod': (Stat.moveSpeedFlat, 1),
    'PercentMovementSpeedMod': (Stat.moveSpeedPercent, 100),
    'PercentLifeStealMod': (Stat.lifeSteal, 100),
    'FlatHPRegenMod': (Stat.healthRegenFlat, 1),
  };

  static StatBag parse(String description, Map<String, dynamic>? stats) {
    final fromText = parseDescription(description);
    if (!fromText.isEmpty) return fromText;
    return parseLegacy(stats);
  }

  static StatBag parseDescription(String description) {
    final bag = StatBag();
    final block = _statsBlock.firstMatch(description)?.group(1);
    if (block == null) return bag;
    for (final raw in block.split(RegExp(r'<br\s*/?>', caseSensitive: false))) {
      final line = raw.replaceAll(_tag, '').trim();
      final m = _line.firstMatch(line);
      if (m == null) continue;
      final value = double.tryParse(m.group(1)!);
      if (value == null) continue;
      final isPercent = m.group(2) == '%';
      final entry = _names[m.group(3)!.trim().toLowerCase()];
      if (entry == null) continue;
      final stat = isPercent ? (entry.$2 ?? entry.$1) : (entry.$1 ?? entry.$2);
      if (stat != null) bag.add(stat, value);
    }
    return bag;
  }

  static StatBag parseLegacy(Map<String, dynamic>? stats) {
    final bag = StatBag();
    stats?.forEach((key, value) {
      final m = _legacy[key];
      if (m != null && value is num) bag.add(m.$1, value * m.$2);
    });
    return bag;
  }
}
