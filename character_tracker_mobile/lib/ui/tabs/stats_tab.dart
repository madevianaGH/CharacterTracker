import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../repositories/character_repository.dart';

class StatsTab extends StatefulWidget {
  final int charId;
  const StatsTab({super.key, required this.charId});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final repo = CharacterRepository();

  // --- Vitals controllers ---
  final _hpCur = TextEditingController();
  final _hpMax = TextEditingController();
  final _tempHp = TextEditingController();
  final _ac = TextEditingController();
  final _init = TextEditingController();
  final _speed = TextEditingController();

  // --- Stats controllers ---
  final _str = TextEditingController();
  final _dex = TextEditingController();
  final _con = TextEditingController();
  final _int = TextEditingController();
  final _wis = TextEditingController();
  final _cha = TextEditingController();

  int _level = 1;
  Map<String, SkillRow> _skills = {};

  Timer? _debounceVitals;
  Timer? _debounceStats;

  static const Map<String, String> _skillLabel = {
    "acrobatics": "Acrobatics",
    "animal_handling": "Animal Handling",
    "arcana": "Arcana",
    "athletics": "Athletics",
    "deception": "Deception",
    "history": "History",
    "insight": "Insight",
    "intimidation": "Intimidation",
    "investigation": "Investigation",
    "medicine": "Medicine",
    "nature": "Nature",
    "perception": "Perception",
    "performance": "Performance",
    "persuasion": "Persuasion",
    "religion": "Religion",
    "sleight_of_hand": "Sleight of Hand",
    "stealth": "Stealth",
    "survival": "Survival",
  };

  // skill -> ability
  static const Map<String, String> _skillAbility = {
    "acrobatics": "dex",
    "animal_handling": "wis",
    "arcana": "int",
    "athletics": "str",
    "deception": "cha",
    "history": "int",
    "insight": "wis",
    "intimidation": "cha",
    "investigation": "int",
    "medicine": "wis",
    "nature": "int",
    "perception": "wis",
    "performance": "cha",
    "persuasion": "cha",
    "religion": "int",
    "sleight_of_hand": "dex",
    "stealth": "dex",
    "survival": "wis",
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _debounceVitals?.cancel();
    _debounceStats?.cancel();

    _hpCur.dispose();
    _hpMax.dispose();
    _tempHp.dispose();
    _ac.dispose();
    _init.dispose();
    _speed.dispose();

    _str.dispose();
    _dex.dispose();
    _con.dispose();
    _int.dispose();
    _wis.dispose();
    _cha.dispose();

    super.dispose();
    for (final t in _skillDebounce.values) {
      t.cancel();
    }
    _skillDebounce.clear();
  }

  int _toInt(TextEditingController c, int fallback) {
    final v = int.tryParse(c.text.trim());
    return v ?? fallback;
  }

  int _modFromScore(int score) => ((score - 10) / 2).floor();

  int get _profBonus => 2 + ((_level - 1) ~/ 4);

  int _abilityScore(String ab) {
    switch (ab) {
      case "str":
        return _toInt(_str, 10);
      case "dex":
        return _toInt(_dex, 10);
      case "con":
        return _toInt(_con, 10);
      case "int":
        return _toInt(_int, 10);
      case "wis":
        return _toInt(_wis, 10);
      case "cha":
        return _toInt(_cha, 10);
      default:
        return 10;
    }
  }

  int _skillTotal(String skillKey) {
    final row =
        _skills[skillKey] ?? SkillRow(proficient: 0, expertise: 0, bonus: 0);
    final ab = _skillAbility[skillKey] ?? "str";
    final mod = _modFromScore(_abilityScore(ab));
    final mult = (row.expertise == 1)
        ? 2
        : (row.proficient == 1)
        ? 1
        : 0;
    return mod + (mult * _profBonus) + row.bonus;
  }

  Future<void> _loadAll() async {
    final ch = await repo.getCharacter(widget.charId);
    final vit = await repo.getVitals(widget.charId);
    final st = await repo.getStats(widget.charId);
    final sk = await repo.getSkills(widget.charId);

    _level = (ch['level'] as int?) ?? 1;

    _hpCur.text = ((vit['hp_cur'] as int?) ?? 0).toString();
    _hpMax.text = ((vit['hp_max'] as int?) ?? 0).toString();
    _tempHp.text = ((vit['temp_hp'] as int?) ?? 0).toString();
    _ac.text = ((vit['ac'] as int?) ?? 10).toString();
    _init.text = ((vit['initiative_bonus'] as int?) ?? 0).toString();
    _speed.text = ((vit['speed'] as int?) ?? 30).toString();

    _str.text = ((st['str'] as int?) ?? 10).toString();
    _dex.text = ((st['dex'] as int?) ?? 10).toString();
    _con.text = ((st['con'] as int?) ?? 10).toString();
    _int.text = ((st['int'] as int?) ?? 10).toString();
    _wis.text = ((st['wis'] as int?) ?? 10).toString();
    _cha.text = ((st['cha'] as int?) ?? 10).toString();

    _skills = sk;

    if (!mounted) return;
    setState(() {});
  }

  void _scheduleSaveVitals() {
    _debounceVitals?.cancel();
    _debounceVitals = Timer(const Duration(milliseconds: 300), () async {
      await repo.updateVitalsFields(widget.charId, {
        'hp_cur': _toInt(_hpCur, 0),
        'hp_max': _toInt(_hpMax, 0),
        'temp_hp': _toInt(_tempHp, 0),
        'ac': _toInt(_ac, 10),
        'initiative_bonus': _toInt(_init, 0),
        'speed': _toInt(_speed, 30),
      });
    });
  }

  void _scheduleSaveStats() {
    _debounceStats?.cancel();
    _debounceStats = Timer(const Duration(milliseconds: 300), () async {
      await repo.updateStatsFields(widget.charId, {
        'str': _toInt(_str, 10),
        'dex': _toInt(_dex, 10),
        'con': _toInt(_con, 10),
        'int': _toInt(_int, 10),
        'wis': _toInt(_wis, 10),
        'cha': _toInt(_cha, 10),
      });
      if (!mounted) return;
      setState(() {}); // refresca totals
    });
  }

  final Map<String, Timer> _skillDebounce = {};

  Future<void> _setSkill(String key, SkillRow row) async {
    _skills = Map<String, SkillRow>.from(_skills)..[key] = row;
    setState(() {});
    await repo.updateSkill(widget.charId, key, row);
  }

  Widget _numField(
    String label,
    TextEditingController c,
    VoidCallback onChanged,
  ) {
    return TextField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (_) => onChanged(),
    );
  }

  Widget _abilityRow(String abLabel, TextEditingController c) {
    final score = _toInt(c, 10);
    final mod = _modFromScore(score);
    final modText = mod >= 0 ? "+$mod" : "$mod";

    return Row(
      children: [
        Expanded(child: _numField(abLabel, c, _scheduleSaveStats)),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: InputDecorator(
            decoration: const InputDecoration(labelText: "Mod"),
            child: Text(modText, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // PB
        Row(
          children: [
            Text(
              "Nivel: $_level",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Text(
              "PB: +$_profBonus",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Text(
          'Vitals / Combate',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _numField('HP actual', _hpCur, _scheduleSaveVitals),
            ),
            const SizedBox(width: 12),
            Expanded(child: _numField('HP máx', _hpMax, _scheduleSaveVitals)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _numField('Temp HP', _tempHp, _scheduleSaveVitals)),
            const SizedBox(width: 12),
            Expanded(child: _numField('AC', _ac, _scheduleSaveVitals)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _numField('Iniciativa bonus', _init, _scheduleSaveVitals),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numField('Velocidad', _speed, _scheduleSaveVitals),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'Atributos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        _abilityRow("STR", _str),
        _abilityRow("DEX", _dex),
        _abilityRow("CON", _con),
        _abilityRow("INT", _int),
        _abilityRow("WIS", _wis),
        _abilityRow("CHA", _cha),

        const SizedBox(height: 24),
        const Text(
          'Skills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        ...CharacterRepository.skillKeys.map((key) {
          final row =
              _skills[key] ?? SkillRow(proficient: 0, expertise: 0, bonus: 0);
          final total = _skillTotal(key);
          final totalText = total >= 0 ? "+$total" : "$total";

          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _skillLabel[key] ?? key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Proficient
                      Row(
                        children: [
                          Checkbox(
                            value: row.proficient == 1,
                            onChanged: (v) {
                              final prof = (v == true) ? 1 : 0;
                              final exp = (prof == 0)
                                  ? 0
                                  : row.expertise; // si desmarcás prof, exp se apaga
                              _setSkill(
                                key,
                                SkillRow(
                                  proficient: prof,
                                  expertise: exp,
                                  bonus: row.bonus,
                                ),
                              );
                            },
                          ),
                          const Text("Prof"),
                        ],
                      ),
                      const SizedBox(width: 8),

                      // Expertise
                      Row(
                        children: [
                          Checkbox(
                            value: row.expertise == 1,
                            onChanged: (v) {
                              final exp = (v == true) ? 1 : 0;
                              final prof = (exp == 1)
                                  ? 1
                                  : row.proficient; // exp implica prof
                              _setSkill(
                                key,
                                SkillRow(
                                  proficient: prof,
                                  expertise: exp,
                                  bonus: row.bonus,
                                ),
                              );
                            },
                          ),
                          const Text("Exp"),
                        ],
                      ),

                      const Spacer(),

                      // Bonus manual
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          key: ValueKey(
                            'bonus-$key-${row.bonus}',
                          ), // fuerza refresh cuando cambia en DB
                          initialValue: row.bonus.toString(),
                          decoration: const InputDecoration(labelText: "Bonus"),
                          keyboardType: TextInputType.number,
                          onChanged: (txt) {
                            final b = int.tryParse(txt.trim()) ?? 0;

                            _skillDebounce[key]?.cancel();
                            _skillDebounce[key] = Timer(
                              const Duration(milliseconds: 250),
                              () {
                                _setSkill(
                                  key,
                                  SkillRow(
                                    proficient: row.proficient,
                                    expertise: row.expertise,
                                    bonus: b,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Total
                      SizedBox(
                        width: 70,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: "Total"),
                          child: Text(totalText, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
