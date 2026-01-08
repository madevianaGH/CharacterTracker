import 'package:flutter/material.dart';
import '../../repositories/character_repository.dart';

class SpellsTab extends StatefulWidget {
  final int charId;
  const SpellsTab({super.key, required this.charId});

  @override
  State<SpellsTab> createState() => _SpellsTabState();
}

class _SpellsTabState extends State<SpellsTab> {
  final repo = CharacterRepository();
  int _selectedSlotLevel = 1;

  List<Map<String, Object?>> _spells = [];
  Map<int, Map<String, Object?>> _slots = {};
  int _spCur = 0;
  int _spMax = 0;

  bool _showPreparedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _asInt(Object? v, int fallback) => (v is int) ? v : fallback;

  Future<void> _load() async {
    await repo.ensureSpellSlotsRows(widget.charId);
    await repo.ensureSpellPointsRow(widget.charId);

    final spells = await repo.listSpells(widget.charId);
    final slots = await repo.getSpellSlotsMap(widget.charId);
    final sp = await repo.getSpellPoints(widget.charId);

    if (!mounted) return;
    setState(() {
      _spells = spells;
      _slots = slots;
      _spCur = _asInt(sp['cur'], 0);
      _spMax = _asInt(sp['max'], 0);
    });
  }

  Future<void> _editSlotLevel(int lvl) async {
    final row = _slots[lvl];
    final cur0 = _asInt(row?['cur'], 0);
    final max0 = _asInt(row?['max'], 0);

    final curC = TextEditingController(text: cur0.toString());
    final maxC = TextEditingController(text: max0.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Slots nivel $lvl'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: curC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cur'),
            ),
            TextField(
              controller: maxC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max'),
            ),
          ],
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
    final cur = int.tryParse(curC.text.trim()) ?? cur0;
    final max = int.tryParse(maxC.text.trim()) ?? max0;

    await repo.setSpellSlotCurMax(
      widget.charId,
      lvl,
      cur.clamp(0, 999),
      max.clamp(0, 999),
    );
    await _load();
  }

  Future<void> _bumpSlot(int lvl, int delta) async {
    final row = _slots[lvl];
    if (row == null) return;
    final cur0 = _asInt(row['cur'], 0);
    final max0 = _asInt(row['max'], 0);
    final next = (cur0 + delta).clamp(0, max0);
    await repo.setSpellSlotCurMax(widget.charId, lvl, next, max0);
    await _load();
  }

  Future<void> _editSpellPoints() async {
    final curC = TextEditingController(text: _spCur.toString());
    final maxC = TextEditingController(text: _spMax.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Spell Points'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: curC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cur'),
            ),
            TextField(
              controller: maxC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max'),
            ),
          ],
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
    final cur = int.tryParse(curC.text.trim()) ?? _spCur;
    final max = int.tryParse(maxC.text.trim()) ?? _spMax;

    await repo.setSpellPointsCurMax(
      widget.charId,
      cur.clamp(0, 9999),
      max.clamp(0, 9999),
    );
    await _load();
  }

  Future<void> _bumpSpellPoints(int delta) async {
    final next = (_spCur + delta).clamp(0, _spMax);
    await repo.setSpellPointsCurMax(widget.charId, next, _spMax);
    await _load();
  }

  Future<void> _openSpellEditor({Map<String, Object?>? row}) async {
    final isEdit = row != null;

    final nameC = TextEditingController(
      text: isEdit ? (row['name'] as String? ?? '') : '',
    );
    final levelC = TextEditingController(
      text: isEdit ? (_asInt(row['level'], 0)).toString() : '0',
    );
    final durationC = TextEditingController(
      text: isEdit ? (row['duration'] as String? ?? '') : '',
    );
    final schoolC = TextEditingController(
      text: isEdit ? (row['school'] as String? ?? '') : '',
    );
    final castC = TextEditingController(
      text: isEdit ? (row['casting_time'] as String? ?? '') : '',
    );
    final rangeC = TextEditingController(
      text: isEdit ? (row['range_text'] as String? ?? '') : '',
    );
    final compC = TextEditingController(
      text: isEdit ? (row['components'] as String? ?? '') : '',
    );
    final descC = TextEditingController(
      text: isEdit ? (row['description'] as String? ?? '') : '',
    );
    final notesC = TextEditingController(
      text: isEdit ? (row['notes'] as String? ?? '') : '',
    );

    int prepared = isEdit ? _asInt(row['prepared'], 0) : 0;
    int ritual = isEdit ? _asInt(row['ritual'], 0) : 0;
    int conc = isEdit ? _asInt(row['concentration'], 0) : 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isEdit ? 'Editar hechizo' : 'Nuevo hechizo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: levelC,
                  decoration: const InputDecoration(labelText: 'Nivel (0–9)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: durationC,
                  decoration: const InputDecoration(labelText: 'Duración'),
                ),
                TextField(
                  controller: schoolC,
                  decoration: const InputDecoration(labelText: 'School'),
                ),
                TextField(
                  controller: castC,
                  decoration: const InputDecoration(labelText: 'Casting Time'),
                ),
                TextField(
                  controller: rangeC,
                  decoration: const InputDecoration(labelText: 'Range'),
                ),
                TextField(
                  controller: compC,
                  decoration: const InputDecoration(labelText: 'Components'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: prepared == 1,
                        onChanged: (v) =>
                            setLocal(() => prepared = (v == true) ? 1 : 0),
                        title: const Text('Prepared'),
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: ritual == 1,
                        onChanged: (v) =>
                            setLocal(() => ritual = (v == true) ? 1 : 0),
                        title: const Text('Ritual'),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: conc == 1,
                  onChanged: (v) => setLocal(() => conc = (v == true) ? 1 : 0),
                  title: const Text('Concentration'),
                ),
                TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 5,
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
      ),
    );

    if (ok != true) return;

    final name = nameC.text.trim();
    if (name.isEmpty) return;

    final lvl = (int.tryParse(levelC.text.trim()) ?? 0).clamp(0, 9);

    if (isEdit) {
      await repo.updateSpell(row['id'] as int, {
        'name': name,
        'level': lvl,
        'duration': durationC.text,
        'prepared': prepared,
        'ritual': ritual,
        'concentration': conc,
        'school': schoolC.text.isEmpty ? null : schoolC.text,
        'casting_time': castC.text.isEmpty ? null : castC.text,
        'range_text': rangeC.text.isEmpty ? null : rangeC.text,
        'components': compC.text.isEmpty ? null : compC.text,
        'description': descC.text.isEmpty ? null : descC.text,
        'notes': notesC.text.isEmpty ? null : notesC.text,
      });
    } else {
      await repo.addSpell(
        widget.charId,
        name: name,
        level: lvl,
        duration: durationC.text,
        prepared: prepared,
        ritual: ritual,
        concentration: conc,
        school: schoolC.text.isEmpty ? null : schoolC.text,
        castingTime: castC.text.isEmpty ? null : castC.text,
        rangeText: rangeC.text.isEmpty ? null : rangeC.text,
        components: compC.text.isEmpty ? null : compC.text,
        description: descC.text.isEmpty ? null : descC.text,
        notes: notesC.text.isEmpty ? null : notesC.text,
      );
    }

    await _load();
  }

  Future<void> _togglePrepared(Map<String, Object?> row) async {
    final id = row['id'] as int;
    final cur = _asInt(row['prepared'], 0);
    final next = (cur == 1) ? 0 : 1;
    await repo.updateSpell(id, {'prepared': next});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final spellsShown = _showPreparedOnly
        ? _spells.where((s) => _asInt(s['prepared'], 0) == 1).toList()
        : _spells;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            const Text(
              'Hechizos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openSpellEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Text(
          'Spell Slots',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(9, (i) {
            final lvl = i + 1;
            final row = _slots[lvl];
            final cur = _asInt(row?['cur'], 0);
            final max = _asInt(row?['max'], 0);

            return InkWell(
              onTap: () async {
                setState(() => _selectedSlotLevel = lvl);
                await _editSlotLevel(lvl);
              },
              child: Chip(label: Text('L$lvl: $cur/$max')),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Nivel seleccionado: L$_selectedSlotLevel'),
            const Spacer(),
            OutlinedButton(
              onPressed: () => _bumpSlot(_selectedSlotLevel, -1),
              child: const Text('-1'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _bumpSlot(_selectedSlotLevel, 1),
              child: const Text('+1'),
            ),
          ],
        ),

        const SizedBox(height: 6),
        // quick bump (usa el último nivel tocado sería ideal, por ahora no)
        const Text(
          'Tip: tocá un chip para editar Cur/Max.',
          style: TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Spell Points',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _editSpellPoints,
              child: Chip(label: Text('$_spCur/$_spMax')),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => _bumpSpellPoints(-1),
              child: const Text('-1'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _bumpSpellPoints(1),
              child: const Text('+1'),
            ),
          ],
        ),

        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostrar solo preparados'),
          value: _showPreparedOnly,
          onChanged: (v) => setState(() => _showPreparedOnly = v),
        ),

        const SizedBox(height: 6),

        if (spellsShown.isEmpty)
          const Text('Sin hechizos (o no hay preparados en el filtro).'),

        ...spellsShown.map((r) {
          final id = r['id'] as int;
          final name = (r['name'] as String?) ?? '';
          final lvl = _asInt(r['level'], 0);
          final dur = (r['duration'] as String?) ?? '';
          final prep = _asInt(r['prepared'], 0) == 1;
          final rit = _asInt(r['ritual'], 0) == 1;
          final con = _asInt(r['concentration'], 0) == 1;

          final tags = <String>[
            if (prep) 'Prep',
            if (rit) 'Ritual',
            if (con) 'Conc',
          ].join(' · ');

          final school = (r['school'] as String?) ?? '';
          final cast = (r['casting_time'] as String?) ?? '';
          final range = (r['range_text'] as String?) ?? '';
          final comp = (r['components'] as String?) ?? '';
          final desc = (r['description'] as String?) ?? '';
          final notes = (r['notes'] as String?) ?? '';

          final header =
              'Nivel $lvl${dur.isNotEmpty ? ' · $dur' : ''}${school.isNotEmpty ? ' · $school' : ''}';

          return Card(
            child: ExpansionTile(
              title: Text(name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(header), if (tags.isNotEmpty) Text(tags)],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Toggle Prepared',
                    icon: Icon(
                      prep ? Icons.check_circle : Icons.radio_button_unchecked,
                    ),
                    onPressed: () => _togglePrepared(r),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') await _openSpellEditor(row: r);
                      if (v == 'delete') {
                        await repo.deleteSpell(id);
                        await _load();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Borrar')),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cast.isNotEmpty) Text('Casting: $cast'),
                      if (range.isNotEmpty) Text('Range: $range'),
                      if (comp.isNotEmpty) Text('Components: $comp'),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Descripción',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(desc),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Notas',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(notes),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openSpellEditor(row: r),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await repo.deleteSpell(id);
                              await _load();
                            },
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
