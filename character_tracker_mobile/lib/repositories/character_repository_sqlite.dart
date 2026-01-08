import 'package:sqflite/sqflite.dart';
import '../db/app_db.dart';
import '../models/models.dart';

class CharacterRepository {
  // Misma lista que tu app.py (keys internas)
  static const List<String> skillKeys = [
    "acrobatics",
    "animal_handling",
    "arcana",
    "athletics",
    "deception",
    "history",
    "insight",
    "intimidation",
    "investigation",
    "medicine",
    "nature",
    "perception",
    "performance",
    "persuasion",
    "religion",
    "sleight_of_hand",
    "stealth",
    "survival",
  ];

  Future<List<Map<String, Object?>>> listCharacters() async {
    final d = await AppDb.instance.db;
    return d.query(
      'characters',
      columns: ['id', 'name', 'level', 'updated_at'],
      orderBy: 'updated_at DESC, id DESC',
    );
  }

  Future<int> createCharacter() async {
    final d = await AppDb.instance.db;
    final now = DateTime.now().toIso8601String().split('.').first;

    return d.transaction<int>((txn) async {
      final id = await txn.insert('characters', {
        'name': 'Nuevo personaje',
        'level': 1,
        'updated_at': now,
      });

      await txn.insert('stats', {'character_id': id});

      for (final k in skillKeys) {
        await txn.insert('skills', {
          'character_id': id,
          'skill_key': k,
          'proficient': 0,
          'expertise': 0,
          'bonus': 0,
        });
      }

      await txn.insert('spell_points', {
        'character_id': id,
        'cur': 0,
        'max': 0,
      });
      for (var lvl = 1; lvl <= 9; lvl++) {
        await txn.insert('spell_slots', {
          'character_id': id,
          'slot_level': lvl,
          'cur': 0,
          'max': 0,
        });
      }

      await txn.insert('vitals', {
        'character_id': id,
        'hp_cur': 0,
        'hp_max': 0,
        'temp_hp': 0,
        'ac': 10,
        'initiative_bonus': 0,
        'speed': 30,
      });

      return id;
    });
  }

  Future<void> deleteCharacter(int charId) async {
    final d = await AppDb.instance.db;
    await d.delete('characters', where: 'id=?', whereArgs: [charId]); // cascade
  }

  // --- Export: compone ExportPayloadV2 leyendo TODAS las tablas ---
  Future<ExportPayloadV2> buildExportPayload(int charId) async {
    final d = await AppDb.instance.db;

    final chRow = (await d.query(
      'characters',
      where: 'id=?',
      whereArgs: [charId],
      limit: 1,
    )).first;

    final character = CharacterSheet(
      name: (chRow['name'] as String?) ?? '',
      race: (chRow['race'] as String?) ?? '',
      klass: (chRow['class'] as String?) ?? '',
      level: (chRow['level'] as int?) ?? 1,
      background: (chRow['background'] as String?) ?? '',
      notes: (chRow['notes'] as String?) ?? '',
    );

    final stRow = (await d.query(
      'stats',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    )).first;
    final stats = Stats(
      str: stRow['str'] as int? ?? 10,
      dex: stRow['dex'] as int? ?? 10,
      con: stRow['con'] as int? ?? 10,
      int_: stRow['int'] as int? ?? 10,
      wis: stRow['wis'] as int? ?? 10,
      cha: stRow['cha'] as int? ?? 10,
    );

    final vRow = (await d.query(
      'vitals',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    )).first;
    final vitals = Vitals(
      hpCur: vRow['hp_cur'] as int? ?? 0,
      hpMax: vRow['hp_max'] as int? ?? 0,
      tempHp: vRow['temp_hp'] as int? ?? 0,
      ac: vRow['ac'] as int? ?? 10,
      initiativeBonus: vRow['initiative_bonus'] as int? ?? 0,
      speed: vRow['speed'] as int? ?? 30,
    );

    final skillsRows = await d.query(
      'skills',
      where: 'character_id=?',
      whereArgs: [charId],
    );
    final skills = <String, SkillRow>{
      for (final r in skillsRows)
        (r['skill_key'] as String): SkillRow(
          proficient: r['proficient'] as int? ?? 0,
          expertise: r['expertise'] as int? ?? 0,
          bonus: r['bonus'] as int? ?? 0,
        ),
    };

    final invRows = await d.query(
      'inventory',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'name COLLATE NOCASE',
    );
    final inventory = invRows
        .map(
          (r) => InventoryItem(
            name: (r['name'] as String?) ?? '',
            qty: r['qty'] as int? ?? 1,
            notes: (r['notes'] as String?) ?? '',
          ),
        )
        .toList();

    final atkRows = await d.query(
      'attacks',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'name COLLATE NOCASE',
    );
    final attacks = atkRows
        .map(
          (r) => AttackRow(
            name: (r['name'] as String?) ?? '',
            toHit: (r['to_hit'] as String?) ?? '',
            damage: (r['damage'] as String?) ?? '',
            dmgType: (r['dmg_type'] as String?) ?? '',
            notes: (r['notes'] as String?) ?? '',
          ),
        )
        .toList();

    final spRows = await d.query(
      'spells',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'level ASC, name COLLATE NOCASE',
    );
    final spells = spRows
        .map(
          (r) => SpellRow(
            name: (r['name'] as String?) ?? '',
            level: r['level'] as int? ?? 0,
            prepared: r['prepared'] as int? ?? 0,
            ritual: r['ritual'] as int? ?? 0,
            concentration: r['concentration'] as int? ?? 0,
            school: (r['school'] as String?) ?? '',
            castingTime: (r['casting_time'] as String?) ?? '',
            rangeText: (r['range_text'] as String?) ?? '',
            components: (r['components'] as String?) ?? '',
            duration: (r['duration'] as String?) ?? '',
            description: (r['description'] as String?) ?? '',
            notes: (r['notes'] as String?) ?? '',
          ),
        )
        .toList();

    final trRows = await d.query(
      'traits',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'name COLLATE NOCASE',
    );
    final traits = trRows
        .map(
          (r) => TraitRow(
            name: (r['name'] as String?) ?? '',
            kind: r['kind'] as String?,
            notes: r['notes'] as String?,
          ),
        )
        .toList();

    final slotRows = await d.query(
      'spell_slots',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'slot_level',
    );
    final spellSlots = <String, SlotRow>{
      for (final r in slotRows)
        (r['slot_level'] as int).toString(): SlotRow(
          cur: r['cur'] as int? ?? 0,
          max: r['max'] as int? ?? 0,
        ),
    };

    final ptsRow = (await d.query(
      'spell_points',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    )).first;
    final spellPoints = SpellPoints(
      cur: ptsRow['cur'] as int? ?? 0,
      max: ptsRow['max'] as int? ?? 0,
    );

    final dpRows = await d.query(
      'dice_presets',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'name COLLATE NOCASE',
    );
    final dicePresets = dpRows
        .map(
          (r) => DicePreset(
            name: (r['name'] as String?) ?? '',
            diceCount: r['dice_count'] as int? ?? 1,
            diceSides: r['dice_sides'] as int? ?? 20,
            modifier: r['modifier'] as int? ?? 0,
          ),
        )
        .toList();

    final exportedAt = DateTime.now().toIso8601String().split('.').first;

    return ExportPayloadV2(
      schemaVersion: 2,
      exportedAt: exportedAt,
      character: character,
      vitals: vitals,
      stats: stats,
      skills: skills,
      inventory: inventory,
      attacks: attacks,
      spells: spells,
      traits: traits,
      spellSlots: spellSlots,
      spellPoints: spellPoints,
      dicePresets: dicePresets,
    );
  }

  // --- Import: crea personaje nuevo e inserta TODO ---
  Future<int> importPayloadV2(ExportPayloadV2 p) async {
    final d = await AppDb.instance.db;
    final now = DateTime.now().toIso8601String().split('.').first;

    return d.transaction<int>((txn) async {
      final newId = await txn.insert('characters', {
        'name': p.character.name.isEmpty ? 'Importado' : p.character.name,
        'race': p.character.race,
        'class': p.character.klass,
        'level': p.character.level,
        'background': p.character.background,
        'notes': p.character.notes,
        'updated_at': now,
      });

      await txn.insert('stats', {
        'character_id': newId,
        'str': p.stats.str,
        'dex': p.stats.dex,
        'con': p.stats.con,
        'int': p.stats.int_,
        'wis': p.stats.wis,
        'cha': p.stats.cha,
      });

      // Skills: insert OR REPLACE por PK (character_id, skill_key)
      for (final e in p.skills.entries) {
        await txn.insert('skills', {
          'character_id': newId,
          'skill_key': e.key,
          'proficient': e.value.proficient,
          'expertise': e.value.expertise,
          'bonus': e.value.bonus,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Vitals
      await txn.insert('vitals', {
        'character_id': newId,
        'hp_cur': p.vitals.hpCur,
        'hp_max': p.vitals.hpMax,
        'temp_hp': p.vitals.tempHp,
        'ac': p.vitals.ac,
        'initiative_bonus': p.vitals.initiativeBonus,
        'speed': p.vitals.speed,
      });

      // Inventory
      for (final it in p.inventory) {
        await txn.insert('inventory', {
          'character_id': newId,
          'name': it.name,
          'qty': it.qty,
          'notes': it.notes,
        });
      }

      // Attacks
      for (final a in p.attacks) {
        await txn.insert('attacks', {
          'character_id': newId,
          'name': a.name,
          'to_hit': a.toHit,
          'damage': a.damage,
          'dmg_type': a.dmgType,
          'notes': a.notes,
        });
      }

      // Spells
      for (final s in p.spells) {
        if (s.name.trim().isEmpty) continue;
        final duration = s.duration.trim().isEmpty ? '—' : s.duration.trim();
        await txn.insert('spells', {
          'character_id': newId,
          'name': s.name,
          'level': s.level,
          'duration': duration,
          'prepared': s.prepared,
          'ritual': s.ritual,
          'concentration': s.concentration,
          'school': s.school.isEmpty ? null : s.school,
          'casting_time': s.castingTime.isEmpty ? null : s.castingTime,
          'range_text': s.rangeText.isEmpty ? null : s.rangeText,
          'components': s.components.isEmpty ? null : s.components,
          'description': s.description.isEmpty ? null : s.description,
          'notes': s.notes.isEmpty ? null : s.notes,
        });
      }

      // Traits
      for (final t in p.traits) {
        if (t.name.trim().isEmpty) continue;
        await txn.insert('traits', {
          'character_id': newId,
          'name': t.name,
          'kind': (t.kind ?? '').trim().isEmpty ? null : t.kind,
          'notes': (t.notes ?? '').trim().isEmpty ? null : t.notes,
        });
      }

      // Spell slots (1..9)
      // Guardamos los 9 (si faltan, quedan 0/0)
      for (var lvl = 1; lvl <= 9; lvl++) {
        final row = p.spellSlots[lvl.toString()];
        await txn.insert('spell_slots', {
          'character_id': newId,
          'slot_level': lvl,
          'cur': row?.cur ?? 0,
          'max': row?.max ?? 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Spell points
      await txn.insert('spell_points', {
        'character_id': newId,
        'cur': p.spellPoints.cur,
        'max': p.spellPoints.max,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Dice presets
      for (final dp in p.dicePresets) {
        if (dp.name.trim().isEmpty) continue;
        await txn.insert('dice_presets', {
          'character_id': newId,
          'name': dp.name,
          'dice_count': dp.diceCount,
          'dice_sides': dp.diceSides,
          'modifier': dp.modifier,
        });
      }

      return newId;
    });
  }

  Future<Map<String, Object?>> getCharacter(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'characters',
      where: 'id=?',
      whereArgs: [charId],
      limit: 1,
    );
    return rows.first;
  }

  Future<Map<String, Object?>> getVitals(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'vitals',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    );
    return rows.first;
  }

  Future<void> updateCharacterFields(
    int charId,
    Map<String, Object?> fields,
  ) async {
    final d = await AppDb.instance.db;
    final now = DateTime.now().toIso8601String().split('.').first;
    final data = Map<String, Object?>.from(fields);
    data['updated_at'] = now;
    await d.update('characters', data, where: 'id=?', whereArgs: [charId]);
  }

  Future<void> updateVitalsFields(
    int charId,
    Map<String, Object?> fields,
  ) async {
    final d = await AppDb.instance.db;
    await d.update(
      'vitals',
      fields,
      where: 'character_id=?',
      whereArgs: [charId],
    );
  }

  Future<Map<String, Object?>> getStats(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'stats',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    );
    return rows.first;
  }

  Future<void> updateStatsFields(
    int charId,
    Map<String, Object?> fields,
  ) async {
    final d = await AppDb.instance.db;
    await d.update(
      'stats',
      fields,
      where: 'character_id=?',
      whereArgs: [charId],
    );
  }

  Future<Map<String, SkillRow>> getSkills(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'skills',
      where: 'character_id=?',
      whereArgs: [charId],
    );

    final out = <String, SkillRow>{};
    for (final r in rows) {
      final key = r['skill_key'] as String;
      out[key] = SkillRow(
        proficient: r['proficient'] as int? ?? 0,
        expertise: r['expertise'] as int? ?? 0,
        bonus: r['bonus'] as int? ?? 0,
      );
    }
    return out;
  }

  Future<void> updateSkill(int charId, String skillKey, SkillRow row) async {
    final d = await AppDb.instance.db;
    await d.update(
      'skills',
      {
        'proficient': row.proficient,
        'expertise': row.expertise,
        'bonus': row.bonus,
      },
      where: 'character_id=? AND skill_key=?',
      whereArgs: [charId, skillKey],
    );
  }

  Future<List<Map<String, Object?>>> listInventory(int charId) async {
    final d = await AppDb.instance.db;
    return d.query(
      'inventory',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'id DESC',
    );
  }

  Future<int> addInventoryItem(
    int charId,
    String name,
    int qty,
    String notes,
  ) async {
    final d = await AppDb.instance.db;
    return d.insert('inventory', {
      'character_id': charId,
      'name': name,
      'qty': qty,
      'notes': notes,
    });
  }

  Future<void> updateInventoryItem(int id, Map<String, Object?> fields) async {
    final d = await AppDb.instance.db;
    await d.update('inventory', fields, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteInventoryItem(int id) async {
    final d = await AppDb.instance.db;
    await d.delete('inventory', where: 'id=?', whereArgs: [id]);
  }

  // ---- Currency helpers (stored inside inventory) ----
  static const currencyNote = '__currency__';
  static const currencyKeys = ['cp', 'sp', 'ep', 'gp', 'pp'];

  Future<void> ensureCurrencyRows(int charId) async {
    final d = await AppDb.instance.db;

    final rows = await d.query(
      'inventory',
      where: 'character_id=? AND notes=?',
      whereArgs: [charId, currencyNote],
    );

    final existing = rows
        .map((r) => (r['name'] as String?)?.toLowerCase())
        .toSet();

    for (final k in currencyKeys) {
      if (!existing.contains(k)) {
        await d.insert('inventory', {
          'character_id': charId,
          'name': k,
          'qty': 0,
          'notes': currencyNote,
        });
      }
    }
  }

  Future<Map<String, Map<String, Object?>>> getCurrencyMap(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'inventory',
      where: 'character_id=? AND notes=?',
      whereArgs: [charId, currencyNote],
    );

    // key -> row map (includes id, qty)
    final out = <String, Map<String, Object?>>{};
    for (final r in rows) {
      final key = ((r['name'] as String?) ?? '').toLowerCase();
      if (currencyKeys.contains(key)) out[key] = r;
    }
    return out;
  }

  Future<List<Map<String, Object?>>> listAttacks(int charId) async {
    final d = await AppDb.instance.db;
    return d.query(
      'attacks',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'id DESC',
    );
  }

  Future<int> addAttack(
    int charId, {
    required String name,
    required String toHit,
    required String damage,
    required String dmgType,
    required String notes,
  }) async {
    final d = await AppDb.instance.db;
    return d.insert('attacks', {
      'character_id': charId,
      'name': name,
      'to_hit': toHit,
      'damage': damage,
      'dmg_type': dmgType,
      'notes': notes,
    });
  }

  Future<void> updateAttack(int id, Map<String, Object?> fields) async {
    final d = await AppDb.instance.db;
    await d.update('attacks', fields, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteAttack(int id) async {
    final d = await AppDb.instance.db;
    await d.delete('attacks', where: 'id=?', whereArgs: [id]);
  }

  Future<void> setCurrency(int rowId, int newQty) async {
    final d = await AppDb.instance.db;
    await d.update(
      'inventory',
      {'qty': newQty},
      where: 'id=?',
      whereArgs: [rowId],
    );
  }

  // ---------- SPELLS CRUD ----------
  Future<List<Map<String, Object?>>> listSpells(int charId) async {
    final d = await AppDb.instance.db;
    return d.query(
      'spells',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'level ASC, name COLLATE NOCASE ASC',
    );
  }

  Future<int> addSpell(
    int charId, {
    required String name,
    required int level,
    required String duration,
    required int prepared,
    required int ritual,
    required int concentration,
    String? school,
    String? castingTime,
    String? rangeText,
    String? components,
    String? description,
    String? notes,
  }) async {
    final d = await AppDb.instance.db;
    return d.insert('spells', {
      'character_id': charId,
      'name': name,
      'level': level,
      'duration': duration,
      'prepared': prepared,
      'ritual': ritual,
      'concentration': concentration,
      'school': school,
      'casting_time': castingTime,
      'range_text': rangeText,
      'components': components,
      'description': description,
      'notes': notes,
    });
  }

  Future<void> updateSpell(int id, Map<String, Object?> fields) async {
    final d = await AppDb.instance.db;
    await d.update('spells', fields, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteSpell(int id) async {
    final d = await AppDb.instance.db;
    await d.delete('spells', where: 'id=?', whereArgs: [id]);
  }

  // ---------- SPELL SLOTS ----------
  Future<void> ensureSpellSlotsRows(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'spell_slots',
      where: 'character_id=?',
      whereArgs: [charId],
    );
    final existing = rows.map((r) => r['slot_level'] as int? ?? 0).toSet();

    for (var lvl = 1; lvl <= 9; lvl++) {
      if (!existing.contains(lvl)) {
        await d.insert('spell_slots', {
          'character_id': charId,
          'slot_level': lvl,
          'cur': 0,
          'max': 0,
        });
      }
    }
  }

  Future<Map<int, Map<String, Object?>>> getSpellSlotsMap(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'spell_slots',
      where: 'character_id=?',
      whereArgs: [charId],
    );
    final out = <int, Map<String, Object?>>{};
    for (final r in rows) {
      final lvl = r['slot_level'] as int;
      out[lvl] = r;
    }
    return out;
  }

  Future<void> setSpellSlotCurMax(
    int charId,
    int slotLevel,
    int cur,
    int max,
  ) async {
    final d = await AppDb.instance.db;
    await d.update(
      'spell_slots',
      {'cur': cur, 'max': max},
      where: 'character_id=? AND slot_level=?',
      whereArgs: [charId, slotLevel],
    );
  }

  // ---------- SPELL POINTS ----------
  Future<void> ensureSpellPointsRow(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'spell_points',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    );
    if (rows.isEmpty) {
      await d.insert('spell_points', {
        'character_id': charId,
        'cur': 0,
        'max': 0,
      });
    }
  }

  Future<Map<String, Object?>> getSpellPoints(int charId) async {
    final d = await AppDb.instance.db;
    final rows = await d.query(
      'spell_points',
      where: 'character_id=?',
      whereArgs: [charId],
      limit: 1,
    );
    return rows.first;
  }

  Future<void> setSpellPointsCurMax(int charId, int cur, int max) async {
    final d = await AppDb.instance.db;
    await d.update(
      'spell_points',
      {'cur': cur, 'max': max},
      where: 'character_id=?',
      whereArgs: [charId],
    );
  }

  Future<List<Map<String, Object?>>> listTraits(int charId) async {
    final d = await AppDb.instance.db;
    return d.query(
      'traits',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'id DESC',
    );
  }

  Future<int> addTrait(
    int charId, {
    required String name,
    required String description,
  }) async {
    final d = await AppDb.instance.db;
    return d.insert('traits', {
      'character_id': charId,
      'name': name,
      'description': description,
    });
  }

  Future<void> updateTrait(int id, Map<String, Object?> fields) async {
    final d = await AppDb.instance.db;
    await d.update('traits', fields, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteTrait(int id) async {
    final d = await AppDb.instance.db;
    await d.delete('traits', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> listDicePresets(int charId) async {
    final d = await AppDb.instance.db;
    return d.query(
      'dice_presets',
      where: 'character_id=?',
      whereArgs: [charId],
      orderBy: 'id DESC',
    );
  }

  Future<int> addDicePreset(
    int charId, {
    required String name,
    required int diceCount,
    required int diceSides,
    required int modifier,
  }) async {
    final d = await AppDb.instance.db;
    return d.insert('dice_presets', {
      'character_id': charId,
      'name': name,
      'dice_count': diceCount,
      'dice_sides': diceSides,
      'modifier': modifier,
    });
  }

  Future<void> updateDicePreset(int id, Map<String, Object?> fields) async {
    final d = await AppDb.instance.db;
    await d.update('dice_presets', fields, where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteDicePreset(int id) async {
    final d = await AppDb.instance.db;
    await d.delete('dice_presets', where: 'id=?', whereArgs: [id]);
  }
}
