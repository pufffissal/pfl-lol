import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/ddragon_api.dart';
import '../../data/providers.dart';
import '../../logic/stat_calculator.dart';
import '../../models/champion.dart';
import '../../models/stat.dart';
import '../widgets/common.dart';
import '../widgets/markup_text.dart';
import 'build_editor_screen.dart';

class ChampionDetailScreen extends ConsumerWidget {
  const ChampionDetailScreen({super.key, required this.championId});

  final String championId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(championDetailProvider(championId));
    return Scaffold(
      body: AsyncView(
        value: detail,
        onRetry: () => ref.invalidate(championDetailProvider(championId)),
        data: (c) => _ChampionBody(champion: c),
      ),
      floatingActionButton: detail.hasValue
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.construction),
              label: const Text('Create build'),
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => BuildEditorScreen.newFor(championId))),
            )
          : null,
    );
  }
}

class _ChampionBody extends ConsumerWidget {
  const _ChampionBody({required this.champion});

  final ChampionDetail champion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = champion.summary;
    final images = ref.watch(imagesProvider);
    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 62),
              title: Text(s.name, style: const TextStyle(shadows: [Shadow(blurRadius: 8)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: DDragonImages.splash(s.id, 0),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorWidget: (_, _, _) => const SizedBox(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.navy],
                        stops: [0.45, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Abilities'),
                Tab(text: 'Stats'),
                Tab(text: 'Skins'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _OverviewTab(champion: champion, images: images),
            _AbilitiesTab(champion: champion, images: images),
            _StatsTab(champion: s),
            _SkinsTab(champion: champion),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.champion, required this.images});

  final ChampionDetail champion;
  final DDragonImages? images;

  @override
  Widget build(BuildContext context) {
    final s = champion.summary;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ListTile(
          leading: Hero(tag: 'champ-${s.id}', child: GameIcon(images?.champion(s.imageFull))),
          title: Text(s.title, style: text.titleMedium),
          subtitle: Text('${s.tags.join(' · ')}  ·  ${s.partype}'),
        ),
        const SectionTitle('Ratings'),
        _Rating('Attack', s.info.attack, const Color(0xFFFF8C34)),
        _Rating('Defense', s.info.defense, const Color(0xFF5FD068)),
        _Rating('Magic', s.info.magic, const Color(0xFF6FA8FF)),
        _Rating('Difficulty', s.info.difficulty, const Color(0xFFC77DFF)),
        const SectionTitle('Lore'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MarkupText(champion.lore, style: text.bodyMedium!.copyWith(height: 1.5)),
        ),
        if (champion.allyTips.isNotEmpty) ...[
          const SectionTitle('Playing as'),
          for (final t in champion.allyTips) _Tip(t),
        ],
        if (champion.enemyTips.isNotEmpty) ...[
          const SectionTitle('Playing against'),
          for (final t in champion.enemyTips) _Tip(t),
        ],
      ],
    );
  }
}

class _Rating extends StatelessWidget {
  const _Rating(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 84, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10,
              minHeight: 8,
              color: color,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
        SizedBox(width: 32, child: Text('$value', textAlign: TextAlign.end)),
      ],
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3, right: 8),
          child: Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.gold),
        ),
        Expanded(child: MarkupText(text)),
      ],
    ),
  );
}

class _AbilitiesTab extends StatelessWidget {
  const _AbilitiesTab({required this.champion, required this.images});

  final ChampionDetail champion;
  final DDragonImages? images;

  static const _keys = ['Q', 'W', 'E', 'R'];

  String _cost(ChampionSpell sp, String partype) {
    if (sp.costBurn == '0' || sp.costBurn.isEmpty) return 'No cost';
    final res = sp.resource
        .replaceAll(RegExp(r'\{\{\s*cost\s*\}\}'), sp.costBurn)
        .replaceAll(RegExp(r'\{\{\s*abilityresourcename\s*\}\}'), partype);
    return plainText(res.isEmpty ? '${sp.costBurn} $partype' : res);
  }

  @override
  Widget build(BuildContext context) {
    final p = champion.passive;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        _AbilityCard(
          keyLabel: 'P',
          name: p.name,
          icon: images?.passive(p.imageFull),
          description: p.description,
          facts: const [],
        ),
        for (var i = 0; i < champion.spells.length; i++)
          _AbilityCard(
            keyLabel: i < _keys.length ? _keys[i] : '',
            name: champion.spells[i].name,
            icon: images?.spell(champion.spells[i].imageFull),
            description: champion.spells[i].description,
            facts: [
              ('Cooldown', '${champion.spells[i].cooldownBurn}s'),
              ('Cost', _cost(champion.spells[i], champion.summary.partype)),
              ('Range', champion.spells[i].rangeBurn),
            ],
          ),
      ],
    );
  }
}

class _AbilityCard extends StatelessWidget {
  const _AbilityCard({
    required this.keyLabel,
    required this.name,
    required this.icon,
    required this.description,
    required this.facts,
  });

  final String keyLabel, name, description;
  final String? icon;
  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GameIcon(icon, size: 52),
                      Positioned(
                        right: -6,
                        bottom: -6,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: AppTheme.gold,
                          child: Text(
                            keyLabel,
                            style: const TextStyle(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(name, style: text.titleMedium)),
                ],
              ),
              if (facts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    for (final (label, value) in facts)
                      if (value.isNotEmpty)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$label: ',
                                style: text.bodySmall!.copyWith(color: Colors.white54),
                              ),
                              TextSpan(text: value, style: text.bodySmall),
                            ],
                          ),
                        ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              MarkupText(description, style: text.bodyMedium!.copyWith(height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsTab extends StatefulWidget {
  const _StatsTab({required this.champion});

  final ChampionSummary champion;

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  int _level = 1;

  @override
  Widget build(BuildContext context) {
    final b = widget.champion.stats;
    final s = StatCalculator.compute(base: b, level: _level, bonus: StatBag());
    String per(double v, [int d = 1]) => v == 0 ? '' : '+${v.toStringAsFixed(d)}';
    final rows = <(String, String, String)>[
      ('Health', s.health.total.toStringAsFixed(0), per(b.hpPerLevel, 0)),
      if (b.mp > 0) (widget.champion.partype, s.mana.total.toStringAsFixed(0), per(b.mpPerLevel, 0)),
      ('Attack Damage', s.attackDamage.total.toStringAsFixed(1), per(b.attackDamagePerLevel)),
      (
        'Attack Speed',
        s.attackSpeed.toStringAsFixed(3),
        b.attackSpeedPerLevel == 0 ? '' : '+${b.attackSpeedPerLevel}%',
      ),
      ('Armor', s.armor.total.toStringAsFixed(1), per(b.armorPerLevel)),
      ('Magic Resist', s.magicResist.total.toStringAsFixed(1), per(b.spellBlockPerLevel, 2)),
      ('Move Speed', s.moveSpeed.toStringAsFixed(0), ''),
      ('Attack Range', s.attackRange.toStringAsFixed(0), ''),
      ('Health Regen /5s', s.healthRegen.total.toStringAsFixed(1), per(b.hpRegenPerLevel, 2)),
      if (b.mpRegen > 0) ('Mana Regen /5s', s.manaRegen.total.toStringAsFixed(1), per(b.mpRegenPerLevel, 2)),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        SectionTitle('Level $_level'),
        Slider(
          value: _level.toDouble(),
          min: 1,
          max: 18,
          divisions: 17,
          label: '$_level',
          onChanged: (v) => setState(() => _level = v.round()),
        ),
        for (final (label, value, growth) in rows)
          ListTile(
            dense: true,
            title: Text(label),
            trailing: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: value, style: Theme.of(context).textTheme.titleSmall),
                  if (growth.isNotEmpty)
                    TextSpan(
                      text: '   $growth/lvl',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SkinsTab extends StatelessWidget {
  const _SkinsTab({required this.champion});

  final ChampionDetail champion;

  @override
  Widget build(BuildContext context) {
    final id = champion.summary.id;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: champion.skins.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final skin = champion.skins[i];
        final name = skin.name == 'default' ? champion.summary.name : skin.name;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.all(8),
                clipBehavior: Clip.antiAlias,
                child: InteractiveViewer(
                  child: CachedNetworkImage(imageUrl: DDragonImages.splash(id, skin.number)),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1215 / 717,
                  child: CachedNetworkImage(
                    imageUrl: DDragonImages.splash(id, skin.number),
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ColoredBox(color: Colors.white10),
                    errorWidget: (_, _, _) => const ColoredBox(color: Colors.white10),
                  ),
                ),
                ListTile(
                  title: Text(name),
                  trailing: skin.hasChromas
                      ? const Chip(label: Text('Chromas'), visualDensity: VisualDensity.compact)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
