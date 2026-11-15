import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/ddragon_api.dart';
import '../../data/providers.dart';
import '../../models/build.dart';
import '../../models/rune.dart';
import '../widgets/common.dart';
import 'runes_screen.dart';

/// Edits a [RunePage]; pops with the updated page.
class RunePageEditor extends ConsumerStatefulWidget {
  const RunePageEditor({super.key, required this.initial});

  final RunePage initial;

  @override
  ConsumerState<RunePageEditor> createState() => _RunePageEditorState();
}

class _RunePageEditorState extends ConsumerState<RunePageEditor> {
  late int? _primary = widget.initial.primaryPathId;
  late List<int?> _primaryRunes = [...widget.initial.primaryRunes];
  late int? _secondary = widget.initial.secondaryPathId;
  late List<int?> _secondaryRunes = [...widget.initial.secondaryRunes];

  RunePage get _page => RunePage(
    primaryPathId: _primary,
    primaryRunes: _primaryRunes,
    secondaryPathId: _secondary,
    secondaryRunes: _secondaryRunes,
  );

  void _setPrimary(int id) => setState(() {
    if (_primary == id) return;
    _primary = id;
    _primaryRunes = [null, null, null, null];
    if (_secondary == id) {
      _secondary = null;
      _secondaryRunes = [null, null];
    }
  });

  void _setSecondary(int id) => setState(() {
    if (_secondary == id) return;
    _secondary = id;
    _secondaryRunes = [null, null];
  });

  /// Secondary rules: two runes, from two different minor rows.
  void _toggleSecondary(RunePath path, Rune rune) => setState(() {
    final row = path.rowOf(rune.id);
    final current = _secondaryRunes.whereType<int>().toList();
    if (current.contains(rune.id)) {
      current.remove(rune.id);
    } else {
      current.removeWhere((id) => path.rowOf(id) == row);
      current.add(rune.id);
      if (current.length > 2) current.removeAt(0);
    }
    _secondaryRunes = [...current, null, null].take(2).toList();
  });

  @override
  Widget build(BuildContext context) {
    final paths = ref.watch(runePathsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rune page'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(_page), child: const Text('Done'))],
      ),
      body: AsyncView(
        value: paths,
        onRetry: () => ref.invalidate(runePathsProvider),
        data: (paths) {
          RunePath? find(int? id) => paths.where((p) => p.id == id).firstOrNull;
          final primary = find(_primary);
          final secondary = find(_secondary);
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const SectionTitle('Primary path'),
              _PathSelector(paths: paths, selected: _primary, onSelected: _setPrimary),
              if (primary != null)
                for (var row = 0; row < primary.slots.length && row < 4; row++)
                  _RuneRow(
                    runes: primary.slots[row],
                    large: row == 0,
                    isSelected: (r) => _primaryRunes[row] == r.id,
                    onTap: (r) => setState(() => _primaryRunes[row] = r.id),
                  ),
              const SectionTitle('Secondary path'),
              _PathSelector(
                paths: paths.where((p) => p.id != _primary).toList(),
                selected: _secondary,
                onSelected: _setSecondary,
              ),
              if (secondary != null)
                for (var row = 1; row < secondary.slots.length; row++)
                  _RuneRow(
                    runes: secondary.slots[row],
                    isSelected: (r) => _secondaryRunes.contains(r.id),
                    onTap: (r) => _toggleSecondary(secondary, r),
                  ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Long-press any rune to read its full description.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PathSelector extends StatelessWidget {
  const _PathSelector({required this.paths, required this.selected, required this.onSelected});

  final List<RunePath> paths;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in paths)
          ChoiceChip(
            avatar: GameIcon(DDragonImages.rune(p.icon), size: 20, circle: true),
            label: Text(p.name),
            selected: p.id == selected,
            onSelected: (_) => onSelected(p.id),
          ),
      ],
    ),
  );
}

class _RuneRow extends StatelessWidget {
  const _RuneRow({required this.runes, required this.isSelected, required this.onTap, this.large = false});

  final List<Rune> runes;
  final bool Function(Rune) isSelected;
  final ValueChanged<Rune> onTap;
  final bool large;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final r in runes)
          Tooltip(
            message: r.name,
            child: GestureDetector(
              onTap: () => onTap(r),
              onLongPress: () => showRuneDetails(context, r),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isSelected(r) ? 1 : 0.35,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected(r) ? AppTheme.gold : Colors.transparent, width: 2),
                  ),
                  child: GameIcon(DDragonImages.rune(r.icon), size: large ? 52 : 40, circle: true),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
