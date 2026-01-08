import 'dart:convert';
import '../models/models.dart';
import '../services/web_cache_store.dart';

class CharacterRepository {
  final _store = WebCacheStore();

  // OJO: tu StatsTab usa CharacterRepository.skillKeys
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

  // monedas en inventory (igual que mobile)
  static const currencyNote = '__currency__';
  static const currencyKeys = ['cp', 'sp', 'ep', 'gp', 'pp'];

  // ----------------- Helpers -----------------
  Future<List<Map<String, dynamic>>> _all() => _store.loadAll();
  Future<void> _save(List<Map<String, dynamic>> all) => _store.saveAll(all);

  int _nextCharId(List<Map<String, dynamic>> all) {
    var maxId = 0;
    for (final e in all) {
      final id = (e['id'] as num?)?.toInt() ?? 0;
      if (id > maxId) maxId = id;
    }
    return maxId + 1;
  }

  Map<String, dynamic> _findData(List<Map<String, dynamic>> all, int charId) {
    final env = all.firstWhere((e) => (e['id'] as num).toInt() == charId);
    return (env['data'] as Map).cast<String, dynamic>();
  }

  void _writeData(
    List<Map<String, dynamic>> all,
    int charId,
    Map<String, dynamic> data,
  ) {
    final i = all.indexWhere((e) => (e['id'] as num).toInt() == charId);
    all[i] = {'id': charId, 'data': data};
  }

  int _nextLocalId(Map<String, dynamic> data, String key) {
    data['_local'] ??= <String, dynamic>{};
    final local = (data['_local'] as Map).cast<String, dynamic>();
    final k = 'next_$key';
    final cur = (local[k] as num?)?.toInt() ?? 1;
    local[k] = cur + 1;
    data['_local'] = local;
    return cur;
  }

  List<Map<String, dynamic>> _listOf(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is List)
      return v.map((e) => (e as Map).cast<String, dynamic>()).toList();
    return [];
  }

  // elimina _id internos al exportar
  dynamic _stripInternal(dynamic v) {
    if (v is List) return v.map(_stripInternal).toList();
    if (v is Map) {
      final out = <String, dynamic>{};
      v.forEach((k, val) {
        if (k == '_id' || k == '_local') return;
        out[k.toString()] = _stripInternal(val);
      });
      return out;
    }
    return v;
  }

  Map<String, dynamic> _newEmptyV2() {
    final skills = <String, dynamic>{};
    for (final k in skillKeys) {
      skills[k] = {'proficient': 0, 'expertise': 0, 'bonus': 0};
    }

    final slots = <String, dynamic>{};
    for (var i = 1; i <= 9; i++) {
      slots['$i'] = {'cur': 0, 'max': 0};
    }

    return {
      'schema_version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'character': {
        'name': '',
        'race': '',
        'class': '',
        'level': 1,
        'background': '',
        'notes': '',
      },
      'vitals': {
        'hp_cur': 0,
        'hp_max': 0,
        'temp_hp': 0,
        'ac': 10,
        'initiative_bonus': 0,
        'speed': 30,
      },
      'stats': {
        'str': 10,
        'dex': 10,
        'con': 10,
        'int': 10,
        'wis': 10,
        'cha': 10,
      },
      'skills': skills,
      'inventory': <dynamic>[],
      'attacks': <dynamic>[],
      'spells': <dynamic>[],
      'traits': <dynamic>[],
      'spell_slots': slots,
      'spell_points': {'cur': 0, 'max': 0},
      'dice_presets': <dynamic>[],
      '_local': <String, dynamic>{},
    };
  }

  // ----------------- Character list -----------------
  Future<List<Map<String, Object?>>> listCharacters() async {
    final all = await _all();
    return all.map((e) {
      final id = (e['id'] as num).toInt();
      final data = (e['data'] as Map).cast<String, dynamic>();
      final ch = (data['character'] as Map).cast<String, dynamic>();
      return {
        'id': id,
        'name': ch['name'] as String?,
        'level': (ch['level'] as num?)?.toInt(),
      };
    }).toList();
  }

  Future<int> createCharacter() async {
    final all = await _all();
    final id = _nextCharId(all);
    all.add({'id': id, 'data': _newEmptyV2()});
    await _save(all);
    return id;
  }

  Future<void> deleteCharacter(int charId) async {
    final all = await _all();
    all.removeWhere((e) => (e['id'] as num).toInt() == charId);
    await _save(all);
  }

  // ----------------- Get/update character -----------------
  Future<Map<String, Object?>> getCharacter(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final ch = (data['character'] as Map).cast<String, dynamic>();
    return {
      'name': ch['name'],
      'race': ch['race'],
      'class': ch['class'],
      'level': (ch['level'] as num?)?.toInt() ?? 1,
      'background': ch['background'],
      'notes': ch['notes'],
    };
  }

  Future<void> updateCharacterFields(
    int charId,
    Map<String, Object?> fields,
  ) async {
    final all = await _all();
    final data = _findData(all, charId);
    final ch = (data['character'] as Map).cast<String, dynamic>();
    fields.forEach((k, v) => ch[k] = v);
    data['character'] = ch;
    _writeData(all, charId, data);
    await _save(all);
  }

  // ----------------- Vitals -----------------
  Future<Map<String, Object?>> getVitals(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    return (data['vitals'] as Map).cast<String, Object?>();
  }

  Future<void> updateVitalsFields(
    int charId,
    Map<String, Object?> fields,
  ) async {
    final all = await _all();
    final data = _findData(all, charId);
    final v = (data['vitals'] as Map).cast<String, dynamic>();
    fields.forEach((k, val) => v[k] = val);
    data['vitals'] = v;
    _writeData(all, charId, data);
    await _save(all);
  }

  // ----------------- Stats -----------------
  Future<Map<String, Object?>> getStats(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    return (data['stats'] as Map).cast<String, Object?>();
  }

  Future<void> updateStatsFields(
    int charId,
    Map<String, Object?> fields,
  ) async {
    final all = await _all();
    final data = _findData(all, charId);
    final s = (data['stats'] as Map).cast<String, dynamic>();
    fields.forEach((k, val) => s[k] = val);
    data['stats'] = s;
    _writeData(all, charId, data);
    await _save(all);
  }

  // ----------------- Skills -----------------
  Future<Map<String, SkillRow>> getSkills(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final sk = (data['skills'] as Map).cast<String, dynamic>();

    final out = <String, SkillRow>{};
    for (final k in skillKeys) {
      final r = (sk[k] as Map?)?.cast<String, dynamic>() ?? {};
      out[k] = SkillRow(
        proficient: (r['proficient'] as num?)?.toInt() ?? 0,
        expertise: (r['expertise'] as num?)?.toInt() ?? 0,
        bonus: (r['bonus'] as num?)?.toInt() ?? 0,
      );
    }
    return out;
  }

  Future<void> updateSkill(int charId, String skillKey, SkillRow row) async {
    final all = await _all();
    final data = _findData(all, charId);
    final sk = (data['skills'] as Map).cast<String, dynamic>();
    sk[skillKey] = {
      'proficient': row.proficient,
      'expertise': row.expertise,
      'bonus': row.bonus,
    };
    data['skills'] = sk;
    _writeData(all, charId, data);
    await _save(all);
  }

  // ----------------- Inventory (con monedas) -----------------
  Future<void> ensureCurrencyRows(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final inv = _listOf(data, 'inventory');

    final existing = inv
        .where((e) => e['notes'] == currencyNote)
        .map((e) => (e['name'] as String).toLowerCase())
        .toSet();

    for (final k in currencyKeys) {
      if (!existing.contains(k)) {
        inv.add({
          '_id': _nextLocalId(data, 'inv'),
          'name': k,
          'qty': 0,
          'notes': currencyNote,
        });
      }
    }

    data['inventory'] = inv;
    _writeData(all, charId, data);
    await _save(all);
  }

  Future<List<Map<String, Object?>>> listInventory(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final inv = _listOf(data, 'inventory');
    return inv
        .map(
          (e) => {
            'id': (e['_id'] as num?)?.toInt(),
            'name': e['name'],
            'qty': (e['qty'] as num?)?.toInt(),
            'notes': e['notes'],
          },
        )
        .toList();
  }

  Future<int> addInventoryItem(
    int charId,
    String name,
    int qty,
    String notes,
  ) async {
    final all = await _all();
    final data = _findData(all, charId);
    final inv = _listOf(data, 'inventory');
    final id = _nextLocalId(data, 'inv');
    inv.add({'_id': id, 'name': name, 'qty': qty, 'notes': notes});
    data['inventory'] = inv;
    _writeData(all, charId, data);
    await _save(all);
    return id;
  }

  Future<void> updateInventoryItem(int id, Map<String, Object?> fields) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final inv = _listOf(data, 'inventory');
      final i = inv.indexWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (i >= 0) {
        fields.forEach((k, v) => inv[i][k] = v);
        data['inventory'] = inv;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final inv = _listOf(data, 'inventory');
      final before = inv.length;
      inv.removeWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (inv.length != before) {
        data['inventory'] = inv;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<Map<String, Map<String, Object?>>> getCurrencyMap(int charId) async {
    final rows = await listInventory(charId);
    final out = <String, Map<String, Object?>>{};
    for (final r in rows) {
      if ((r['notes'] as String?) == currencyNote) {
        final k = ((r['name'] as String?) ?? '').toLowerCase();
        out[k] = r;
      }
    }
    return out;
  }

  Future<void> setCurrency(int rowId, int newQty) async {
    await updateInventoryItem(rowId, {'qty': newQty});
  }

  // ----------------- Attacks -----------------
  Future<List<Map<String, Object?>>> listAttacks(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'attacks');
    return list
        .map(
          (e) => {
            'id': (e['_id'] as num?)?.toInt(),
            'name': e['name'],
            'to_hit': e['to_hit'],
            'damage': e['damage'],
            'dmg_type': e['dmg_type'],
            'notes': e['notes'],
          },
        )
        .toList();
  }

  Future<int> addAttack(
    int charId, {
    required String name,
    required String toHit,
    required String damage,
    required String dmgType,
    required String notes,
  }) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'attacks');
    final id = _nextLocalId(data, 'atk');
    list.add({
      '_id': id,
      'name': name,
      'to_hit': toHit,
      'damage': damage,
      'dmg_type': dmgType,
      'notes': notes,
    });
    data['attacks'] = list;
    _writeData(all, charId, data);
    await _save(all);
    return id;
  }

  Future<void> updateAttack(int id, Map<String, Object?> fields) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'attacks');
      final i = list.indexWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (i >= 0) {
        fields.forEach((k, v) => list[i][k] = v);
        data['attacks'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<void> deleteAttack(int id) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'attacks');
      final before = list.length;
      list.removeWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (list.length != before) {
        data['attacks'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  // ----------------- Spells / Slots / Points / Traits / Dice presets -----------------
  // Para mantener esto manejable: en Web demo, el resto lo guardamos igual que arriba
  // usando listas con _id y maps, y en export se limpia _id automáticamente.

  Future<void> ensureSpellSlotsRows(int charId) async {}
  Future<void> ensureSpellPointsRow(int charId) async {}

  Future<Map<int, Map<String, Object?>>> getSpellSlotsMap(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final slots = (data['spell_slots'] as Map).cast<String, dynamic>();
    final out = <int, Map<String, Object?>>{};
    slots.forEach((k, v) {
      final lvl = int.tryParse(k) ?? 0;
      final m = (v as Map).cast<String, dynamic>();
      out[lvl] = {
        'slot_level': lvl,
        'cur': (m['cur'] as num?)?.toInt() ?? 0,
        'max': (m['max'] as num?)?.toInt() ?? 0,
      };
    });
    return out;
  }

  Future<void> setSpellSlotCurMax(
    int charId,
    int slotLevel,
    int cur,
    int max,
  ) async {
    final all = await _all();
    final data = _findData(all, charId);
    final slots = (data['spell_slots'] as Map).cast<String, dynamic>();
    slots['$slotLevel'] = {'cur': cur, 'max': max};
    data['spell_slots'] = slots;
    _writeData(all, charId, data);
    await _save(all);
  }

  Future<Map<String, Object?>> getSpellPoints(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    return (data['spell_points'] as Map).cast<String, Object?>();
  }

  Future<void> setSpellPointsCurMax(int charId, int cur, int max) async {
    final all = await _all();
    final data = _findData(all, charId);
    data['spell_points'] = {'cur': cur, 'max': max};
    _writeData(all, charId, data);
    await _save(all);
  }

  Future<List<Map<String, Object?>>> listSpells(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'spells');
    return list
        .map((e) => {'id': (e['_id'] as num?)?.toInt(), ...e..remove('_id')})
        .toList();
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
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'spells');
    final id = _nextLocalId(data, 'spl');
    list.add({
      '_id': id,
      'name': name,
      'level': level,
      'prepared': prepared,
      'ritual': ritual,
      'concentration': concentration,
      'school': school,
      'casting_time': castingTime,
      'range_text': rangeText,
      'components': components,
      'duration': duration,
      'description': description,
      'notes': notes,
    });
    data['spells'] = list;
    _writeData(all, charId, data);
    await _save(all);
    return id;
  }

  Future<void> updateSpell(int id, Map<String, Object?> fields) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'spells');
      final i = list.indexWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (i >= 0) {
        fields.forEach((k, v) => list[i][k] = v);
        data['spells'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<void> deleteSpell(int id) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'spells');
      final before = list.length;
      list.removeWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (list.length != before) {
        data['spells'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<List<Map<String, Object?>>> listTraits(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'traits');
    return list
        .map((e) => {'id': (e['_id'] as num?)?.toInt(), ...e..remove('_id')})
        .toList();
  }

  Future<int> addTrait(
    int charId, {
    required String name,
    required String description,
  }) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'traits');
    final id = _nextLocalId(data, 'trt');
    list.add({'_id': id, 'name': name, 'description': description});
    data['traits'] = list;
    _writeData(all, charId, data);
    await _save(all);
    return id;
  }

  Future<void> updateTrait(int id, Map<String, Object?> fields) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'traits');
      final i = list.indexWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (i >= 0) {
        fields.forEach((k, v) => list[i][k] = v);
        data['traits'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<void> deleteTrait(int id) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'traits');
      final before = list.length;
      list.removeWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (list.length != before) {
        data['traits'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<List<Map<String, Object?>>> listDicePresets(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'dice_presets');
    return list
        .map((e) => {'id': (e['_id'] as num?)?.toInt(), ...e..remove('_id')})
        .toList();
  }

  Future<int> addDicePreset(
    int charId, {
    required String name,
    required int diceCount,
    required int diceSides,
    required int modifier,
  }) async {
    final all = await _all();
    final data = _findData(all, charId);
    final list = _listOf(data, 'dice_presets');
    final id = _nextLocalId(data, 'dpr');
    list.add({
      '_id': id,
      'name': name,
      'dice_count': diceCount,
      'dice_sides': diceSides,
      'modifier': modifier,
    });
    data['dice_presets'] = list;
    _writeData(all, charId, data);
    await _save(all);
    return id;
  }

  Future<void> updateDicePreset(int id, Map<String, Object?> fields) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'dice_presets');
      final i = list.indexWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (i >= 0) {
        fields.forEach((k, v) => list[i][k] = v);
        data['dice_presets'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  Future<void> deleteDicePreset(int id) async {
    final all = await _all();
    for (final env in all) {
      final data = (env['data'] as Map).cast<String, dynamic>();
      final list = _listOf(data, 'dice_presets');
      final before = list.length;
      list.removeWhere((e) => (e['_id'] as num?)?.toInt() == id);
      if (list.length != before) {
        data['dice_presets'] = list;
        env['data'] = data;
        await _save(all);
        return;
      }
    }
  }

  // ----------------- Import / Export (v2) -----------------
  Future<ExportPayloadV2> buildExportPayload(int charId) async {
    final all = await _all();
    final data = _findData(all, charId);
    final clean =
        _stripInternal(jsonDecode(jsonEncode(data))) as Map<String, dynamic>;
    return ExportPayloadV2.fromJson(clean);
  }

  Future<int> importPayloadV2(ExportPayloadV2 payload) async {
    final all = await _all();
    final id = _nextCharId(all);

    // data base (sin ids), pero cache necesita _id en listas para CRUD
    final data = payload.toJson();
    data['_local'] = <String, dynamic>{};

    void addIds(String key, String localKey) {
      final list = (data[key] as List?)?.cast<Map>() ?? [];
      final out = <dynamic>[];
      for (final item in list) {
        final m = item.cast<String, dynamic>();
        m['_id'] = _nextLocalId(data, localKey);
        out.add(m);
      }
      data[key] = out;
    }

    addIds('inventory', 'inv');
    addIds('attacks', 'atk');
    addIds('spells', 'spl');
    addIds('traits', 'trt');
    addIds('dice_presets', 'dpr');

    all.add({'id': id, 'data': data});
    await _save(all);
    return id;
  }
}
