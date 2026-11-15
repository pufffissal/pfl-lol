/// Every stat the build calculator knows how to sum.
enum Stat {
  health('Health'),
  mana('Mana'),
  attackDamage('Attack Damage'),
  abilityPower('Ability Power'),
  armor('Armor'),
  magicResist('Magic Resist'),
  attackSpeed('Attack Speed', percent: true),
  critChance('Critical Strike Chance', percent: true),
  moveSpeedFlat('Move Speed'),
  moveSpeedPercent('Move Speed', percent: true),
  abilityHaste('Ability Haste'),
  lethality('Lethality'),
  armorPenPercent('Armor Penetration', percent: true),
  magicPenFlat('Magic Penetration'),
  magicPenPercent('Magic Penetration', percent: true),
  lifeSteal('Life Steal', percent: true),
  omnivamp('Omnivamp', percent: true),
  healShieldPower('Heal and Shield Power', percent: true),
  baseHealthRegen('Base Health Regen', percent: true),
  baseManaRegen('Base Mana Regen', percent: true),
  healthRegenFlat('Health Regen'),
  manaRegenFlat('Mana Regen'),
  tenacity('Tenacity', percent: true),
  slowResist('Slow Resist', percent: true),
  critDamage('Critical Strike Damage', percent: true),
  adaptiveForce('Adaptive Force');

  const Stat(this.label, {this.percent = false});

  final String label;

  /// Percent stats are stored as percentage points (25 means 25%).
  final bool percent;

  String format(double value) {
    final v = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
    return percent ? '$v%' : v;
  }
}

/// A bag of stat values that can be added together.
class StatBag {
  StatBag([Map<Stat, double>? values]) : _v = {...?values};

  final Map<Stat, double> _v;

  double operator [](Stat s) => _v[s] ?? 0;
  void add(Stat s, double value) => _v[s] = this[s] + value;

  void addAll(StatBag other) {
    for (final e in other.entries) {
      add(e.key, e.value);
    }
  }

  Iterable<MapEntry<Stat, double>> get entries => _v.entries.where((e) => e.value != 0);

  bool get isEmpty => entries.isEmpty;
}
