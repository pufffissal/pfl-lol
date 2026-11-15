/// A user-created build: champion + level + items + runes + summoners.
class RunePage {
  const RunePage({
    this.primaryPathId,
    this.primaryRunes = const [null, null, null, null],
    this.secondaryPathId,
    this.secondaryRunes = const [null, null],
  });

  factory RunePage.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const RunePage();
    List<int?> ints(Object? v, int len) {
      final list = [for (final x in (v as List? ?? const [])) (x as num?)?.toInt()];
      return [...list, ...List<int?>.filled(len, null)].take(len).toList();
    }

    return RunePage(
      primaryPathId: (j['primaryPathId'] as num?)?.toInt(),
      primaryRunes: ints(j['primaryRunes'], 4),
      secondaryPathId: (j['secondaryPathId'] as num?)?.toInt(),
      secondaryRunes: ints(j['secondaryRunes'], 2),
    );
  }

  final int? primaryPathId;

  /// Keystone followed by one rune for each of the 3 minor rows.
  final List<int?> primaryRunes;
  final int? secondaryPathId;

  /// Two runes from different minor rows of the secondary path.
  final List<int?> secondaryRunes;

  bool get isEmpty => primaryPathId == null && secondaryPathId == null;

  Map<String, dynamic> toJson() => {
    'primaryPathId': primaryPathId,
    'primaryRunes': primaryRunes,
    'secondaryPathId': secondaryPathId,
    'secondaryRunes': secondaryRunes,
  };
}

class SavedBuild {
  const SavedBuild({
    required this.id,
    required this.name,
    required this.championId,
    this.level = 18,
    this.items = const [null, null, null, null, null, null],
    this.shards = const [null, null, null],
    this.summoners = const [null, null],
    this.runePage = const RunePage(),
    this.notes = '',
    required this.updatedAt,
  });

  factory SavedBuild.fromJson(Map<String, dynamic> j) {
    List<String?> strs(Object? v, int len) {
      final list = [for (final x in (v as List? ?? const [])) x as String?];
      return [...list, ...List<String?>.filled(len, null)].take(len).toList();
    }

    return SavedBuild(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      championId: j['championId'] as String,
      level: (j['level'] as num?)?.toInt() ?? 18,
      items: strs(j['items'], 6),
      shards: strs(j['shards'], 3),
      summoners: strs(j['summoners'], 2),
      runePage: RunePage.fromJson(j['runePage'] as Map<String, dynamic>?),
      notes: j['notes'] as String? ?? '',
      updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String name;
  final String championId;
  final int level;

  /// Six inventory slots holding item ids.
  final List<String?> items;

  /// Stat shard ids for the offense / flex / defense rows.
  final List<String?> shards;

  /// Summoner spell ids, e.g. `SummonerFlash`.
  final List<String?> summoners;
  final RunePage runePage;
  final String notes;
  final DateTime updatedAt;

  SavedBuild copyWith({
    String? name,
    String? championId,
    int? level,
    List<String?>? items,
    List<String?>? shards,
    List<String?>? summoners,
    RunePage? runePage,
    String? notes,
    DateTime? updatedAt,
  }) => SavedBuild(
    id: id,
    name: name ?? this.name,
    championId: championId ?? this.championId,
    level: level ?? this.level,
    items: items ?? this.items,
    shards: shards ?? this.shards,
    summoners: summoners ?? this.summoners,
    runePage: runePage ?? this.runePage,
    notes: notes ?? this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'championId': championId,
    'level': level,
    'items': items,
    'shards': shards,
    'summoners': summoners,
    'runePage': runePage.toJson(),
    'notes': notes,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
