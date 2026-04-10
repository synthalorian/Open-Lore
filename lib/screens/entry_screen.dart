import 'package:flutter/material.dart';
import '../models/lore_entry.dart';
import '../theme/lore_theme.dart';

class EntryScreen extends StatefulWidget {
  final LoreEntry entry;
  final WorldProject project;
  final VoidCallback onSaved;

  const EntryScreen({super.key, required this.entry, required this.project, required this.onSaved});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late TextEditingController _titleCtl;
  late TextEditingController _contentCtl;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.entry.title);
    _contentCtl = TextEditingController(text: widget.entry.content);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _contentCtl.dispose();
    super.dispose();
  }

  void _save() {
    widget.entry.title = _titleCtl.text;
    widget.entry.content = _contentCtl.text;
    widget.entry.modifiedAt = DateTime.now();
    widget.onSaved();
  }

  void _addTag() async {
    final ctl = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LoreTheme.surface,
        title: const Text('Add Tag', style: TextStyle(color: LoreTheme.gold)),
        content: TextField(controller: ctl, autofocus: true,
            style: const TextStyle(color: LoreTheme.textPrimary),
            onSubmitted: (v) => Navigator.pop(ctx, v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctl.text), child: const Text('Add')),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty) {
      setState(() => widget.entry.tags.add(tag));
      _save();
    }
  }

  void _addProperty() async {
    final keyCtl = TextEditingController();
    final valCtl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LoreTheme.surface,
        title: const Text('Add Property', style: TextStyle(color: LoreTheme.gold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: keyCtl, autofocus: true,
              style: const TextStyle(color: LoreTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Key (e.g. race, age)',
                  labelStyle: TextStyle(color: LoreTheme.textSecondary))),
          TextField(controller: valCtl,
              style: const TextStyle(color: LoreTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Value',
                  labelStyle: TextStyle(color: LoreTheme.textSecondary))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (result == true && keyCtl.text.isNotEmpty) {
      setState(() => widget.entry.properties[keyCtl.text] = valCtl.text);
      _save();
    }
  }

  void _addLink() async {
    final others = widget.project.entries.where((e) => e.id != widget.entry.id).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other entries to link to')));
      return;
    }

    LoreEntry? target;
    LinkRelation relation = LinkRelation.relatedTo;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: LoreTheme.surface,
          title: const Text('Add Link', style: TextStyle(color: LoreTheme.gold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<LoreEntry>(
              dropdownColor: LoreTheme.surfaceLight,
              style: const TextStyle(color: LoreTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Target Entry',
                  labelStyle: TextStyle(color: LoreTheme.textSecondary)),
              items: others.map((e) => DropdownMenuItem(
                  value: e,
                  child: Row(children: [
                    Icon(e.type.icon, size: 14, color: e.type.color),
                    const SizedBox(width: 8),
                    Text(e.title),
                  ]))).toList(),
              onChanged: (v) => setDialogState(() => target = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LinkRelation>(
              value: relation,
              dropdownColor: LoreTheme.surfaceLight,
              style: const TextStyle(color: LoreTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Relation',
                  labelStyle: TextStyle(color: LoreTheme.textSecondary)),
              items: LinkRelation.values.map((r) =>
                  DropdownMenuItem(value: r, child: Text(r.label))).toList(),
              onChanged: (v) { if (v != null) setDialogState(() => relation = v); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );

    if (result == true && target != null) {
      setState(() {
        widget.entry.links.add(LoreLink(targetId: target!.id, relation: relation));
      });
      _save();
    }
  }

  void _changeType() async {
    final type = await showDialog<EntryType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: LoreTheme.surface,
        title: const Text('Change Type', style: TextStyle(color: LoreTheme.gold)),
        children: EntryType.values.map((t) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Row(children: [
                Icon(t.icon, color: t.color, size: 18),
                const SizedBox(width: 12),
                Text(t.label, style: TextStyle(color: t.color)),
              ]),
            )).toList(),
      ),
    );
    if (type != null) {
      setState(() => widget.entry.type = type);
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final incoming = widget.project.incomingLinks(entry.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          GestureDetector(
            onTap: _changeType,
            child: Icon(entry.type.icon, color: entry.type.color, size: 20),
          ),
          const SizedBox(width: 8),
          Text(entry.title),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () {
            _save();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)));
          }),
        ],
      ),
      body: Row(children: [
        // Editor
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _titleCtl,
                style: const TextStyle(color: LoreTheme.parchment, fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(hintText: 'Entry Title',
                    hintStyle: TextStyle(color: LoreTheme.textSecondary), border: InputBorder.none),
                onChanged: (_) => _save(),
              ),
              // Tags
              Wrap(spacing: 6, children: [
                ...entry.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () { setState(() => entry.tags.remove(tag)); _save(); },
                      backgroundColor: entry.type.color.withValues(alpha: 0.1),
                      side: BorderSide.none, padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )),
                ActionChip(label: const Text('+ Tag', style: TextStyle(fontSize: 11)),
                    onPressed: _addTag, backgroundColor: LoreTheme.surfaceLight,
                    side: BorderSide.none, padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ]),
              const SizedBox(height: 16),
              const Divider(color: LoreTheme.divider),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentCtl, maxLines: null, expands: true,
                  style: const TextStyle(color: LoreTheme.textPrimary, fontSize: 14, height: 1.6),
                  decoration: const InputDecoration(
                      hintText: 'Write your lore here...',
                      hintStyle: TextStyle(color: LoreTheme.textSecondary), border: InputBorder.none),
                  onChanged: (_) => _save(),
                ),
              ),
            ]),
          ),
        ),
        const VerticalDivider(width: 1, color: LoreTheme.divider),
        // Properties sidebar
        Container(
          width: 250,
          color: LoreTheme.surface,
          child: ListView(padding: const EdgeInsets.all(14), children: [
            // Type
            Row(children: [
              const _Label('TYPE'),
              const Spacer(),
              GestureDetector(
                onTap: _changeType,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: entry.type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(entry.type.icon, size: 12, color: entry.type.color),
                    const SizedBox(width: 4),
                    Text(entry.type.label, style: TextStyle(color: entry.type.color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            // Properties
            Row(children: [
              const _Label('PROPERTIES'),
              const Spacer(),
              GestureDetector(onTap: _addProperty,
                  child: const Icon(Icons.add, size: 14, color: LoreTheme.gold)),
            ]),
            const SizedBox(height: 6),
            _InfoRow('Created', _formatDate(entry.createdAt)),
            _InfoRow('Modified', _formatDate(entry.modifiedAt)),
            ...entry.properties.entries.map((e) => _EditablePropertyRow(
                  label: e.key, value: e.value,
                  onDelete: () { setState(() => entry.properties.remove(e.key)); _save(); },
                )),
            const SizedBox(height: 16),
            // Outgoing links
            Row(children: [
              const _Label('LINKS'),
              const Spacer(),
              GestureDetector(onTap: _addLink,
                  child: const Icon(Icons.add, size: 14, color: LoreTheme.gold)),
            ]),
            const SizedBox(height: 6),
            if (entry.links.isEmpty && incoming.isEmpty)
              const Text('No links', style: TextStyle(color: LoreTheme.textSecondary, fontSize: 11)),
            ...entry.links.asMap().entries.map((e) {
              final link = e.value;
              final target = widget.project.findById(link.targetId);
              return _LinkRow(
                icon: target?.type.icon ?? Icons.link,
                color: target?.type.color ?? LoreTheme.textSecondary,
                title: target?.title ?? '[Deleted]',
                subtitle: link.relation.label,
                onTap: () { if (target != null) _navigateTo(target); },
                onDelete: () { setState(() => entry.links.removeAt(e.key)); _save(); },
              );
            }),
            // Incoming links (backlinks)
            if (incoming.isNotEmpty) ...[
              const SizedBox(height: 12),
              const _Label('BACKLINKS'),
              const SizedBox(height: 6),
              ...incoming.map((pair) => _LinkRow(
                    icon: pair.key.type.icon,
                    color: pair.key.type.color,
                    title: pair.key.title,
                    subtitle: '${pair.value.relation.label} (from)',
                    onTap: () => _navigateTo(pair.key),
                  )),
            ],
          ]),
        ),
      ]),
    );
  }

  void _navigateTo(LoreEntry target) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EntryScreen(
          entry: target,
          project: widget.project,
          onSaved: widget.onSaved,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(color: LoreTheme.gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(color: LoreTheme.textPrimary, fontSize: 11))),
        ]),
      );
}

class _EditablePropertyRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onDelete;

  const _EditablePropertyRow({required this.label, required this.value, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label,
            style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 11))),
        Expanded(child: Text(value, style: const TextStyle(color: LoreTheme.textPrimary, fontSize: 11))),
        GestureDetector(onTap: onDelete,
            child: Icon(Icons.close, size: 12, color: LoreTheme.textSecondary.withValues(alpha: 0.5))),
      ]),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _LinkRow({required this.icon, required this.color, required this.title,
      required this.subtitle, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: LoreTheme.textPrimary, fontSize: 11)),
              Text(subtitle, style: const TextStyle(color: LoreTheme.textSecondary, fontSize: 9)),
            ]),
          ),
          if (onDelete != null)
            GestureDetector(onTap: onDelete,
                child: Icon(Icons.close, size: 12, color: LoreTheme.textSecondary.withValues(alpha: 0.5))),
        ]),
      ),
    );
  }
}
