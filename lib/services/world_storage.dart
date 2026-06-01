import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/lore_entry.dart';

class WorldStorage {
  static String? _cachedBasePath;

  static Future<String> get _basePath async {
    if (_cachedBasePath != null) return _cachedBasePath!;

    String base;
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      base = p.join(dir.path, 'openlore', 'worlds');
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final home = Platform.environment['HOME']
          ?? Platform.environment['USERPROFILE']
          ?? '.';
      base = p.join(home, '.openlore', 'worlds');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      base = p.join(dir.path, 'openlore', 'worlds');
    }

    _cachedBasePath = base;
    return base;
  }

  static Future<void> _ensureDir() async {
    final dir = Directory(await _basePath);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  static Future<String> _filePath(String id) async =>
      p.join(await _basePath, '$id.json');

  static Future<void> save(WorldProject project) async {
    await _ensureDir();
    project.modifiedAt = DateTime.now();
    final json = const JsonEncoder.withIndent('  ').convert(project.toJson());
    await File(await _filePath(project.id)).writeAsString(json);
  }

  static Future<WorldProject?> load(String id) async {
    final file = File(await _filePath(id));
    if (!await file.exists()) return null;
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return WorldProject.fromJson(json);
  }

  static Future<List<WorldSummary>> listWorlds() async {
    await _ensureDir();
    final dir = Directory(await _basePath);
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
    final file = File(await _filePath(id));
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
