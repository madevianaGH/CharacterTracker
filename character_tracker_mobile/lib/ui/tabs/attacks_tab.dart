import 'package:flutter/material.dart';
import '../../repositories/character_repository.dart';

class AttacksTab extends StatefulWidget {
  final int charId;
  const AttacksTab({super.key, required this.charId});

  @override
  State<AttacksTab> createState() => _AttacksTabState();
}

class _AttacksTabState extends State<AttacksTab> {
  final repo = CharacterRepository();
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await repo.listAttacks(widget.charId);
    if (!mounted) return;
    setState(() => _rows = rows);
  }

  Future<void> _openEditor({Map<String, Object?>? row}) async {
    final isEdit = row != null;

    final nameC = TextEditingController(
      text: isEdit ? (row['name'] as String? ?? '') : '',
    );
    final toHitC = TextEditingController(
      text: isEdit ? (row['to_hit'] as String? ?? '') : '',
    );
    final dmgC = TextEditingController(
      text: isEdit ? (row['damage'] as String? ?? '') : '',
    );
    final typeC = TextEditingController(
      text: isEdit ? (row['dmg_type'] as String? ?? '') : '',
    );
    final notesC = TextEditingController(
      text: isEdit ? (row['notes'] as String? ?? '') : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar ataque' : 'Nuevo ataque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: toHitC,
                decoration: const InputDecoration(labelText: 'To Hit (ej: +7)'),
              ),
              TextField(
                controller: dmgC,
                decoration: const InputDecoration(
                  labelText: 'Daño (ej: 1d8+4)',
                ),
              ),
              TextField(
                controller: typeC,
                decoration: const InputDecoration(
                  labelText: 'Tipo (ej: slashing)',
                ),
              ),
              TextField(
                controller: notesC,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final name = nameC.text.trim();
    if (name.isEmpty) return;

    if (isEdit) {
      await repo.updateAttack(row['id'] as int, {
        'name': name,
        'to_hit': toHitC.text,
        'damage': dmgC.text,
        'dmg_type': typeC.text,
        'notes': notesC.text,
      });
    } else {
      await repo.addAttack(
        widget.charId,
        name: name,
        toHit: toHitC.text,
        damage: dmgC.text,
        dmgType: typeC.text,
        notes: notesC.text,
      );
    }

    await _load();
  }

  Future<void> _deleteRow(int id) async {
    await repo.deleteAttack(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Importante: este Scaffold es solo para tener FAB dentro del tab.
      // Si preferís, lo sacamos y ponemos un botón arriba.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Ataques',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          if (_rows.isEmpty) const Text('Sin ataques. Agregá con el botón +.'),

          ..._rows.map((r) {
            final id = r['id'] as int;
            final name = (r['name'] as String?) ?? '';
            final toHit = (r['to_hit'] as String?) ?? '';
            final dmg = (r['damage'] as String?) ?? '';
            final type = (r['dmg_type'] as String?) ?? '';
            final notes = (r['notes'] as String?) ?? '';

            final line = [
              if (toHit.isNotEmpty) toHit,
              if (dmg.isNotEmpty) dmg,
              if (type.isNotEmpty) '($type)',
            ].join('  ');

            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (line.isNotEmpty) Text(line),
                    if (notes.isNotEmpty)
                      Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
                onTap: () => _openEditor(row: r),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteRow(id),
                ),
              ),
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
