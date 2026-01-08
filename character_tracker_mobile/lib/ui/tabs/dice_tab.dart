import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../repositories/character_repository.dart';

class DiceTab extends StatefulWidget {
  final int charId;
  const DiceTab({super.key, required this.charId});

  @override
  State<DiceTab> createState() => _DiceTabState();
}

class _DiceTabState extends State<DiceTab> {
  final repo = CharacterRepository();

  final _countC = TextEditingController(text: '1');
  final _sidesC = TextEditingController(text: '20');
  final _modC = TextEditingController(text: '0');

  final _rng = Random();
  List<Map<String, Object?>> _presets = [];

  // historial en memoria (no DB)
  final List<_DiceResult> _history = [];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _countC.dispose();
    _sidesC.dispose();
    _modC.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    final rows = await repo.listDicePresets(widget.charId);
    if (!mounted) return;
    setState(() => _presets = rows);
  }

  int _toInt(TextEditingController c, int fallback) {
    final v = int.tryParse(c.text.trim());
    return v ?? fallback;
  }

  _DiceResult _roll(int count, int sides, int modifier) {
    count = count.clamp(1, 200);
    sides = sides.clamp(2, 1000);

    final rolls = <int>[];
    var sum = 0;
    for (var i = 0; i < count; i++) {
      final r = _rng.nextInt(sides) + 1; // 1..sides
      rolls.add(r);
      sum += r;
    }
    final total = sum + modifier;
    return _DiceResult(
      total: total,
      rolls: rolls,
      count: count,
      sides: sides,
      modifier: modifier,
      timestamp: DateTime.now(),
    );
  }

  String _fmt(_DiceResult r) {
    final mod = r.modifier;
    final modText = mod == 0 ? '' : (mod > 0 ? '+$mod' : '$mod');
    return '${r.total} ⟵ [${r.rolls.join(',')}] ${r.count}d${r.sides}$modText';
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
  }

  void _addToHistory(_DiceResult r) {
    setState(() {
      _history.insert(0, r);
      if (_history.length > 50) _history.removeRange(50, _history.length);
    });
  }

  void _rollQuick() {
    final c = _toInt(_countC, 1);
    final s = _toInt(_sidesC, 20);
    final m = int.tryParse(_modC.text.trim()) ?? 0;

    final r = _roll(c, s, m);
    _addToHistory(r);
  }

  Future<void> _openPresetEditor({Map<String, Object?>? row}) async {
    final isEdit = row != null;

    final nameC = TextEditingController(
      text: isEdit ? (row['name'] as String? ?? '') : '',
    );
    final countC = TextEditingController(
      text: isEdit ? ((row['dice_count'] as int?) ?? 1).toString() : '1',
    );
    final sidesC = TextEditingController(
      text: isEdit ? ((row['dice_sides'] as int?) ?? 20).toString() : '20',
    );
    final modC = TextEditingController(
      text: isEdit ? ((row['modifier'] as int?) ?? 0).toString() : '0',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar preset' : 'Nuevo preset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: countC,
                decoration: const InputDecoration(labelText: 'Dados (count)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sidesC,
                decoration: const InputDecoration(labelText: 'Caras (sides)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: modC,
                decoration: const InputDecoration(
                  labelText: 'Modificador (+/-)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
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

    final diceCount = int.tryParse(countC.text.trim()) ?? 1;
    final diceSides = int.tryParse(sidesC.text.trim()) ?? 20;
    final modifier = int.tryParse(modC.text.trim()) ?? 0;

    if (isEdit) {
      await repo.updateDicePreset(row['id'] as int, {
        'name': name,
        'dice_count': diceCount,
        'dice_sides': diceSides,
        'modifier': modifier,
      });
    } else {
      await repo.addDicePreset(
        widget.charId,
        name: name,
        diceCount: diceCount,
        diceSides: diceSides,
        modifier: modifier,
      );
    }

    await _loadPresets();
  }

  Future<void> _deletePreset(int id) async {
    await repo.deleteDicePreset(id);
    await _loadPresets();
  }

  void _rollPreset(Map<String, Object?> p) {
    final c = (p['dice_count'] as int?) ?? 1;
    final s = (p['dice_sides'] as int?) ?? 20;
    final m = (p['modifier'] as int?) ?? 0;

    final r = _roll(c, s, m);
    _addToHistory(r);
  }

  @override
  Widget build(BuildContext context) {
    final last = _history.isNotEmpty ? _fmt(_history.first) : null;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Tirada rápida',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _countC,
                decoration: const InputDecoration(labelText: 'Count'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sidesC,
                decoration: const InputDecoration(labelText: 'Sides'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _modC,
                decoration: const InputDecoration(labelText: 'Mod'),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _rollQuick,
              icon: const Icon(Icons.casino),
              label: const Text('Tirar'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _history.clear());
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Limpiar historial'),
            ),
          ],
        ),

        if (last != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Última tirada'),
              subtitle: Text(last),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copy(last),
              ),
            ),
          ),
        ],

        const SizedBox(height: 18),
        Row(
          children: [
            const Text(
              'Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openPresetEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_presets.isEmpty) const Text('Sin presets. Agregá uno.'),

        ..._presets.map((p) {
          final id = p['id'] as int;
          final name = (p['name'] as String?) ?? '';
          final c = (p['dice_count'] as int?) ?? 1;
          final s = (p['dice_sides'] as int?) ?? 20;
          final m = (p['modifier'] as int?) ?? 0;
          final modText = m == 0 ? '' : (m > 0 ? '+$m' : '$m');

          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: Text('${c}d$s$modText'),
              onTap: () => _rollPreset(p),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') await _openPresetEditor(row: p);
                  if (v == 'delete') await _deletePreset(id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Borrar')),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 18),
        const Text(
          'Historial',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        if (_history.isEmpty) const Text('Todavía no hay tiradas.'),

        ..._history.map((r) {
          final text = _fmt(r);
          return Card(
            child: ListTile(
              title: Text(text),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copy(text),
              ),
            ),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _DiceResult {
  final int total;
  final List<int> rolls;
  final int count;
  final int sides;
  final int modifier;
  final DateTime timestamp;

  _DiceResult({
    required this.total,
    required this.rolls,
    required this.count,
    required this.sides,
    required this.modifier,
    required this.timestamp,
  });
}
