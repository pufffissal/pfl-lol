import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../models/item.dart';
import '../../models/summoner_spell.dart';
import '../widgets/common.dart';
import 'items_screen.dart';

/// Full-screen champion chooser. Pops with the selected champion id.
class ChampionPickerScreen extends ConsumerStatefulWidget {
  const ChampionPickerScreen({super.key});

  @override
  ConsumerState<ChampionPickerScreen> createState() => _ChampionPickerScreenState();
}

class _ChampionPickerScreenState extends ConsumerState<ChampionPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final champions = ref.watch(championsProvider);
    final images = ref.watch(imagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a champion')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(hint: 'Search', onChanged: (v) => setState(() => _query = v)),
          ),
          Expanded(
            child: AsyncView(
              value: champions,
              onRetry: () => ref.invalidate(versionsProvider),
              data: (all) {
                final q = _query.toLowerCase();
                final list = all.where((c) => c.name.toLowerCase().contains(q)).toList();
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 88,
                    mainAxisExtent: 96,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => InkWell(
                    onTap: () => Navigator.of(context).pop(list[i].id),
                    child: Column(
                      children: [
                        GameIcon(images?.champion(list[i].imageFull), size: 64),
                        const SizedBox(height: 4),
                        Text(
                          list[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet item chooser. Resolves to the selected item.
Future<Item?> pickItem(BuildContext context) => showModalBottomSheet<Item>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.85,
    child: ItemBrowser(
      initialTiers: const {ItemTier.legendary, ItemTier.boots},
      onSelected: (item) => Navigator.of(context).pop(item),
    ),
  ),
);

/// Summoner spell chooser dialog.
Future<SummonerSpell?> pickSummonerSpell(BuildContext context, WidgetRef ref) => showDialog<SummonerSpell>(
  context: context,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final spells = ref.watch(summonerSpellsProvider).value ?? const [];
      final images = ref.watch(imagesProvider);
      return SimpleDialog(
        title: const Text('Summoner spell'),
        children: [
          for (final s in spells.where((s) => s.isClassic))
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(s),
              child: Row(
                children: [
                  GameIcon(images?.spell(s.imageFull), size: 36),
                  const SizedBox(width: 12),
                  Text(s.name),
                ],
              ),
            ),
        ],
      );
    },
  ),
);
