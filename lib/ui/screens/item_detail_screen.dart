import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/ddragon_api.dart';
import '../../data/providers.dart';
import '../../models/item.dart';
import '../widgets/common.dart';
import '../widgets/markup_text.dart';
import 'items_screen.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allItemsProvider);
    final images = ref.watch(imagesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(all.value?[itemId]?.name ?? 'Item')),
      body: AsyncView(
        value: all,
        onRetry: () => ref.invalidate(allItemsProvider),
        data: (items) {
          final item = items[itemId];
          if (item == null) return const Center(child: Text('Item not found in this patch.'));
          return _ItemBody(item: item, items: items, images: images);
        },
      ),
    );
  }
}

class _ItemBody extends StatelessWidget {
  const _ItemBody({required this.item, required this.items, required this.images});

  final Item item;
  final Map<String, Item> items;
  final DDragonImages? images;

  void _open(BuildContext context, String id) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: id)));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final into = item.into.where((id) => items[id]?.isOnSummonersRift ?? false).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: GameIcon(images?.item(item.imageFull), size: 64),
          title: Text(item.name, style: text.titleLarge),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GoldText(item.goldTotal, style: text.titleSmall),
                if (item.goldBase != item.goldTotal)
                  Text('(${item.goldBase} combine)', style: text.bodySmall),
                Text('Sells for ${item.goldSell}', style: text.bodySmall),
                Chip(label: Text(tierLabels[item.tier]!), visualDensity: VisualDensity.compact),
              ],
            ),
          ),
        ),
        if (item.plaintext.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(item.plaintext, style: text.bodyMedium!.copyWith(fontStyle: FontStyle.italic)),
          ),
        if (!item.stats.isEmpty) ...[
          const SectionTitle('Stats'),
          for (final e in item.stats.entries)
            ListTile(
              dense: true,
              title: Text(e.key.label),
              trailing: Text(
                '+${e.key.format(e.value)}',
                style: text.titleSmall!.copyWith(color: AppTheme.gold),
              ),
            ),
        ],
        const SectionTitle('Description'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MarkupText(item.description, style: text.bodyMedium!.copyWith(height: 1.45)),
        ),
        if (item.from.isNotEmpty) ...[
          const SectionTitle('Recipe'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _RecipeTree(
              itemId: item.id,
              items: items,
              images: images,
              onTap: (id) => _open(context, id),
            ),
          ),
        ],
        if (into.isNotEmpty) ...[
          const SectionTitle('Builds into'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in into)
                  _ItemChip(item: items[id]!, images: images, onTap: () => _open(context, id)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Recursive "builds from" tree, indented per depth.
class _RecipeTree extends StatelessWidget {
  const _RecipeTree({
    required this.itemId,
    required this.items,
    required this.images,
    required this.onTap,
    this.depth = 0,
  });

  final String itemId;
  final Map<String, Item> items;
  final DDragonImages? images;
  final ValueChanged<String> onTap;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final item = items[itemId];
    if (item == null || depth > 4) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in item.from)
          if (items[child] != null)
            Padding(
              padding: EdgeInsets.only(left: depth * 24.0, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ItemChip(item: items[child]!, images: images, onTap: () => onTap(child)),
                  _RecipeTree(itemId: child, items: items, images: images, onTap: onTap, depth: depth + 1),
                ],
              ),
            ),
      ],
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.item, required this.images, required this.onTap});

  final Item item;
  final DDragonImages? images;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(images?.item(item.imageFull), size: 32, radius: 6),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.bodySmall),
              GoldText(item.goldTotal, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    ),
  );
}
