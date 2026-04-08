import 'package:flutter/material.dart';
import '../theme/lore_theme.dart';

enum EntryType {
  character('Character', Icons.person, LoreTheme.ruby),
  location('Location', Icons.place, LoreTheme.emerald),
  faction('Faction', Icons.groups, LoreTheme.sapphire),
  item('Item', Icons.inventory_2, LoreTheme.gold),
  event('Event', Icons.event, LoreTheme.amethyst),
  creature('Creature', Icons.pets, LoreTheme.ruby),
  concept('Concept', Icons.lightbulb, LoreTheme.gold),
  note('Note', Icons.note, LoreTheme.textSecondary);

  final String label;
  final IconData icon;
  final Color color;
  const EntryType(this.label, this.icon, this.color);

  static EntryType fromName(String name) =>
      EntryType.values.firstWhere((t) => t.name == name, orElse: () => EntryType.note);
}

enum LinkRelation {
  relatedTo('Related to'),
  locatedIn('Located in'),
  memberOf('Member of'),
  allyOf('Ally of'),
  enemyOf('Enemy of'),
  createdBy('Created by'),
  owns('Owns'),
  parentOf('Parent of'),
  childOf('Child of'),
  rulerOf('Ruler of');

  final String label;
  const LinkRelation(this.label);

  static LinkRelation fromName(String name) =>
      LinkRelation.values.firstWhere((r) => r.name == name, orElse: () => LinkRelation.relatedTo);
}

class LoreLink {
  final String targetId;
  final LinkRelation relation;
  final String? description;

  const LoreLink({required this.targetId, required this.relation, this.description});

  Map<String, dynamic> toJson() => {
        'targetId': targetId,
        'relation': relation.name,
        'description': description,
      };

  factory LoreLink.fromJson(Map<String, dynamic> json) => LoreLink(
        targetId: json['targetId'] as String,
        relation: LinkRelation.fromName(json['relation'] as String),
        description: json['description'] as String?,
      );
}

class LoreEntry {
  final String id;
  String title;
  EntryType type;
  String content;
  final List<String> tags;
  final Map<String, String> properties;
  final List<LoreLink> links;
  final DateTime createdAt;
  DateTime modifiedAt;

  LoreEntry({
    required this.id,
    required this.title,
    required this.type,
    this.content = '',
    List<String>? tags,
    Map<String, String>? properties,
    List<LoreLink>? links,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : tags = tags ?? [],
        properties = properties ?? {},
        links = links ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'content': content,
        'tags': tags,
        'properties': properties,
        'links': links.map((l) => l.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory LoreEntry.fromJson(Map<String, dynamic> json) => LoreEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        type: EntryType.fromName(json['type'] as String),
        content: json['content'] as String? ?? '',
        tags: List<String>.from(json['tags'] as List? ?? []),
        properties: Map<String, String>.from(json['properties'] as Map? ?? {}),
        links: (json['links'] as List?)
                ?.map((l) => LoreLink.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      );
}

class WorldProject {
  final String id;
  String name;
  String? description;
  final List<LoreEntry> entries;
  final DateTime createdAt;
  DateTime modifiedAt;

  WorldProject({
    required this.id,
    required this.name,
    this.description,
    List<LoreEntry>? entries,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : entries = entries ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  List<LoreEntry> entriesByType(EntryType type) =>
      entries.where((e) => e.type == type).toList();

  LoreEntry? findById(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Get all entries that link TO this entry (incoming/backlinks)
  List<MapEntry<LoreEntry, LoreLink>> incomingLinks(String entryId) {
    final results = <MapEntry<LoreEntry, LoreLink>>[];
    for (final entry in entries) {
      for (final link in entry.links) {
        if (link.targetId == entryId) {
          results.add(MapEntry(entry, link));
        }
      }
    }
    return results;
  }

  void deleteEntry(String id) {
    entries.removeWhere((e) => e.id == id);
    // Clean up dangling links
    for (final entry in entries) {
      entry.links.removeWhere((l) => l.targetId == id);
    }
  }

  List<LoreEntry> search(String query) {
    final q = query.toLowerCase();
    return entries
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'entries': entries.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory WorldProject.fromJson(Map<String, dynamic> json) => WorldProject(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        entries: (json['entries'] as List?)
                ?.map((e) => LoreEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      );
}
