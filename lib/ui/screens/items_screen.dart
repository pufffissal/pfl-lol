import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../models/item.dart';
import '../widgets/common.dart';
import '../widgets/markup_text.dart';
import 'item_detail_screen.dart';

/// Display label -> Data Dragon item tag.
const itemCategories = <String, String>{
  'Attack Damage': 'Damage',
  'Crit': 'CriticalStrike',
  'Attack Speed': 'AttackSpeed',
  'On-Hit': 'OnHit',
  'Armor Pen': 'ArmorPenetration',
  'Life Steal': 'LifeSteal',
  'Ability Power': 'SpellDamage',
  'Magic Pen': 'MagicPenetration',
  'Mana': 'Mana',
  'Ability Haste': 'CooldownReduction',
  'Health': 'Health',
  'Armor': 'Armor',
  'Magic Resist': 'SpellBlock',
  'Move Speed': 'NonbootsMovement',
  'Boots': 'Boots',
  'Vision': 'Vision',
  'Consumable': 'Consumable',
};

const tierLabels = {
  ItemTier.legendary: 'Legendary',
  ItemTier.epic: 'Epic',
  ItemTier.basic: 'Basic',
  ItemTier.boots: 'Boots',
  ItemTier.starter: 'Starter',
  ItemTier.consumable: 'Consumable',
};

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Items')),
    body: ItemBrowser(
      onSelected: (item) =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id))),
    ),
  );
}

/// Searchable, filterable item grid. Used by the Items tab and the build
/// editor's item picker.
class ItemBrowser extends ConsumerStatefulWidget {
  const ItemBrowser({super.key, required this.onSelected, this.initialTiers});

  final ValueChanged<Item> onSelected;
  final Set<ItemTier>? initialTiers;

  @override
  ConsumerState<ItemBrowser> createState() => _ItemBrowserState();
}

class _ItemBrowserState extends ConsumerState<ItemBrowser> {
  String _query = '';
  final Set<String> _tags = {};
  late final Set<ItemTier> _tiers = {...?widget.initialTiers};

  bool _matches(Item i) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !i.name.toLowerCase().contains(q) &&
        !plainText(i.description).toLowerCase().contains(q)) {
      return false;
    }
    if (_tiers.isNotEmpty && !_tiers.contains(i.tier)) return false;
    return _tags.every(i.tags.contains);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shopItemsProvider);
    final images = ref.watch(imagesProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SearchField(hint: 'Search items or effects', onChanged: (v) => setState(() => _query = v)),
        ),
        _chipRow([
          for (final e in tierLabels.entries)
            FilterChip(
              label: Text(e.value),
              selected: _tiers.contains(e.key),
              onSelected: (on) => setState(() => on ? _tiers.add(e.key) : _tiers.remove(e.key)),
            ),
        ]),
        _chipRow([
          for (final e in itemCategories.entries)
            FilterChip(
              label: Text(e.key),
              selected: _tags.contains(e.value),
              onSelected: (on) => setState(() => on ? _tags.add(e.value) : _tags.remove(e.value)),
            ),
        ]),
        Expanded(
          child: AsyncView(
            value: items,
            onRetry: () => ref.invalidate(allItemsProvider),
            data: (all) {
              final list = all.where(_matches).toList();
              if (list.isEmpty) return const Center(child: Text('No items match.'));
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 84,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 124, // icon + two-line name + price
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final item = list[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onSelected(item),
                    child: Column(
                      children: [
                        GameIcon(images?.item(item.imageFull), size: 56),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        GoldText(item.goldTotal, style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chipRow(List<Widget> chips) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final c in chips) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c),
      ],
    ),
  );
}
