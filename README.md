# PFL LoL

An unofficial League of Legends wiki and build calculator for Android, built with Flutter.

## Features

- **Champions**: search, filter by role, sort by ratings. Detail pages with lore, tips,
  abilities (cooldown, cost, range), stats at any level 1–18, and every skin's splash art.
- **Items**: Summoner's Rift shop items with search (names *and* effect text), tier and
  stat filters, stats, description, recursive recipe tree and "builds into".
- **Runes**: all rune paths, plus stat shards.
- **Summoner spells**.
- **Build calculator / custom builds**: pick a champion, level, 6 items, a full rune page,
  stat shards and summoner spells, and see the final stats: base, bonus and total, plus
  effective HP, auto-attack DPS, cooldown reduction from ability haste and damage after
  penetration. Builds are saved on the device.
- **Offline**: every downloaded patch file is cached, so the app works without a connection
  after the first load.
- **Settings**: game-data language (all Riot locales) and pinning an older patch.

## Data & legal

All game data and images come from Riot's public [Data Dragon](https://developer.riotgames.com/docs/lol#data-dragon) CDN
at runtime. The repository contains no Riot assets. The app shows Riot's required
"Legal Jibber Jabber" notice on the **More** screen. Under Riot's policy, fan projects
must stay free, or follow Riot's monetization rules if you add ads or paid features.

## Project layout

```
lib/
  models/      plain Dart data classes (champion, item, rune, build, stat)
  logic/       pure, unit-tested game math
               stat_calculator.dart   growth curve, AS cap, MS soft caps, adaptive force
               item_stats_parser.dart reads item stats from the description <stats> block
               build_evaluator.dart   build -> final stats, gold and warnings
               stat_shards.dart       shard values (not in Data Dragon; update by hand)
  data/        Data Dragon client with file cache + Riverpod providers
  ui/          screens and widgets
test/          logic tests + widget smoke tests using fixture data (no network)
```

The `logic/` and `models/` folders don't depend on Flutter, much like a plain Python module.
That makes them the easiest place to add game rules and test them.

## Running

```bash
flutter pub get
flutter test
flutter run            # with an Android device or emulator connected
flutter build apk      # build/app/outputs/flutter-apk/app-release.apk
```

Every push runs `.github/workflows/build.yml`, which analyzes and tests the code, builds a
release APK (signed with the debug key) and attaches it to the run as the `pfl-lol-apk` artifact.

## Known simplifications

- Item **passives/actives** (e.g. extra crit damage) are shown as text but not added to the
  numbers. Only the listed stats count.
- Attack speed uses the champion's base AS as the AS ratio, which is right for most champions.
- Ability damage numbers: Riot no longer ships reliable per-rank values in Data Dragon, so
  ability descriptions show `?` where a number would be.
