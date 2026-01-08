import 'dart:async';
import 'package:flutter/material.dart';
import '../../repositories/character_repository.dart';

class FichaTab extends StatefulWidget {
  final int charId;
  const FichaTab({super.key, required this.charId});

  @override
  State<FichaTab> createState() => _FichaTabState();
}

class _FichaTabState extends State<FichaTab> {
  final repo = CharacterRepository();

  final _name = TextEditingController();
  final _race = TextEditingController();
  final _klass = TextEditingController();
  final _level = TextEditingController();
  final _background = TextEditingController();
  final _notes = TextEditingController();

  final _hpCur = TextEditingController();
  final _hpMax = TextEditingController();
  final _tempHp = TextEditingController();
  final _ac = TextEditingController();
  final _init = TextEditingController();
  final _speed = TextEditingController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _race.dispose();
    _klass.dispose();
    _level.dispose();
    _background.dispose();
    _notes.dispose();
    _hpCur.dispose();
    _hpMax.dispose();
    _tempHp.dispose();
    _ac.dispose();
    _init.dispose();
    _speed.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ch = await repo.getCharacter(widget.charId);
    final vit = await repo.getVitals(widget.charId);

    _name.text = (ch['name'] as String?) ?? '';
    _race.text = (ch['race'] as String?) ?? '';
    _klass.text = (ch['class'] as String?) ?? '';
    _level.text = ((ch['level'] as int?) ?? 1).toString();
    _background.text = (ch['background'] as String?) ?? '';
    _notes.text = (ch['notes'] as String?) ?? '';

    _hpCur.text = ((vit['hp_cur'] as int?) ?? 0).toString();
    _hpMax.text = ((vit['hp_max'] as int?) ?? 0).toString();
    _tempHp.text = ((vit['temp_hp'] as int?) ?? 0).toString();
    _ac.text = ((vit['ac'] as int?) ?? 10).toString();
    _init.text = ((vit['initiative_bonus'] as int?) ?? 0).toString();
    _speed.text = ((vit['speed'] as int?) ?? 30).toString();

    if (!mounted) return;
    setState(() {});
  }

  int _toInt(TextEditingController c, int fallback) {
    final v = int.tryParse(c.text.trim());
    return v ?? fallback;
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      await repo.updateCharacterFields(widget.charId, {
        'name': _name.text,
        'race': _race.text,
        'class': _klass.text,
        'level': _toInt(_level, 1),
        'background': _background.text,
        'notes': _notes.text,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Ficha',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nombre'),
          onChanged: (_) => _scheduleSave(),
        ),
        TextField(
          controller: _race,
          decoration: const InputDecoration(labelText: 'Raza'),
          onChanged: (_) => _scheduleSave(),
        ),
        TextField(
          controller: _klass,
          decoration: const InputDecoration(labelText: 'Clase'),
          onChanged: (_) => _scheduleSave(),
        ),
        TextField(
          controller: _level,
          decoration: const InputDecoration(labelText: 'Nivel'),
          keyboardType: TextInputType.number,
          onChanged: (_) => _scheduleSave(),
        ),
        TextField(
          controller: _background,
          decoration: const InputDecoration(labelText: 'Trasfondo'),
          onChanged: (_) => _scheduleSave(),
        ),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(labelText: 'Notas'),
          maxLines: 5,
          onChanged: (_) => _scheduleSave(),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
