class SummonerSpell {
  const SummonerSpell({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.cooldownBurn,
    required this.summonerLevel,
    required this.modes,
    required this.imageFull,
  });

  factory SummonerSpell.fromJson(Map<String, dynamic> j) => SummonerSpell(
    id: j['id'] as String? ?? '',
    key: j['key'] as String? ?? '',
    name: j['name'] as String? ?? '',
    description: j['description'] as String? ?? '',
    cooldownBurn: j['cooldownBurn'] as String? ?? '',
    summonerLevel: (j['summonerLevel'] as num?)?.toInt() ?? 1,
    modes: List<String>.from(j['modes'] as List? ?? const []),
    imageFull: (j['image'] as Map?)?['full'] as String? ?? '',
  );

  final String id, key, name, description, cooldownBurn;
  final int summonerLevel;
  final List<String> modes;
  final String imageFull;

  bool get isClassic => modes.contains('CLASSIC');
}
