# Changelog

## v1.0.0 — Open Lore: Game World Bible

**Released:** 2026-05-31

### Features

- **Entry types** — characters, locations, factions, items, events, creatures, concepts, notes
- **Markdown editor** — rich content with title, tags, and custom properties
- **Bidirectional links** — typed relationships (ally of, located in, member of, etc.) with automatic backlink tracking
- **Properties system** — custom key-value metadata per entry (race, age, alignment, etc.)
- **Tag & search** — full-text search across titles, content, and tags
- **Type filtering** — sidebar with per-type counts and one-click filtering
- **Project library** — manage multiple worlds, each saved as JSON
- **Export** — copy full world JSON to clipboard for backup or sharing
- **Dangling link cleanup** — deleting an entry automatically removes all links pointing to it

### Architecture

- **1,293 lines** across 7 Dart files
- **Flutter** cross-platform: Linux, macOS, Windows, web, Android, iOS
- **JSON file storage** — worlds saved to `~/.openlore/worlds/`
- **Graph data model** — entries + typed directional links with backlink resolution
- **Synthwave theme** — deep purples, electric accents, dark surface palette

### Technical

- Migrated from `Lorekeeper` to `Open Lore` open-source branding
- Updated Android Gradle plugin and wrapper for modern toolchain compatibility
- Fixed deprecated Flutter API usage (`DropdownButtonFormField.value` → `initialValue`)
- Rebranded assistant credit: synthclaw → synthclaw

---

## v0.1.0 — Lorekeeper

**Released:** 2025-04-09

Initial release as `Lorekeeper` — a private game worldbuilding tool.

---

Made by **synth** with **synthclaw** 🎹🦈
