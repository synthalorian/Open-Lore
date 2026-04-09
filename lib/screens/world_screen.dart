import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lore_entry.dart';
import '../services/world_storage.dart';
import '../theme/lore_theme.dart';
import 'entry_screen.dart';

class WorldScreen extends StatefulWidget {
  final WorldProject project;
  const WorldScreen({super.key, required this.project});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  late WorldProject _project;
  EntryType? _filterType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  Future<void> _save() async {
    await WorldStorage.save(_project);
  }

  Future<void> _export() async {
    final json = await WorldStorage.exportJson(_project);
    await Clipboard.setData(ClipboardData(text: json));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('World JSON copied to clipboard')),
      );
    }
  }

  List<LoreEntry> get _filteredEntries {
    var entries = _project.entries;
    if (_filterType != null) {
      entries = entries.where((e) => e.type == _filterType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries.where((e) =>
          e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q) ||
          e.tags.any((t) => t.toLowerCase().contains(q))).toList();
    }
    return entries;
  }

  void _addEntry() {
    final entry = LoreEntry(
      id: 'e${DateTime.now().millisecondsSinceEpoch}',
      title: 'New ${(_filterType ?? EntryType.note).label}',
      type: _filterType ?? EntryType.note,
    );
    setState(() => _project.entries.add(entry));
    _save();
    _openEntry(entry);
  }

  void _openEntry(LoreEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryScreen(
          entry: entry,
          project: _project,
          onSaved: () {
            setState(() {});
            _save();
          },
        ),
      ),
    );
    setState(() {});
  }

  void _deleteEntry(LoreEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LoreTheme.surface,
        title: const Text('Delete Entry', style: TextStyle(color: LoreTheme.ruby)),
        content: Text('Delete "${entry.title}"? Links to this entry will also be removed.',
            style: const TextStyle(color: LoreTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: LoreTheme.ruby),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _project.deleteEntry(entry.id));
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: LoreTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        color: LoreTheme.textSecondary,
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_project.name,
                            style: const TextStyle(color: LoreTheme.gold, fontSize: 13,
                                fontWeight: FontWeight.bold, letterSpacing: 1),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const Divider(color: LoreTheme.divider, height: 1),
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () { _save(); ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Saved "${_project.name}"'), duration: const Duration(seconds: 1))); },
                          icon: const Icon(Icons.save, size: 14),
                          label: const Text('Save', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(foregroundColor: LoreTheme.gold, padding: EdgeInsets.zero),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _export,
                          icon: const Icon(Icons.file_download, size: 14),
                          label: const Text('Export', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(foregroundColor: LoreTheme.textSecondary, padding: EdgeInsets.zero),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: LoreTheme.divider, height: 1),
                // Type filters
                _FilterItem(
                  label: 'All Entries', icon: Icons.book, color: LoreTheme.parchment,
                  count: _project.entries.length, selected: _filterType == null,
                  onTap: () => setState(() => _filterType = null),
                ),
                ...EntryType.values.map((type) => _FilterItem(
                      label: '${type.label}s', icon: type.icon, color: type.color,
                      count: _project.entriesByType(type).length, selected: _filterType == type,
                      onTap: () => setState(() => _filterType = _filterType == type ? null : type),
                    )),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: LoreTheme.divider),
          // Main content
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: LoreTheme.surface,
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: LoreTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search entries...', hintStyle: const TextStyle(color: LoreTheme.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: LoreTheme.textSecondary),
                      filled: true, fillColor: LoreTheme.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredEntries.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_filterType?.icon ?? Icons.book, size: 64, color: LoreTheme.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text('No entries', style: TextStyle(color: LoreTheme.textSecondary, fontSize: 18)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            return _EntryCard(
                              entry: entry,
                              linkCount: entry.links.length + _project.incomingLinks(entry.id).length,
                              onTap: () => _openEntry(entry),
                              onDelete: () => _deleteEntry(entry),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: LoreTheme.gold,
        foregroundColor: LoreTheme.ink,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterItem({required this.label, required this.icon, required this.color,
      required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(0.1) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Icon(icon, size: 18, color: selected ? color : LoreTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(color: selected ? color : LoreTheme.textPrimary,
                fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal))),
            Text('$count', style: TextStyle(color: selected ? color : LoreTheme.textSecondary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final LoreEntry entry;
  final int linkCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.linkCount, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: entry.type.color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Icon(entry.type.icon, color: entry.type.color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.title, style: const TextStyle(color: LoreTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                if (entry.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(entry.content.length > 80 ? '${entry.content.substring(0, 80)}...' : entry.content,
                      style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 12)),
                ],
                if (entry.tags.isNotEmpty || linkCount > 0) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    ...entry.tags.take(3).map((tag) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: entry.type.color.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                          child: Text(tag, style: TextStyle(color: entry.type.color, fontSize: 10)),
                        )),
                    if (linkCount > 0) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.link, size: 12, color: LoreTheme.textSecondary.withOpacity(0.6)),
                      Text(' $linkCount', style: TextStyle(color: LoreTheme.textSecondary.withOpacity(0.6), fontSize: 10)),
                    ],
                  ]),
                ],
              ]),
            ),
            PopupMenuButton<String>(
              iconSize: 18,
              onSelected: (v) { if (v == 'delete') onDelete(); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))],
            ),
          ]),
        ),
      ),
    );
  }
}
