import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'ui/screens/builds_screen.dart';
import 'ui/screens/champions_screen.dart';
import 'ui/screens/items_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/screens/runes_screen.dart';

class PflLolApp extends StatelessWidget {
  const PflLolApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PFL LoL',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark(),
    home: const HomeShell(),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [ChampionsScreen(), ItemsScreen(), RunesScreen(), BuildsScreen(), MoreScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    // IndexedStack keeps each tab's scroll position and filters.
    body: IndexedStack(index: _index, children: _tabs),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.person_search_outlined),
          selectedIcon: Icon(Icons.person_search),
          label: 'Champions',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag),
          label: 'Items',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Runes',
        ),
        NavigationDestination(
          icon: Icon(Icons.construction_outlined),
          selectedIcon: Icon(Icons.construction),
          label: 'Builds',
        ),
        NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    ),
  );
}
