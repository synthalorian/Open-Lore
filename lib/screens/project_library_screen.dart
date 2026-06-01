import 'package:flutter/material.dart';
import '../models/lore_entry.dart';
import '../services/world_storage.dart';
import '../theme/lore_theme.dart';
import 'world_screen.dart';

class ProjectLibraryScreen extends StatefulWidget {
  const ProjectLibraryScreen({super.key});

  @override
  State<ProjectLibraryScreen> createState() => _ProjectLibraryScreenState();
}

class _ProjectLibraryScreenState extends State<ProjectLibraryScreen> {
  List<WorldSummary>? _worlds;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorlds();
  }

  Future<void> _loadWorlds() async {
    setState(() { _loading = true; _error = null; });
    try {
      final worlds = await WorldStorage.listWorlds()
          .timeout(const Duration(seconds: 10));
      if (mounted) setState(() { _worlds = worlds; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _createNew() async {
    final nameCtl = TextEditingController(text: 'New World');
    final descCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LoreTheme.surface,
        title: const Text('New World', style: TextStyle(color: LoreTheme.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, autofocus: true,
                style: const TextStyle(color: LoreTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'World Name',
                    labelStyle: TextStyle(color: LoreTheme.textSecondary))),
            TextField(controller: descCtl,
                style: const TextStyle(color: LoreTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: LoreTheme.textSecondary))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (result != true || nameCtl.text.isEmpty) return;

    final project = WorldProject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameCtl.text,
      description: descCtl.text.isEmpty ? null : descCtl.text,
    );
    await WorldStorage.save(project);
    if (mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => WorldScreen(project: project)));
      _loadWorlds();
    }
  }

  Future<void> _openWorld(String id) async {
    final project = await WorldStorage.load(id);
    if (project != null && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => WorldScreen(project: project)));
      _loadWorlds();
    }
  }

  Future<void> _deleteWorld(WorldSummary s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LoreTheme.surface,
        title: const Text('Delete World', style: TextStyle(color: LoreTheme.ruby)),
        content: Text('Delete "${s.name}" and all its entries?',
            style: const TextStyle(color: LoreTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: LoreTheme.ruby),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) { await WorldStorage.delete(s.id); _loadWorlds(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoreTheme.background,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.auto_stories, color: LoreTheme.gold, size: 28),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OPEN LORE', style: TextStyle(color: LoreTheme.gold, fontSize: 22,
                        fontWeight: FontWeight.bold, letterSpacing: 4)),
                    Text('Game World Bible', style: TextStyle(color: LoreTheme.textSecondary, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _createNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New World'),
                  style: FilledButton.styleFrom(backgroundColor: LoreTheme.gold, foregroundColor: LoreTheme.ink),
                ),
              ],
            ),
          ),
          const Divider(color: LoreTheme.divider, height: 1),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: LoreTheme.gold));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: LoreTheme.ruby),
              const SizedBox(height: 16),
              const Text('Failed to load worlds', style: TextStyle(color: LoreTheme.textPrimary, fontSize: 18)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadWorlds,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: LoreTheme.gold, foregroundColor: LoreTheme.ink),
              ),
            ],
          ),
        ),
      );
    }
    if (_worlds == null || _worlds!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 72, color: LoreTheme.gold.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text('No worlds yet', style: TextStyle(color: LoreTheme.textSecondary, fontSize: 20)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createNew,
              icon: const Icon(Icons.add),
              label: const Text('Create World'),
              style: FilledButton.styleFrom(backgroundColor: LoreTheme.gold, foregroundColor: LoreTheme.ink),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 140),
      itemCount: _worlds!.length,
      itemBuilder: (_, i) {
        final w = _worlds![i];
        return _WorldCard(summary: w, onTap: () => _openWorld(w.id), onDelete: () => _deleteWorld(w));
      },
    );
  }
}

class _WorldCard extends StatelessWidget {
  final WorldSummary summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _WorldCard({required this.summary, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LoreTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LoreTheme.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_stories, color: LoreTheme.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(summary.name, style: const TextStyle(color: LoreTheme.textPrimary,
                  fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline, size: 16, color: LoreTheme.textSecondary)),
            ]),
            if (summary.description != null) ...[
              const SizedBox(height: 6),
              Text(summary.description!, style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: LoreTheme.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                child: Text('${summary.entryCount} entries', style: const TextStyle(color: LoreTheme.gold, fontSize: 10))),
            const SizedBox(height: 4),
            Text(_relativeDate(summary.modifiedAt), style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 10)),
          ]),
        ),
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
