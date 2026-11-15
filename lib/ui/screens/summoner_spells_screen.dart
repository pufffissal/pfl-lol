import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../widgets/common.dart';
import '../widgets/markup_text.dart';

class SummonerSpellsScreen extends ConsumerWidget {
  const SummonerSpellsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spells = ref.watch(summonerSpellsProvider);
    final images = ref.watch(imagesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Summoner Spells')),
      body: AsyncView(
        value: spells,
        onRetry: () => ref.invalidate(summonerSpellsProvider),
        data: (all) {
          final list = all.where((s) => s.isClassic).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GameIcon(images?.spell(s.imageFull), size: 52),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              'Cooldown ${s.cooldownBurn}s · Unlocks at level ${s.summonerLevel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            MarkupText(s.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
