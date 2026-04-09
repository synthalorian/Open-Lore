import 'package:flutter_test/flutter_test.dart';
import 'package:open_lore/models/lore_entry.dart';

void main() {
  test('LoreEntry JSON roundtrip', () {
    final entry = LoreEntry(
      id: 'c1', title: 'Hero', type: EntryType.character,
      content: 'A brave warrior', tags: ['hero', 'warrior'],
      properties: {'race': 'Elf', 'age': '200'},
      links: [const LoreLink(targetId: 'l1', relation: LinkRelation.locatedIn)],
    );
    final json = entry.toJson();
    final restored = LoreEntry.fromJson(json);
    expect(restored.title, 'Hero');
    expect(restored.type, EntryType.character);
    expect(restored.tags, ['hero', 'warrior']);
    expect(restored.properties['race'], 'Elf');
    expect(restored.links.length, 1);
    expect(restored.links[0].relation, LinkRelation.locatedIn);
  });

  test('WorldProject JSON roundtrip', () {
    final project = WorldProject(id: '1', name: 'Test World', entries: [
      LoreEntry(id: 'e1', title: 'Place', type: EntryType.location),
      LoreEntry(id: 'e2', title: 'Person', type: EntryType.character,
          links: [const LoreLink(targetId: 'e1', relation: LinkRelation.locatedIn)]),
    ]);
    final json = project.toJson();
    final restored = WorldProject.fromJson(json);
    expect(restored.name, 'Test World');
    expect(restored.entries.length, 2);
    expect(restored.entries[1].links[0].targetId, 'e1');
  });

  test('WorldProject incoming links', () {
    final project = WorldProject(id: '1', name: 'Test', entries: [
      LoreEntry(id: 'a', title: 'A', type: EntryType.character),
      LoreEntry(id: 'b', title: 'B', type: EntryType.character,
          links: [const LoreLink(targetId: 'a', relation: LinkRelation.allyOf)]),
      LoreEntry(id: 'c', title: 'C', type: EntryType.faction,
          links: [const LoreLink(targetId: 'a', relation: LinkRelation.memberOf)]),
    ]);
    final incoming = project.incomingLinks('a');
    expect(incoming.length, 2);
  });

  test('WorldProject deleteEntry cleans up links', () {
    final project = WorldProject(id: '1', name: 'Test', entries: [
      LoreEntry(id: 'a', title: 'A', type: EntryType.character),
      LoreEntry(id: 'b', title: 'B', type: EntryType.character,
          links: [const LoreLink(targetId: 'a', relation: LinkRelation.allyOf)]),
    ]);
    project.deleteEntry('a');
    expect(project.entries.length, 1);
    expect(project.entries[0].links.length, 0);
  });

  test('WorldProject search', () {
    final project = WorldProject(id: '1', name: 'Test', entries: [
      LoreEntry(id: '1', title: 'Dragon', type: EntryType.creature, content: 'fire breathing'),
      LoreEntry(id: '2', title: 'Castle', type: EntryType.location, tags: ['dragon']),
    ]);
    expect(project.search('dragon').length, 2);
    expect(project.search('castle').length, 1);
  });
}
