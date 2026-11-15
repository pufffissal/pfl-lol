import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pfl_lol/app.dart';
import 'package:pfl_lol/data/providers.dart';
import 'package:pfl_lol/models/champion.dart';
import 'package:pfl_lol/models/item.dart';
import 'package:pfl_lol/models/rune.dart';
import 'package:pfl_lol/models/summoner_spell.dart';
import 'package:pfl_lol/ui/screens/build_editor_screen.dart';
import 'package:pfl_lol/ui/screens/champion_detail_screen.dart';
import 'package:pfl_lol/ui/screens/item_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic_test.dart' show championJson;

final champ = ChampionSummary.fromJson(championJson);
final detail = ChampionDetail.fromJson({
  ...championJson,
  'lore': 'A <i>fixture</i> champion.',
  'allytips': ['Tip one'],
  'enemytips': ['Tip two'],
  'skins': [
    {'id': '999000', 'num': 0, 'name': 'default', 'chromas': false},
  ],
  'passive': {
    'name': 'Passive',
    'description': 'Does <magicDamage>things</magicDamage>.',
    'image': {'full': 'p.png'},
  },
  'spells': [
    for (final k in ['Q', 'W', 'E', 'R'])
      {
        'id': 'T$k',
        'name': 'Spell $k',
        'description': 'Deals {{ e1 }} damage.<br>More.',
        'maxrank': 5,
        'cooldownBurn': '10/9/8',
        'costBurn': '50',
        'rangeBurn': '600',
        'resource': '{{ cost }} {{ abilityresourcename }}',
        'image': {'full': '$k.png'},
      },
  ],
});

final items = {
  '1036': Item.fromJson('1036', {
    'name': 'Long Sword',
    'description': '<mainText><stats><attention>10</attention> Attack Damage</stats></mainText>',
    'gold': {'base': 350, 'total': 350, 'sell': 245, 'purchasable': true},
    'tags': ['Damage'],
    'maps': {'11': true},
    'into': ['3031'],
  }),
  '3031': Item.fromJson('3031', {
    'name': 'Big Crit Sword',
    'description':
        '<mainText><stats><attention>65</attention> Attack Damage<br>'
        '<attention>25%</attention> Critical Strike Chance</stats><br><br><passive>Edge</passive></mainText>',
    'gold': {'base': 2650, 'total': 3350, 'sell': 2345, 'purchasable': true},
    'tags': ['Damage', 'CriticalStrike'],
    'maps': {'11': true},
    'from': ['1036'],
  }),
};

final runePaths = [
  RunePath.fromJson({
    'id': 8000,
    'key': 'Precision',
    'name': 'Precision',
    'icon': 'p.png',
    'slots': [
      {
        'runes': [
          {'id': 8005, 'key': 'K', 'name': 'Keystone A', 'icon': 'a', 'shortDesc': 's', 'longDesc': 'l'},
        ],
      },
      {
        'runes': [
          {'id': 9111, 'key': 'R1', 'name': 'Rune One', 'icon': 'b', 'shortDesc': 's', 'longDesc': 'l'},
        ],
      },
    ],
  }),
];

final spells = [
  SummonerSpell.fromJson({
    'id': 'SummonerFlash',
    'key': '4',
    'name': 'Flash',
    'description': 'Blink.',
    'cooldownBurn': '300',
    'summonerLevel': 7,
    'modes': ['CLASSIC'],
    'image': {'full': 'f.png'},
  }),
];

Future<void> pumpApp(WidgetTester tester, Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.binding.setSurfaceSize(const Size(360, 1800));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        patchVersionProvider.overrideWith((ref) async => '99.1.1'),
        imagesProvider.overrideWithValue(null), // no network images in tests
        championsProvider.overrideWith((ref) async => [champ]),
        championDetailProvider.overrideWith((ref, id) async => detail),
        allItemsProvider.overrideWith((ref) async => items),
        runePathsProvider.overrideWith((ref) async => runePaths),
        summonerSpellsProvider.overrideWith((ref) async => spells),
      ],
      child: home is PflLolApp ? home : MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every tab renders', (tester) async {
    await pumpApp(tester, const PflLolApp());
    expect(find.text('Test Champ'), findsOneWidget);
    for (final tab in ['Items', 'Runes', 'Builds', 'More']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    expect(find.textContaining('isn\'t endorsed by Riot Games'), findsOneWidget);
  });

  testWidgets('champion detail tabs render', (tester) async {
    await pumpApp(tester, ChampionDetailScreen(championId: champ.id));
    expect(find.text('Ratings'.toUpperCase()), findsOneWidget);
    for (final tab in ['Abilities', 'Stats', 'Skins']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('item detail shows parsed stats and recipe', (tester) async {
    await pumpApp(tester, const ItemDetailScreen(itemId: '3031'));
    expect(find.text('Critical Strike Chance'), findsOneWidget);
    expect(find.text('+25%'), findsOneWidget);
    expect(find.text('Long Sword'), findsOneWidget);
  });

  testWidgets('build editor: add an item, totals update, save', (tester) async {
    await pumpApp(tester, BuildEditorScreen.newFor(champ.id));
    expect(find.text('FINAL STATS · LEVEL 18'), findsOneWidget);
    // Level 18 base health: 600 + 100 * 17 = 2300; flat 65 HP shard by default.
    expect(find.text('2365'), findsOneWidget);

    await tester.tap(find.byTooltip('Empty slot').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Big Crit Sword'));
    await tester.pumpAndSettle();
    expect(find.text('3350'), findsOneWidget); // total gold

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Build saved'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(BuildEditorScreen)));
    final saved = container.read(buildsProvider);
    expect(saved, hasLength(1));
    expect(saved.single.items.first, '3031');
  });
}
