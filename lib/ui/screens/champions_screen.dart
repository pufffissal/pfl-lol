import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../../models/champion.dart';
import '../widgets/common.dart';
import 'champion_detail_screen.dart';

const championRoles = ['Fighter', 'Tank', 'Mage', 'Assassin', 'Marksman', 'Support'];

enum ChampionSort { name, difficulty, attack, defense, magic }

class ChampionsScreen extends ConsumerStatefulWidget {
  const ChampionsScreen({super.key});

  @override
  ConsumerState<ChampionsScreen> createState() => _ChampionsScreenState();
}

class _ChampionsScreenState extends ConsumerState<ChampionsScreen> {
  String _query = '';
  final Set<String> _roles = {};
  ChampionSort _sort = ChampionSort.name;

  List<ChampionSummary> _filter(List<ChampionSummary> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((c) {
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q) && !c.title.toLowerCase().contains(q)) {
        return false;
      }
      return _roles.isEmpty || c.tags.any(_roles.contains);
    }).toList();
    int by(ChampionSummary c) => switch (_sort) {
      ChampionSort.difficulty => c.info.difficulty,
      ChampionSort.attack => c.info.attack,
      ChampionSort.defense => c.info.defense,
      ChampionSort.magic => c.info.magic,
      ChampionSort.name => 0,
    };
    if (_sort != ChampionSort.name) {
      list.sort((a, b) {
        final c = by(b).compareTo(by(a));
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final champions = ref.watch(championsProvider);
    final images = ref.watch(imagesProvider);
    final patch = ref.watch(patchVersionProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Champions'),
        actions: [
          if (patch != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: Text('Patch $patch', style: Theme.of(context).textTheme.bodySmall)),
            ),
          PopupMenuButton<ChampionSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in ChampionSort.values) PopupMenuItem(value: s, child: Text('Sort by ${s.name}')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(hint: 'Search champions', onChanged: (v) => setState(() => _query = v)),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final role in championRoles)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(role),
                      selected: _roles.contains(role),
                      onSelected: (on) => setState(() => on ? _roles.add(role) : _roles.remove(role)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncView(
              value: champions,
              onRetry: () => ref.invalidate(versionsProvider),
              data: (all) {
                final list = _filter(all);
                if (list.isEmpty) return const Center(child: Text('No champions match.'));
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 96,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 104, // icon + one line of text
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => ChampionDetailScreen(championId: c.id))),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'champ-${c.id}',
                            child: GameIcon(images?.champion(c.imageFull), size: 72),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
