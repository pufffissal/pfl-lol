import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/build.dart';
import '../models/champion.dart';
import '../models/item.dart';
import '../models/rune.dart';
import '../models/summoner_spell.dart';
import 'ddragon_api.dart';

/// Overridden in `main()` with an already-loaded instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

class AppSettings {
  const AppSettings({this.language = 'en_US', this.pinnedVersion});

  final String language;

  /// `null` means "always use the latest patch".
  final String? pinnedVersion;
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _langKey = 'settings.language';
  static const _versionKey = 'settings.pinnedVersion';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return AppSettings(
      language: prefs.getString(_langKey) ?? 'en_US',
      pinnedVersion: prefs.getString(_versionKey),
    );
  }

  Future<void> setLanguage(String lang) async {
    await _prefs.setString(_langKey, lang);
    state = AppSettings(language: lang, pinnedVersion: state.pinnedVersion);
  }

  Future<void> setPinnedVersion(String? version) async {
    if (version == null) {
      await _prefs.remove(_versionKey);
    } else {
      await _prefs.setString(_versionKey, version);
    }
    state = AppSettings(language: state.language, pinnedVersion: version);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ---------------------------------------------------------------------------
// Data Dragon
// ---------------------------------------------------------------------------

final ddragonApiProvider = Provider<DDragonApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return DDragonApi(client: client, cacheDir: getApplicationSupportDirectory().then<Directory?>((d) => d));
});

final versionsProvider = FutureProvider<List<String>>((ref) => ref.watch(ddragonApiProvider).versions());

final languagesProvider = FutureProvider<List<String>>((ref) => ref.watch(ddragonApiProvider).languages());

/// The patch currently shown in the app.
final patchVersionProvider = FutureProvider<String>((ref) async {
  final pinned = ref.watch(settingsProvider.select((s) => s.pinnedVersion));
  if (pinned != null) return pinned;
  final versions = await ref.watch(versionsProvider.future);
  return versions.first;
});

/// Image URL builder for the current patch, or `null` while loading.
final imagesProvider = Provider<DDragonImages?>((ref) {
  final v = ref.watch(patchVersionProvider).value;
  return v == null ? null : DDragonImages(v);
});

Future<Map<String, dynamic>> _patchData(Ref ref, String file) async {
  final version = await ref.watch(patchVersionProvider.future);
  final lang = ref.watch(settingsProvider.select((s) => s.language));
  return ref.watch(ddragonApiProvider).data(version, lang, file);
}

final championsProvider = FutureProvider<List<ChampionSummary>>((ref) async {
  final json = await _patchData(ref, 'champion.json');
  final data = Map<String, dynamic>.from(json['data'] as Map);
  final list = [for (final c in data.values) ChampionSummary.fromJson(Map<String, dynamic>.from(c as Map))]
    ..sort((a, b) => a.name.compareTo(b.name));
  return list;
});

final championsByIdProvider = FutureProvider<Map<String, ChampionSummary>>((ref) async {
  final list = await ref.watch(championsProvider.future);
  return {for (final c in list) c.id: c};
});

final championDetailProvider = FutureProvider.family<ChampionDetail, String>((ref, id) async {
  final json = await _patchData(ref, 'champion/$id.json');
  final data = Map<String, dynamic>.from(json['data'] as Map);
  return ChampionDetail.fromJson(Map<String, dynamic>.from(data[id] as Map));
});

/// Every item in the patch, keyed by id.
final allItemsProvider = FutureProvider<Map<String, Item>>((ref) async {
  final json = await _patchData(ref, 'item.json');
  final data = Map<String, dynamic>.from(json['data'] as Map);
  return {
    for (final e in data.entries) e.key: Item.fromJson(e.key, Map<String, dynamic>.from(e.value as Map)),
  };
});

/// Buyable Summoner's Rift items, sorted by cost then name, de-duplicated by
/// name (Data Dragon sometimes ships the same item under several ids).
final shopItemsProvider = FutureProvider<List<Item>>((ref) async {
  final all = await ref.watch(allItemsProvider.future);
  final byName = <String, Item>{};
  for (final item in all.values.where((i) => i.isShopItem)) {
    final existing = byName[item.name];
    if (existing == null || int.parse(item.id) < int.parse(existing.id)) {
      byName[item.name] = item;
    }
  }
  return byName.values.toList()..sort((a, b) {
    final c = a.goldTotal.compareTo(b.goldTotal);
    return c != 0 ? c : a.name.compareTo(b.name);
  });
});

final runePathsProvider = FutureProvider<List<RunePath>>((ref) async {
  final json = await _patchData(ref, 'runesReforged.json');
  return [for (final p in json['data'] as List) RunePath.fromJson(Map<String, dynamic>.from(p as Map))];
});

final summonerSpellsProvider = FutureProvider<List<SummonerSpell>>((ref) async {
  final json = await _patchData(ref, 'summoner.json');
  final data = Map<String, dynamic>.from(json['data'] as Map);
  return [for (final s in data.values) SummonerSpell.fromJson(Map<String, dynamic>.from(s as Map))]
    ..sort((a, b) => a.summonerLevel.compareTo(b.summonerLevel));
});

// ---------------------------------------------------------------------------
// Saved builds
// ---------------------------------------------------------------------------

class BuildsNotifier extends Notifier<List<SavedBuild>> {
  static const _key = 'builds.v1';
  static final _rng = Random();

  @override
  List<SavedBuild> build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = [
        for (final j in jsonDecode(raw) as List) SavedBuild.fromJson(Map<String, dynamic>.from(j as Map)),
      ];
      return list..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const [];
    }
  }

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rng.nextInt(1 << 20).toRadixString(36)}';

  Future<void> _persist(List<SavedBuild> builds) async {
    builds.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = List.unmodifiable(builds);
    await ref.read(sharedPrefsProvider).setString(_key, jsonEncode([for (final b in builds) b.toJson()]));
  }

  Future<void> save(SavedBuild build) async {
    final updated = build.copyWith(updatedAt: DateTime.now());
    final list = [...state.where((b) => b.id != build.id), updated];
    await _persist(list);
  }

  Future<void> delete(String id) => _persist([...state.where((b) => b.id != id)]);
}

final buildsProvider = NotifierProvider<BuildsNotifier, List<SavedBuild>>(BuildsNotifier.new);
