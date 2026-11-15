import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../models/build.dart';
import '../widgets/common.dart';
import 'build_editor_screen.dart';
import 'pickers.dart';

class BuildsScreen extends ConsumerWidget {
  const BuildsScreen({super.key});

  Future<void> _newBuild(BuildContext context) async {
    final id = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const ChampionPickerScreen()));
    if (id == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => BuildEditorScreen.newFor(id)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builds = ref.watch(buildsProvider);
    final champions = ref.watch(championsByIdProvider).value ?? const {};
    final items = ref.watch(allItemsProvider).value ?? const {};
    final images = ref.watch(imagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Builds')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newBuild(context),
        icon: const Icon(Icons.add),
        label: const Text('New build'),
      ),
      body: builds.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No builds yet.\nCreate one to see a champion\'s final stats '
                  'with your items, runes and level.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: builds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = builds[i];
                final champ = champions[b.championId];
                return Dismissible(
                  key: ValueKey(b.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete),
                  ),
                  onDismissed: (_) => _delete(context, ref, b),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => BuildEditorScreen(initial: b))),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GameIcon(champ == null ? null : images?.champion(champ.imageFull), size: 56),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text(
                                    '${champ?.name ?? b.championId} · level ${b.level}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      for (final id in b.items.whereType<String>())
                                        if (items[id] != null)
                                          GameIcon(images?.item(items[id]!.imageFull), size: 26, radius: 4),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, SavedBuild b) {
    final notifier = ref.read(buildsProvider.notifier);
    notifier.delete(b.id);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${b.name}"'),
          action: SnackBarAction(label: 'Undo', onPressed: () => notifier.save(b)),
        ),
      );
  }
}
