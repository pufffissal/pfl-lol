import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/ddragon_api.dart';
import '../../data/providers.dart';
import '../../logic/stat_shards.dart';
import '../../models/rune.dart';
import '../widgets/common.dart';
import '../widgets/markup_text.dart';

class RunesScreen extends ConsumerWidget {
  const RunesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(runePathsProvider);
    return AsyncView(
      value: paths,
      onRetry: () => ref.invalidate(runePathsProvider),
      data: (paths) => DefaultTabController(
        length: paths.length + 1,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Runes'),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final p in paths)
                  Tab(icon: GameIcon(DDragonImages.rune(p.icon), size: 24, circle: true), text: p.name),
                const Tab(icon: Icon(Icons.tune, size: 24), text: 'Shards'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              for (final p in paths) _PathView(path: p),
              const _ShardsView(),
            ],
          ),
        ),
      ),
    );
  }
}

void showRuneDetails(BuildContext context, Rune rune) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            children: [
              GameIcon(DDragonImages.rune(rune.icon), size: 56, circle: true),
              const SizedBox(width: 16),
              Expanded(child: Text(rune.name, style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: 16),
          MarkupText(rune.longDesc, style: Theme.of(context).textTheme.bodyMedium!.copyWith(height: 1.45)),
        ],
      ),
    ),
  );
}

class _PathView extends StatelessWidget {
  const _PathView({required this.path});

  final RunePath path;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      for (var row = 0; row < path.slots.length; row++) ...[
        SectionTitle(row == 0 ? 'Keystones' : 'Row $row'),
        for (final r in path.slots[row])
          ListTile(
            leading: GameIcon(DDragonImages.rune(r.icon), size: row == 0 ? 48 : 36, circle: true),
            title: Text(r.name),
            subtitle: MarkupText(r.shortDesc, maxLines: 3),
            onTap: () => showRuneDetails(context, r),
          ),
      ],
    ],
  );
}

class _ShardsView extends StatelessWidget {
  const _ShardsView();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Text(
          'Stat shards are not part of the official data files, so they are '
          'kept in the app and may lag behind a balance patch.',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      for (var i = 0; i < statShardRows.length; i++) ...[
        SectionTitle(statShardRowNames[i]),
        for (final s in statShardRows[i])
          ListTile(
            leading: const Icon(Icons.hexagon_outlined, color: AppTheme.gold),
            title: Text(s.label),
          ),
      ],
    ],
  );
}
