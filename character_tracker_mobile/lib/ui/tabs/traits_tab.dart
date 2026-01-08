import 'package:flutter/material.dart';
import '../../repositories/character_repository.dart';

class TraitsTab extends StatefulWidget {
  final int charId;
  const TraitsTab({super.key, required this.charId});

  @override
  State<TraitsTab> createState() => _TraitsTabState();
}

class _TraitsTabState extends State<TraitsTab> {
  final repo = CharacterRepository();
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await repo.listTraits(widget.charId);
    if (!mounted) return;
    setState(() => _rows = rows);
  }

  Future<void> _openEditor({Map<String, Object?>? row}) async {
    final isEdit = row != null;

    final nameC = TextEditingController(
      text: isEdit ? (row['name'] as String? ?? '') : '',
    );
    final descC = TextEditingController(
      text: isEdit ? (row['description'] as String? ?? '') : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar rasgo' : 'Nuevo rasgo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: descC,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 6,
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

    final desc = descC.text;

    if (isEdit) {
      await repo.updateTrait(row['id'] as int, {
        'name': name,
        'description': desc,
      });
    } else {
      await repo.addTrait(widget.charId, name: name, description: desc);
    }

    await _load();
  }

  Future<void> _delete(int id) async {
    await repo.deleteTrait(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Rasgos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (_rows.isEmpty) const Text('Sin rasgos. Agregá uno.'),

        ..._rows.map((r) {
          final id = r['id'] as int;
          final name = (r['name'] as String?) ?? '';
          final desc = (r['description'] as String?) ?? '';

          return Card(
            child: ExpansionTile(
              title: Text(name),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (desc.isNotEmpty) Text(desc),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openEditor(row: r),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _delete(id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Borrar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }
}
