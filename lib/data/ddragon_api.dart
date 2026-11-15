import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Client for Riot's public Data Dragon CDN with an offline file cache.
///
/// Patch data is immutable per version, so once a file is cached for a
/// version + language it is never fetched again.
class DDragonApi {
  DDragonApi({required this.client, required this.cacheDir});

  static const host = 'https://ddragon.leagueoflegends.com';

  final http.Client client;

  /// Root directory for cached JSON. `null` disables disk caching.
  final Future<Directory?> cacheDir;

  Future<File?> _file(String relative) async {
    final dir = await cacheDir;
    if (dir == null) return null;
    return File('${dir.path}/ddragon/$relative');
  }

  Future<Object?> _getJson(Uri uri) async {
    final res = await client.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}', uri: uri);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Fetches a mutable index (version list, languages): network first,
  /// falling back to the last cached copy when offline.
  Future<Object?> _networkFirst(String path, String cacheName) async {
    final file = await _file(cacheName);
    try {
      final data = await _getJson(Uri.parse('$host$path'));
      if (file != null) {
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(data));
      }
      return data;
    } catch (_) {
      if (file != null && await file.exists()) {
        return jsonDecode(await file.readAsString());
      }
      rethrow;
    }
  }

  /// All patch versions, newest first.
  Future<List<String>> versions() async {
    final data = await _networkFirst('/api/versions.json', 'versions.json');
    return List<String>.from(data as List);
  }

  Future<List<String>> languages() async {
    final data = await _networkFirst('/cdn/languages.json', 'languages.json');
    return List<String>.from(data as List);
  }

  /// A data file such as `champion.json` or `champion/Ahri.json`.
  /// Cache first, since patch files never change.
  Future<Map<String, dynamic>> data(String version, String lang, String file) async {
    final cached = await _file('$version/$lang/$file');
    if (cached != null && await cached.exists()) {
      try {
        return _asMap(jsonDecode(await cached.readAsString()));
      } catch (_) {
        await cached.delete(); // corrupt; refetch below
      }
    }
    final json = await _getJson(Uri.parse('$host/cdn/$version/data/$lang/$file'));
    if (cached != null) {
      await cached.parent.create(recursive: true);
      await cached.writeAsString(jsonEncode(json));
    }
    return _asMap(json);
  }

  /// `runesReforged.json` is a top-level list; wrap it so [data] stays typed.
  Map<String, dynamic> _asMap(Object? json) => json is Map<String, dynamic> ? json : {'data': json};

  Future<void> clearCache() async {
    final dir = await cacheDir;
    if (dir == null) return;
    final root = Directory('${dir.path}/ddragon');
    if (await root.exists()) await root.delete(recursive: true);
  }
}

/// Image URLs for a given patch.
class DDragonImages {
  const DDragonImages(this.version);

  final String version;

  String champion(String imageFull) => '${DDragonApi.host}/cdn/$version/img/champion/$imageFull';
  String item(String imageFull) => '${DDragonApi.host}/cdn/$version/img/item/$imageFull';
  String spell(String imageFull) => '${DDragonApi.host}/cdn/$version/img/spell/$imageFull';
  String passive(String imageFull) => '${DDragonApi.host}/cdn/$version/img/passive/$imageFull';

  /// Rune and rune-path icons are not versioned.
  static String rune(String icon) => '${DDragonApi.host}/cdn/img/$icon';
  static String splash(String championId, int skinNum) =>
      '${DDragonApi.host}/cdn/img/champion/splash/${championId}_$skinNum.jpg';
  static String loading(String championId, int skinNum) =>
      '${DDragonApi.host}/cdn/img/champion/loading/${championId}_$skinNum.jpg';
}
