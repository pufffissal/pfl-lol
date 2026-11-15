/// Rune trees from Data Dragon `runesReforged.json`.
class Rune {
  const Rune({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
    required this.shortDesc,
    required this.longDesc,
  });

  factory Rune.fromJson(Map<String, dynamic> j) => Rune(
    id: (j['id'] as num).toInt(),
    key: j['key'] as String? ?? '',
    name: j['name'] as String? ?? '',
    icon: j['icon'] as String? ?? '',
    shortDesc: j['shortDesc'] as String? ?? '',
    longDesc: j['longDesc'] as String? ?? '',
  );

  final int id;
  final String key, name;

  /// Path relative to `/cdn/img/`.
  final String icon;
  final String shortDesc, longDesc;
}

class RunePath {
  const RunePath({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
    required this.slots,
  });

  factory RunePath.fromJson(Map<String, dynamic> j) => RunePath(
    id: (j['id'] as num).toInt(),
    key: j['key'] as String? ?? '',
    name: j['name'] as String? ?? '',
    icon: j['icon'] as String? ?? '',
    slots: [
      for (final slot in (j['slots'] as List? ?? const []))
        [
          for (final r in ((slot as Map)['runes'] as List? ?? const []))
            Rune.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
    ],
  );

  final int id;
  final String key, name, icon;

  /// `slots[0]` holds keystones, `slots[1..3]` the minor rune rows.
  final List<List<Rune>> slots;

  List<Rune> get keystones => slots.isEmpty ? const [] : slots.first;

  Rune? findRune(int id) {
    for (final row in slots) {
      for (final r in row) {
        if (r.id == id) return r;
      }
    }
    return null;
  }

  /// Index of the row containing [runeId], or -1.
  int rowOf(int runeId) {
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].any((r) => r.id == runeId)) return i;
    }
    return -1;
  }
}
