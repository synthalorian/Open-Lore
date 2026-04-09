import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/lore_entry.dart';

class WorldStorage {
  static String get _basePath {
    final home = Platform.environment['HOME'] ?? '.';
    return p.join(home, '.openlore', 'worlds');
  }

  static Future<void> _ensureDir() async {
    final dir = Directory(_basePath);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  static String _filePath(String id) => p.join(_basePath, '$id.json');

  static Future<void> save(WorldProject project) async {
    await _ensureDir();
    project.modifiedAt = DateTime.now();
    final json = const JsonEncoder.withIndent('  ').convert(project.toJson());
    await File(_filePath(project.id)).writeAsString(json);
  }

  static Future<WorldProject?> load(String id) async {
    final file = File(_filePath(id));
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return WorldProject.fromJson(json);
  }

  static Future<List<WorldSummary>> listWorlds() async {
    await _ensureDir();
    final dir = Directory(_basePath);
    final summaries = <WorldSummary>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
          summaries.add(WorldSummary(
            id: json['id'] as String,
            name: json['name'] as String,
            description: json['description'] as String?,
            entryCount: (json['entries'] as List?)?.length ?? 0,
            modifiedAt: DateTime.parse(json['modifiedAt'] as String),
          ));
        } catch (_) {}
      }
    }
    summaries.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return summaries;
  }

  static Future<void> delete(String id) async {
    final file = File(_filePath(id));
    if (await file.exists()) await file.delete();
  }

  static Future<String> exportJson(WorldProject project) async {
    return const JsonEncoder.withIndent('  ').convert(project.toJson());
  }
}

class WorldSummary {
  final String id;
  final String name;
  final String? description;
  final int entryCount;
  final DateTime modifiedAt;

  const WorldSummary({
    required this.id,
    required this.name,
    this.description,
    required this.entryCount,
    required this.modifiedAt,
  });
}
