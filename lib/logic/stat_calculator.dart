import 'dart:math' as math;

import '../models/champion.dart';
import '../models/stat.dart';

/// Base / bonus / total for one stat line.
class StatLine {
  const StatLine(this.label, this.base, this.bonus, {this.percent = false, this.decimals = 0});

  final String label;
  final double base, bonus;
  final bool percent;
  final int decimals;

  double get total => base + bonus;

  String fmt(double v) => '${v.toStringAsFixed(decimals)}${percent ? '%' : ''}';
}

class ComputedStats {
  ComputedStats({
    required this.level,
    required this.health,
    required this.mana,
    required this.attackDamage,
    required this.abilityPower,
    required this.armor,
    required this.magicResist,
    required this.attackSpeed,
    required this.bonusAttackSpeedPercent,
    required this.critChance,
    required this.critDamage,
    required this.moveSpeed,
    required this.attackRange,
    required this.healthRegen,
    required this.manaRegen,
    required this.abilityHaste,
    required this.lethality,
    required this.armorPenPercent,
    required this.magicPenFlat,
    required this.magicPenPercent,
    required this.lifeSteal,
    required this.omnivamp,
    required this.healShieldPower,
    required this.tenacity,
  });

  final int level;
  final StatLine health, mana, attackDamage, abilityPower, armor, magicResist;

  /// Final attacks per second (capped).
  final double attackSpeed;
  final double bonusAttackSpeedPercent;
  final double critChance, critDamage;

  /// Final move speed after soft caps.
  final double moveSpeed;
  final double attackRange;

  /// Per 5 seconds.
  final StatLine healthRegen, manaRegen;
  final double abilityHaste, lethality, armorPenPercent;
  final double magicPenFlat, magicPenPercent;
  final double lifeSteal, omnivamp, healShieldPower, tenacity;

  /// Cooldown reduction equivalent of ability haste, in percent.
  double get cooldownReductionPercent => 100 * abilityHaste / (abilityHaste + 100);

  /// Health needed to kill you with physical damage.
  double get effectiveHealthPhysical => _ehp(armor.total);
  double get effectiveHealthMagic => _ehp(magicResist.total);

  double _ehp(double resist) =>
      resist >= 0 ? health.total * (1 + resist / 100) : health.total * (2 - 100 / (100 - resist));

  /// Expected auto-attack damage per second against 0 armor.
  double get autoAttackDps {
    final crit = critChance.clamp(0, 100) / 100;
    return attackDamage.total * attackSpeed * (1 + crit * (critDamage / 100 - 1));
  }

  /// Damage multiplier of an auto attack against a target with [targetArmor]
  /// (after this build's lethality and armor penetration).
  double physicalMultiplierAgainst(double targetArmor) {
    var a = targetArmor * (1 - armorPenPercent / 100) - lethality;
    a = math.max(0, a);
    return 100 / (100 + a);
  }
}

class StatCalculator {
  static const attackSpeedCap = 2.5;
  static const baseCritDamage = 175.0;

  /// Riot's growth curve: stat = base + perLevel * growth(level).
  /// At level 1 growth is 0, at level 18 it is exactly 17.
  static double growth(int level) {
    final n = (level - 1).toDouble();
    return n * (0.7025 + 0.0175 * n);
  }

  static double atLevel(double base, double perLevel, int level) => base + perLevel * growth(level);

  /// Applies League's move speed soft caps.
  static double applyMoveSpeedCaps(double raw) {
    // 415..490 is scaled by 0.8 (=> 475 at 490), above 490 by 0.5.
    if (raw > 490) return 475 + (raw - 490) * 0.5;
    if (raw > 415) return 415 + (raw - 415) * 0.8;
    if (raw < 220) return 220 * 0.5 + raw * 0.5;
    return raw;
  }

  static ComputedStats compute({
    required BaseStats base,
    required int level,
    required StatBag bonus,
    bool prefersAd = false,
  }) {
    final lvl = level.clamp(1, 18);
    var bonusAd = bonus[Stat.attackDamage];
    var bonusAp = bonus[Stat.abilityPower];
    final adaptive = bonus[Stat.adaptiveForce];
    if (adaptive != 0) {
      final toAd = bonusAd > bonusAp || (bonusAd == bonusAp && prefersAd);
      if (toAd) {
        bonusAd += adaptive * 0.6;
      } else {
        bonusAp += adaptive;
      }
    }

    final baseHpRegen = atLevel(base.hpRegen, base.hpRegenPerLevel, lvl);
    final baseMpRegen = atLevel(base.mpRegen, base.mpRegenPerLevel, lvl);

    final bonusAsPct = base.attackSpeedPerLevel * growth(lvl) + bonus[Stat.attackSpeed];
    final as = math.min(attackSpeedCap, base.attackSpeed * (1 + bonusAsPct / 100));

    final rawMs = (base.moveSpeed + bonus[Stat.moveSpeedFlat]) * (1 + bonus[Stat.moveSpeedPercent] / 100);

    // Tenacity sources stack multiplicatively; we treat the sum as one source.
    return ComputedStats(
      level: lvl,
      health: StatLine('Health', atLevel(base.hp, base.hpPerLevel, lvl), bonus[Stat.health]),
      mana: StatLine('Mana', atLevel(base.mp, base.mpPerLevel, lvl), bonus[Stat.mana]),
      attackDamage: StatLine(
        'Attack Damage',
        atLevel(base.attackDamage, base.attackDamagePerLevel, lvl),
        bonusAd,
      ),
      abilityPower: StatLine('Ability Power', 0, bonusAp),
      armor: StatLine('Armor', atLevel(base.armor, base.armorPerLevel, lvl), bonus[Stat.armor]),
      magicResist: StatLine(
        'Magic Resist',
        atLevel(base.spellBlock, base.spellBlockPerLevel, lvl),
        bonus[Stat.magicResist],
      ),
      attackSpeed: as,
      bonusAttackSpeedPercent: bonusAsPct,
      critChance: math.min(100, base.crit + bonus[Stat.critChance]),
      critDamage: baseCritDamage + bonus[Stat.critDamage],
      moveSpeed: applyMoveSpeedCaps(rawMs),
      attackRange: base.attackRange,
      healthRegen: StatLine(
        'Health Regen /5s',
        baseHpRegen,
        baseHpRegen * bonus[Stat.baseHealthRegen] / 100 + bonus[Stat.healthRegenFlat],
        decimals: 1,
      ),
      manaRegen: StatLine(
        'Mana Regen /5s',
        baseMpRegen,
        baseMpRegen * bonus[Stat.baseManaRegen] / 100 + bonus[Stat.manaRegenFlat],
        decimals: 1,
      ),
      abilityHaste: bonus[Stat.abilityHaste],
      lethality: bonus[Stat.lethality],
      armorPenPercent: math.min(100, bonus[Stat.armorPenPercent]),
      magicPenFlat: bonus[Stat.magicPenFlat],
      magicPenPercent: math.min(100, bonus[Stat.magicPenPercent]),
      lifeSteal: bonus[Stat.lifeSteal],
      omnivamp: bonus[Stat.omnivamp],
      healShieldPower: bonus[Stat.healShieldPower],
      tenacity: math.min(100, bonus[Stat.tenacity]),
    );
  }
}
