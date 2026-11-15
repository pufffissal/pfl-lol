import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/ddragon_api.dart';
import '../../data/providers.dart';
import '../../logic/build_evaluator.dart';
import '../../logic/stat_calculator.dart';
import '../../logic/stat_shards.dart';
import '../../models/build.dart';
import '../../models/champion.dart';
import '../../models/item.dart';
import '../../models/rune.dart';
import '../../models/summoner_spell.dart';
import '../widgets/common.dart';
import 'pickers.dart';
import 'rune_page_editor.dart';

class BuildEditorScreen extends ConsumerStatefulWidget {
  /// Edit an existing saved build.
  const BuildEditorScreen({super.key, required SavedBuild this.initial}) : championId = null;

  /// Start a new build for [championId].
  const BuildEditorScreen.newFor(String this.championId, {super.key}) : initial = null;

  final SavedBuild? initial;
  final String? championId;

  @override
  ConsumerState<BuildEditorScreen> createState() => _BuildEditorScreenState();
}

class _BuildEditorScreenState extends ConsumerState<BuildEditorScreen> {
  late SavedBuild _build =
      widget.initial ??
      SavedBuild(
        id: BuildsNotifier.newId(),
        name: '',
        championId: widget.championId!,
        shards: const ['adaptive', 'adaptive', 'hp'],
        summoners: const ['SummonerFlash', null],
        updatedAt: DateTime.now(),
      );
  late final _nameController = TextEditingController(text: _build.name);
  late final _notesController = TextEditingController(text: _build.notes);
  bool _dirty = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _update(SavedBuild b) => setState(() {
    _build = b;
    _dirty = true;
  });

  Future<void> _save(ChampionSummary champion) async {
    final name = _nameController.text.trim();
    final toSave = _build.copyWith(
      name: name.isEmpty ? '${champion.name} build' : name,
      notes: _notesController.text,
    );
    await ref.read(buildsProvider.notifier).save(toSave);
    if (!mounted) return;
    setState(() {
      _build = toSave;
      _dirty = false;
    });
    _nameController.text = toSave.name;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Build saved')));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('This build has unsaved changes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final champions = ref.watch(championsByIdProvider);
    final items = ref.watch(allItemsProvider);
    final images = ref.watch(imagesProvider);

    final champion = champions.value?[_build.championId];
    final itemMap = items.value;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initial == null ? 'New build' : 'Edit build'),
          actions: [
            if (champion != null)
              IconButton(
                tooltip: 'Save',
                icon: Icon(_dirty ? Icons.save : Icons.save_outlined),
                onPressed: () => _save(champion),
              ),
          ],
        ),
        body: champion == null || itemMap == null
            ? AsyncView(
                value: champions.hasError ? champions : items,
                onRetry: () => ref.invalidate(versionsProvider),
                data: (_) => const Center(child: Text('Champion not found in this patch.')),
              )
            : _body(context, champion, itemMap, images),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ChampionSummary champion,
    Map<String, Item> itemMap,
    DDragonImages? images,
  ) {
    final result = BuildEvaluator.evaluate(build: _build, champion: champion, items: itemMap);
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        // --- Champion & name ------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final id = await Navigator.of(context)
                      .push<String>(MaterialPageRoute(builder: (_) => const ChampionPickerScreen()));
                  if (id != null) _update(_build.copyWith(championId: id));
                },
                child: Stack(
                  children: [
                    GameIcon(images?.champion(champion.imageFull), size: 64),
                    const Positioned(
                      right: 2,
                      bottom: 2,
                      child: Icon(Icons.swap_horiz, size: 18, color: AppTheme.gold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() => _dirty = true),
                  decoration: InputDecoration(hintText: '${champion.name} build', labelText: 'Build name'),
                ),
              ),
            ],
          ),
        ),

        // --- Level ------------------------------------------------------------
        SectionTitle('Level ${_build.level}'),
        Slider(
          value: _build.level.toDouble(),
          min: 1,
          max: 18,
          divisions: 17,
          label: '${_build.level}',
          onChanged: (v) => _update(_build.copyWith(level: v.round())),
        ),

        // --- Items --------------------------------------------------------------
        SectionTitle('Items', trailing: GoldText(result.totalGold, style: text.titleSmall)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (var i = 0; i < 6; i++) _itemSlot(i, itemMap, images)],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            'Tap a slot to choose an item, long-press to clear it.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),

        // --- Summoners & runes -----------------------------------------------
        const SectionTitle('Summoner spells & runes'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var i = 0; i < 2; i++)
                Padding(padding: const EdgeInsets.only(right: 8), child: _summonerSlot(i, images)),
              const SizedBox(width: 8),
              Expanded(child: _runeSummary(context)),
            ],
          ),
        ),

        // --- Stat shards ----------------------------------------------------
        const SectionTitle('Stat shards'),
        for (var row = 0; row < statShardRows.length; row++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Wrap(
              spacing: 6,
              children: [
                for (final s in statShardRows[row])
                  ChoiceChip(
                    label: Text(s.label, style: const TextStyle(fontSize: 12)),
                    selected: _build.shards[row] == s.id,
                    onSelected: (on) {
                      final shards = [..._build.shards];
                      shards[row] = on ? s.id : null;
                      _update(_build.copyWith(shards: shards));
                    },
                  ),
              ],
            ),
          ),

        if (result.warnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              color: Colors.orange.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final w in result.warnings)
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(child: Text(w)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

        // --- Final stats --------------------------------------------------------
        SectionTitle('Final stats · level ${result.stats.level}'),
        _FinalStatsTable(stats: result.stats),
        const SectionTitle('At a glance'),
        _DerivedStats(stats: result.stats),

        // --- Notes ----------------------------------------------------------
        const SectionTitle('Notes'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 6,
            onChanged: (_) => setState(() => _dirty = true),
            decoration: const InputDecoration(hintText: 'Matchups, skill order, power spikes...'),
          ),
        ),
      ],
    );
  }

  Widget _itemSlot(int i, Map<String, Item> itemMap, DDragonImages? images) {
    final item = itemMap[_build.items[i]];
    void set(String? id) {
      final items = [..._build.items];
      items[i] = id;
      _update(_build.copyWith(items: items));
    }

    return Tooltip(
      message: item?.name ?? 'Empty slot',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await pickItem(context);
          if (picked != null) set(picked.id);
        },
        onLongPress: item == null ? null : () => set(null),
        child: item == null ? const EmptySlot(size: 50) : GameIcon(images?.item(item.imageFull), size: 50),
      ),
    );
  }

  Widget _summonerSlot(int i, DDragonImages? images) {
    final spells = ref.watch(summonerSpellsProvider).value ?? const <SummonerSpell>[];
    final spell = spells.where((s) => s.id == _build.summoners[i]).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await pickSummonerSpell(context, ref);
        if (picked == null) return;
        final list = [..._build.summoners];
        // Picking the spell held in the other slot swaps them.
        final other = 1 - i;
        if (list[other] == picked.id) list[other] = list[i];
        list[i] = picked.id;
        _update(_build.copyWith(summoners: list));
      },
      child: spell == null
          ? const EmptySlot(size: 44, icon: Icons.bolt)
          : GameIcon(images?.spell(spell.imageFull), size: 44),
    );
  }

  Widget _runeSummary(BuildContext context) {
    final paths = ref.watch(runePathsProvider).value ?? const <RunePath>[];
    final page = _build.runePage;
    RunePath? path(int? id) => paths.where((p) => p.id == id).firstOrNull;
    final primary = path(page.primaryPathId);
    final secondary = path(page.secondaryPathId);
    final keystone = page.primaryRunes.first == null ? null : primary?.findRune(page.primaryRunes.first!);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final updated = await Navigator.of(context)
            .push<RunePage>(MaterialPageRoute(builder: (_) => RunePageEditor(initial: page)));
        if (updated != null) _update(_build.copyWith(runePage: updated));
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            keystone == null
                ? const EmptySlot(size: 32, icon: Icons.auto_awesome, circle: true)
                : GameIcon(DDragonImages.rune(keystone.icon), size: 32, circle: true),
            if (secondary != null) ...[
              const SizedBox(width: 4),
              GameIcon(DDragonImages.rune(secondary.icon), size: 20, circle: true),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                keystone?.name ?? (primary?.name ?? 'Choose runes'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalStatsTable extends StatelessWidget {
  const _FinalStatsTable({required this.stats});

  final ComputedStats stats;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dim = text.bodySmall!.copyWith(color: Colors.white54);
    final bonus = text.bodySmall!.copyWith(color: const Color(0xFF5FD068));

    TableRow row(String label, String base, String plus, String total) => TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(label)),
        Text(base, style: dim, textAlign: TextAlign.end),
        Text(plus, style: bonus, textAlign: TextAlign.end),
        Text(total, style: text.titleSmall, textAlign: TextAlign.end),
      ],
    );

    TableRow line(StatLine l) =>
        row(l.label, l.fmt(l.base), l.bonus == 0 ? '' : '+${l.fmt(l.bonus)}', l.fmt(l.total));

    String pct(double v) => '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}%';

    final extras = <(String, String)>[
      ('Attack Speed', stats.attackSpeed.toStringAsFixed(3)),
      ('Bonus Attack Speed', pct(stats.bonusAttackSpeedPercent)),
      ('Crit Chance', pct(stats.critChance)),
      ('Move Speed', stats.moveSpeed.toStringAsFixed(0)),
      ('Attack Range', stats.attackRange.toStringAsFixed(0)),
      ('Ability Haste', stats.abilityHaste.toStringAsFixed(0)),
      if (stats.lethality > 0) ('Lethality', stats.lethality.toStringAsFixed(0)),
      if (stats.armorPenPercent > 0) ('Armor Penetration', pct(stats.armorPenPercent)),
      if (stats.magicPenFlat > 0) ('Magic Penetration', stats.magicPenFlat.toStringAsFixed(0)),
      if (stats.magicPenPercent > 0) ('Magic Penetration', pct(stats.magicPenPercent)),
      if (stats.lifeSteal > 0) ('Life Steal', pct(stats.lifeSteal)),
      if (stats.omnivamp > 0) ('Omnivamp', pct(stats.omnivamp)),
      if (stats.healShieldPower > 0) ('Heal & Shield Power', pct(stats.healShieldPower)),
      if (stats.tenacity > 0) ('Tenacity', pct(stats.tenacity)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              row('', 'Base', 'Bonus', 'Total'),
              line(stats.health),
              if (stats.mana.total > 0) line(stats.mana),
              line(stats.attackDamage),
              line(stats.abilityPower),
              line(stats.armor),
              line(stats.magicResist),
              line(stats.healthRegen),
              if (stats.manaRegen.total > 0) line(stats.manaRegen),
            ],
          ),
          const Divider(height: 24),
          for (final (label, value) in extras)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(label)),
                  Text(value, style: text.titleSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DerivedStats extends StatelessWidget {
  const _DerivedStats({required this.stats});

  final ComputedStats stats;

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, IconData icon, {String? hint}) => Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.gold),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            if (hint != null)
              Text(hint, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: Colors.white38)),
          ],
        ),
      ),
    );

    final tiles = [
      tile('Effective HP vs physical', stats.effectiveHealthPhysical.toStringAsFixed(0), Icons.shield),
      tile('Effective HP vs magic', stats.effectiveHealthMagic.toStringAsFixed(0), Icons.auto_fix_high),
      tile(
        'Auto-attack DPS',
        stats.autoAttackDps.toStringAsFixed(0),
        Icons.flash_on,
        hint: 'vs 0 armor, no on-hit',
      ),
      tile(
        'Cooldown reduction',
        '${stats.cooldownReductionPercent.toStringAsFixed(1)}%',
        Icons.timer,
        hint: 'from ${stats.abilityHaste.toStringAsFixed(0)} ability haste',
      ),
      tile(
        'Auto damage vs 100 armor',
        '${(stats.physicalMultiplierAgainst(100) * 100).toStringAsFixed(0)}%',
        Icons.gps_fixed,
        hint: 'after penetration',
      ),
      tile('Attacks per second', stats.attackSpeed.toStringAsFixed(2), Icons.speed),
    ];

    // Two columns whose height follows the content, so long labels or large
    // system font sizes wrap instead of overflowing.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in tiles) SizedBox(width: (constraints.maxWidth - 8) / 2, child: t)],
        ),
      ),
    );
  }
}
