import 'package:flutter/material.dart';
import '../../repositories/character_repository.dart';

class InventoryTab extends StatefulWidget {
  final int charId;
  const InventoryTab({super.key, required this.charId});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  final repo = CharacterRepository();

  List<Map<String, Object?>> _items = [];
  Map<String, Map<String, Object?>> _coins = {};

  final _cmd = TextEditingController();
  String _selectedCoin = 'gp';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cmd.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await repo.ensureCurrencyRows(widget.charId);
    final inv = await repo.listInventory(widget.charId);
    final coins = await repo.getCurrencyMap(widget.charId);

    // filtrar las monedas del listado “items”
    final items = inv
        .where(
          (r) => (r['notes'] as String?) != CharacterRepository.currencyNote,
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _items = items;
      _coins = coins;
    });
  }

  int _qtyOf(String key) => (_coins[key]?['qty'] as int?) ?? 0;
  int _idOf(String key) => (_coins[key]?['id'] as int?) ?? -1;

  Future<void> _applyCurrencyDelta(String key, int delta) async {
    final id = _idOf(key);
    if (id == -1) return;
    final cur = _qtyOf(key);
    final next = (cur + delta).clamp(0, 999999999);
    await repo.setCurrency(id, next);
    await _load();
  }

  // Soporta:
  // "+50gp", "-10 sp", "gp=200", "+50" (usa la moneda seleccionada)
  ({String coin, int? delta, int? setTo}) _parseCmd(String raw) {
    final s = raw.trim().toLowerCase().replaceAll(' ', '');

    // set: gp=200
    final setMatch = RegExp(r'^(cp|sp|ep|gp|pp)=(\-?\d+)$').firstMatch(s);
    if (setMatch != null) {
      return (
        coin: setMatch.group(1)!,
        delta: null,
        setTo: int.tryParse(setMatch.group(2)!),
      );
    }

    // delta with coin: +50gp / -10sp
    final deltaMatch = RegExp(r'^([+\-]\d+)(cp|sp|ep|gp|pp)$').firstMatch(s);
    if (deltaMatch != null) {
      return (
        coin: deltaMatch.group(2)!,
        delta: int.tryParse(deltaMatch.group(1)!),
        setTo: null,
      );
    }

    // delta only: +50 / -10
    final deltaOnly = RegExp(r'^([+\-]\d+)$').firstMatch(s);
    if (deltaOnly != null) {
      return (
        coin: _selectedCoin,
        delta: int.tryParse(deltaOnly.group(1)!),
        setTo: null,
      );
    }

    return (coin: _selectedCoin, delta: null, setTo: null);
  }

  Future<void> _applyCmd() async {
    final parsed = _parseCmd(_cmd.text);
    if (parsed.delta == null && parsed.setTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Comando inválido. Ej: +50gp, -10sp, gp=200, +50"),
        ),
      );
      return;
    }

    final coin = parsed.coin;
    final id = _idOf(coin);
    if (id == -1) return;

    if (parsed.setTo != null) {
      final next = (parsed.setTo!).clamp(0, 999999999);
      await repo.setCurrency(id, next);
    } else {
      final cur = _qtyOf(coin);
      final next = (cur + parsed.delta!).clamp(0, 999999999);
      await repo.setCurrency(id, next);
    }

    _cmd.clear();
    await _load();
  }

  Future<void> _editCoin(String key) async {
    final cur = _qtyOf(key);
    final c = TextEditingController(text: cur.toString());

    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar ${key.toUpperCase()}'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(c.text.trim()) ?? cur;
              Navigator.pop(ctx, v);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (res == null) return;
    final id = _idOf(key);
    if (id == -1) return;
    await repo.setCurrency(id, res.clamp(0, 999999999));
    await _load();
  }

  Future<void> _addOrEditItem({Map<String, Object?>? row}) async {
    final isEdit = row != null;
    final nameC = TextEditingController(
      text: isEdit ? (row['name'] as String? ?? '') : '',
    );
    final qtyC = TextEditingController(
      text: isEdit ? ((row['qty'] as int?) ?? 1).toString() : '1',
    );
    final notesC = TextEditingController(
      text: isEdit ? (row['notes'] as String? ?? '') : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar item' : 'Nuevo item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: qtyC,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: notesC,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 3,
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

    final name = nameC.text.trim();
    if (name.isEmpty) return;

    final qty = int.tryParse(qtyC.text.trim()) ?? 1;
    final notes = notesC.text;

    if (isEdit) {
      await repo.updateInventoryItem(row['id'] as int, {
        'name': name,
        'qty': qty,
        'notes': notes,
      });
    } else {
      await repo.addInventoryItem(widget.charId, name, qty, notes);
    }

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Monedas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CharacterRepository.currencyKeys.map((k) {
            final qty = _qtyOf(k);
            return InkWell(
              onTap: () => _editCoin(k),
              child: Chip(label: Text('${k.toUpperCase()}: $qty')),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            DropdownButton<String>(
              value: _selectedCoin,
              items: CharacterRepository.currencyKeys
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(k.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCoin = v ?? 'gp'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _cmd,
                decoration: const InputDecoration(
                  labelText: 'Comando',
                  hintText: '+50gp / -10sp / gp=200 / +50',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _applyCmd, child: const Text('OK')),
          ],
        ),

        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => _applyCurrencyDelta(_selectedCoin, -1),
              child: const Text('-1'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _applyCurrencyDelta(_selectedCoin, 1),
              child: const Text('+1'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _applyCurrencyDelta(_selectedCoin, -10),
              child: const Text('-10'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => _applyCurrencyDelta(_selectedCoin, 10),
              child: const Text('+10'),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Text(
          'Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _addOrEditItem(),
            icon: const Icon(Icons.add),
            label: const Text('Agregar item'),
          ),
        ),

        const SizedBox(height: 8),

        if (_items.isEmpty)
          const Text('Sin items. Agregá con el botón de arriba.'),

        ..._items.map((r) {
          final id = r['id'] as int;
          final name = (r['name'] as String?) ?? '';
          final qty = (r['qty'] as int?) ?? 1;
          final notes = (r['notes'] as String?) ?? '';

          return Card(
            child: ListTile(
              title: Text(name),
              subtitle: notes.isEmpty
                  ? null
                  : Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis),
              leading: CircleAvatar(child: Text('x$qty')),
              onTap: () => _addOrEditItem(row: r),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await repo.deleteInventoryItem(id);
                  await _load();
                },
              ),
            ),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }
}
