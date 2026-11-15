import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/providers.dart';
import '../widgets/common.dart';
import 'summoner_spells_screen.dart';

/// Riot's required notice for fan projects ("Legal Jibber Jabber" policy).
const riotDisclaimer =
    'PFL LoL isn\'t endorsed by Riot Games and doesn\'t reflect the views or '
    'opinions of Riot Games or anyone officially involved in producing or '
    'managing Riot Games properties. Riot Games, and all associated '
    'properties are trademarks or registered trademarks of Riot Games, Inc.';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final patch = ref.watch(patchVersionProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('Summoner spells'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SummonerSpellsScreen())),
          ),
          const SectionTitle('Data'),
          ListTile(
            leading: const Icon(Icons.update),
            title: const Text('Patch'),
            subtitle: Text(
              settings.pinnedVersion == null
                  ? 'Latest (${patch ?? '…'})'
                  : 'Pinned to ${settings.pinnedVersion}',
            ),
            onTap: () => _pickVersion(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Game data language'),
            subtitle: Text(settings.language),
            onTap: () => _pickLanguage(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear downloaded data'),
            subtitle: const Text('Data is re-downloaded on next use'),
            onTap: () async {
              await ref.read(ddragonApiProvider).clearCache();
              ref.invalidate(versionsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }
            },
          ),
          const SectionTitle('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('PFL LoL'),
            subtitle: const Text(
              'Unofficial League of Legends wiki and build calculator. '
              'Game data from Riot\'s public Data Dragon.',
            ),
            onTap: () => showLicensePage(context: context, applicationName: 'PFL LoL'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(riotDisclaimer, style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVersion(BuildContext context, WidgetRef ref) async {
    final versions = await ref.read(versionsProvider.future);
    if (!context.mounted) return;
    // Show only real patches (not the ancient "lolpatch_" entries).
    final list = versions.where((v) => RegExp(r'^\d+\.\d+\.\d+$').hasMatch(v)).take(40).toList();
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Patch'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, ''), child: const Text('Always latest')),
          for (final v in list)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, v), child: Text(v)),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setPinnedVersion(picked.isEmpty ? null : picked);
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    List<String> langs;
    try {
      langs = await ref.read(languagesProvider.future);
    } catch (_) {
      langs = const ['en_US'];
    }
    if (!context.mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Language'),
        children: [
          for (final l in langs)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, l), child: Text(l)),
        ],
      ),
    );
    if (picked != null) await ref.read(settingsProvider.notifier).setLanguage(picked);
  }
}
