import 'package:flutter_test/flutter_test.dart';
import 'package:pfl_lol/logic/build_evaluator.dart';
import 'package:pfl_lol/logic/item_stats_parser.dart';
import 'package:pfl_lol/logic/stat_calculator.dart';
import 'package:pfl_lol/models/build.dart';
import 'package:pfl_lol/models/champion.dart';
import 'package:pfl_lol/models/item.dart';
import 'package:pfl_lol/models/rune.dart';
import 'package:pfl_lol/models/stat.dart';

/// Hand-written fixture in Data Dragon's format (values are illustrative).
final championJson = <String, dynamic>{
  'id': 'TestChamp',
  'key': '999',
  'name': 'Test Champ',
  'title': 'the Fixture',
  'tags': ['Marksman'],
  'partype': 'Mana',
  'image': {'full': 'TestChamp.png'},
  'info': {'attack': 8, 'defense': 3, 'magic': 2, 'difficulty': 5},
  'stats': {
    'hp': 600,
    'hpperlevel': 100,
    'mp': 300,
    'mpperlevel': 40,
    'movespeed': 330,
    'armor': 25,
    'armorperlevel': 4.5,
    'spellblock': 30,
    'spellblockperlevel': 1.3,
    'attackrange': 550,
    'hpregen': 3.5,
    'hpregenperlevel': 0.55,
    'mpregen': 7,
    'mpregenperlevel': 0.65,
    'crit': 0,
    'critperlevel': 0,
    'attackdamage': 60,
    'attackdamageperlevel': 2.5,
    'attackspeedperlevel': 3,
    'attackspeed': 0.625,
  },
};

Item item(String id, String desc, {int gold = 3000, List<String> tags = const []}) => Item.fromJson(id, {
  'name': 'Item $id',
  'description': desc,
  'gold': {'base': gold, 'total': gold, 'sell': gold * 0.7, 'purchasable': true},
  'tags': tags,
  'maps': {'11': true},
  'from': ['1036'],
});

void main() {
  group('growth curve', () {
    test('level 1 adds nothing, level 18 adds 17 x per-level', () {
      expect(StatCalculator.growth(1), 0);
      expect(StatCalculator.growth(18), closeTo(17, 1e-9));
      expect(StatCalculator.atLevel(600, 100, 18), closeTo(2300, 1e-9));
    });

    test('is not linear in between', () {
      // level 2: 1 * (0.7025 + 0.0175) = 0.72
      expect(StatCalculator.growth(2), closeTo(0.72, 1e-9));
    });
  });

  group('ItemStatsParser', () {
    test('parses the <stats> block of a modern description', () {
      const desc =
          '<mainText><stats><attention>55</attention> Attack Damage<br>'
          '<attention>20</attention> Ability Haste<br><attention>25%</attention> '
          'Critical Strike Chance<br><attention>18</attention> Lethality<br>'
          '<attention>4%</attention> Move Speed</stats><br><br><passive>X</passive></mainText>';
      final bag = ItemStatsParser.parseDescription(desc);
      expect(bag[Stat.attackDamage], 55);
      expect(bag[Stat.abilityHaste], 20);
      expect(bag[Stat.critChance], 25);
      expect(bag[Stat.lethality], 18);
      expect(bag[Stat.moveSpeedPercent], 4);
      expect(bag[Stat.moveSpeedFlat], 0);
    });

    test('distinguishes flat and percent magic penetration', () {
      final bag = ItemStatsParser.parseDescription(
        '<stats><attention>15</attention> Magic Penetration<br>'
        '<attention>40%</attention> Magic Penetration</stats>',
      );
      expect(bag[Stat.magicPenFlat], 15);
      expect(bag[Stat.magicPenPercent], 40);
    });

    test('falls back to the legacy stats object', () {
      final bag = ItemStatsParser.parse('no stats here', {
        'FlatHPPoolMod': 400,
        'PercentAttackSpeedMod': 0.25,
      });
      expect(bag[Stat.health], 400);
      expect(bag[Stat.attackSpeed], closeTo(25, 1e-9));
    });
  });

  group('StatCalculator', () {
    final champ = ChampionSummary.fromJson(championJson);

    test('level 1 with no items equals base stats', () {
      final s = StatCalculator.compute(base: champ.stats, level: 1, bonus: StatBag());
      expect(s.health.total, 600);
      expect(s.attackDamage.total, 60);
      expect(s.attackSpeed, closeTo(0.625, 1e-9));
      expect(s.moveSpeed, 330);
    });

    test('attack speed uses per-level growth and is capped', () {
      final s18 = StatCalculator.compute(base: champ.stats, level: 18, bonus: StatBag());
      // 0.625 * (1 + 3% * 17)
      expect(s18.attackSpeed, closeTo(0.625 * 1.51, 1e-9));
      final capped = StatCalculator.compute(
        base: champ.stats,
        level: 18,
        bonus: StatBag({Stat.attackSpeed: 500}),
      );
      expect(capped.attackSpeed, StatCalculator.attackSpeedCap);
    });

    test('adaptive force follows the larger bonus', () {
      final ad = StatCalculator.compute(
        base: champ.stats,
        level: 1,
        bonus: StatBag({Stat.adaptiveForce: 9, Stat.attackDamage: 10}),
      );
      expect(ad.attackDamage.bonus, closeTo(15.4, 1e-9));
      expect(ad.abilityPower.total, 0);
      final ap = StatCalculator.compute(
        base: champ.stats,
        level: 1,
        bonus: StatBag({Stat.adaptiveForce: 9, Stat.abilityPower: 10}),
      );
      expect(ap.abilityPower.total, 19);
    });

    test('move speed soft caps', () {
      expect(StatCalculator.applyMoveSpeedCaps(400), 400);
      expect(StatCalculator.applyMoveSpeedCaps(465), closeTo(455, 1e-9));
      expect(StatCalculator.applyMoveSpeedCaps(490), closeTo(475, 1e-9));
      expect(StatCalculator.applyMoveSpeedCaps(510), closeTo(485, 1e-9));
    });

    test('derived values', () {
      final s = StatCalculator.compute(
        base: champ.stats,
        level: 1,
        bonus: StatBag({Stat.abilityHaste: 100, Stat.critChance: 100}),
      );
      expect(s.cooldownReductionPercent, closeTo(50, 1e-9));
      expect(s.effectiveHealthPhysical, closeTo(600 * 1.25, 1e-9));
      expect(s.autoAttackDps, closeTo(60 * 0.625 * 1.75, 1e-9));
    });
  });

  group('BuildEvaluator', () {
    final champ = ChampionSummary.fromJson(championJson);
    final items = {
      '1': item('1', '<stats><attention>40</attention> Attack Damage</stats>'),
      '2': item('2', '<stats><attention>300</attention> Health</stats>', gold: 1000),
      'b': item('b', '<stats><attention>45</attention> Move Speed</stats>', gold: 1100, tags: ['Boots']),
    };

    test('sums items, shards and gold', () {
      final build = SavedBuild(
        id: 'x',
        name: 'x',
        championId: champ.id,
        level: 18,
        items: const ['1', '2', 'b', null, null, null],
        shards: const ['adaptive', 'ms', 'hp'],
        updatedAt: DateTime(2026),
      );
      final r = BuildEvaluator.evaluate(build: build, champion: champ, items: items);
      expect(r.totalGold, 5100);
      expect(r.stats.health.bonus, 365);
      expect(r.stats.attackDamage.bonus, closeTo(40 + 5.4, 1e-9));
      expect(r.stats.moveSpeed, closeTo((330 + 45) * 1.02, 1e-9));
      expect(r.warnings, isEmpty);
    });

    test('warns about two boots and duplicate legendaries', () {
      final build = SavedBuild(
        id: 'x',
        name: 'x',
        championId: champ.id,
        items: const ['1', '1', 'b', 'b', null, null],
        updatedAt: DateTime(2026),
      );
      final r = BuildEvaluator.evaluate(build: build, champion: champ, items: items);
      expect(r.warnings, hasLength(2));
    });
  });

  test('SavedBuild JSON round-trip', () {
    final b = SavedBuild(
      id: 'abc',
      name: 'Crit',
      championId: 'Jinx',
      level: 11,
      items: const ['3031', null, null, null, null, '3006'],
      summoners: const ['SummonerFlash', 'SummonerHeal'],
      runePage: const RunePage(primaryPathId: 8000, primaryRunes: [8008, 9111, 9104, 8014]),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    final back = SavedBuild.fromJson(b.toJson());
    expect(back.items, b.items);
    expect(back.level, 11);
    expect(back.runePage.primaryRunes, [8008, 9111, 9104, 8014]);
    expect(back.runePage.secondaryRunes, [null, null]);
    expect(back.updatedAt, b.updatedAt);
  });

  test('RunePath parsing', () {
    final p = RunePath.fromJson({
      'id': 8000,
      'key': 'Precision',
      'name': 'Precision',
      'icon': 'p.png',
      'slots': [
        {
          'runes': [
            {'id': 8005, 'key': 'PTA', 'name': 'Press the Attack', 'icon': 'a'},
          ],
        },
        {
          'runes': [
            {'id': 9111, 'key': 'T', 'name': 'Triumph', 'icon': 'b'},
          ],
        },
      ],
    });
    expect(p.keystones.single.name, 'Press the Attack');
    expect(p.rowOf(9111), 1);
    expect(p.findRune(42), isNull);
  });
}
