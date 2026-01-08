 class ExportPayloadV2 {
  final int schemaVersion; // = 2
  final String exportedAt; // ISO string
  final CharacterSheet character;
  final Vitals vitals;
  final Stats stats;
  final Map<String, SkillRow> skills; // key: "acrobatics" etc
  final List<InventoryItem> inventory;
  final List<AttackRow> attacks;
  final List<SpellRow> spells;
  final List<TraitRow> traits;
  final Map<String, SlotRow> spellSlots; // keys "1".."9"
  final SpellPoints spellPoints;
  final List<DicePreset> dicePresets;

  ExportPayloadV2({
    required this.schemaVersion,
    required this.exportedAt,
    required this.character,
    required this.vitals,
    required this.stats,
    required this.skills,
    required this.inventory,
    required this.attacks,
    required this.spells,
    required this.traits,
    required this.spellSlots,
    required this.spellPoints,
    required this.dicePresets,
  });

  factory ExportPayloadV2.fromJson(Map<String, dynamic> j) {
    final slotsAny = (j['spell_slots'] as Map?)?.cast<dynamic, dynamic>() ?? {};
    final slots = <String, SlotRow>{};
    for (final e in slotsAny.entries) {
      final k = e.key.toString(); // acepta int o string
      slots[k] = SlotRow.fromJson((e.value as Map).cast<String, dynamic>());
    }

    final skillsAny = (j['skills'] as Map?)?.cast<dynamic, dynamic>() ?? {};
    final skills = <String, SkillRow>{};
    for (final e in skillsAny.entries) {
      skills[e.key.toString()] = SkillRow.fromJson((e.value as Map).cast<String, dynamic>());
    }

    return ExportPayloadV2(
      schemaVersion: (j['schema_version'] as num?)?.toInt() ?? 2,
      exportedAt: (j['exported_at'] as String?) ?? '',
      character: CharacterSheet.fromJson((j['character'] as Map).cast<String, dynamic>()),
      vitals: Vitals.fromJson((j['vitals'] as Map).cast<String, dynamic>()),
      stats: Stats.fromJson((j['stats'] as Map).cast<String, dynamic>()),
      skills: skills,
      inventory: ((j['inventory'] as List?) ?? [])
          .map((x) => InventoryItem.fromJson((x as Map).cast<String, dynamic>()))
          .toList(),
      attacks: ((j['attacks'] as List?) ?? [])
          .map((x) => AttackRow.fromJson((x as Map).cast<String, dynamic>()))
          .toList(),
      spells: ((j['spells'] as List?) ?? [])
          .map((x) => SpellRow.fromJson((x as Map).cast<String, dynamic>()))
          .toList(),
      traits: ((j['traits'] as List?) ?? [])
          .map((x) => TraitRow.fromJson((x as Map).cast<String, dynamic>()))
          .toList(),
      spellSlots: slots,
      spellPoints: SpellPoints.fromJson((j['spell_points'] as Map).cast<String, dynamic>()),
      dicePresets: ((j['dice_presets'] as List?) ?? [])
          .map((x) => DicePreset.fromJson((x as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'exported_at': exportedAt,
        'character': character.toJson(),
        'vitals': vitals.toJson(),
        'stats': stats.toJson(),
        'skills': skills.map((k, v) => MapEntry(k, v.toJson())),
        'inventory': inventory.map((x) => x.toJson()).toList(),
        'attacks': attacks.map((x) => x.toJson()).toList(),
        'spells': spells.map((x) => x.toJson()).toList(),
        'traits': traits.map((x) => x.toJson()).toList(),
        'spell_slots': spellSlots.map((k, v) => MapEntry(k, v.toJson())),
        'spell_points': spellPoints.toJson(),
        'dice_presets': dicePresets.map((x) => x.toJson()).toList(),
      };
}

class CharacterSheet {
  final String name;
  final String race;
  final String klass; // "class" es palabra reservada
  final int level;
  final String background;
  final String notes;

  CharacterSheet({
    required this.name,
    required this.race,
    required this.klass,
    required this.level,
    required this.background,
    required this.notes,
  });

  factory CharacterSheet.fromJson(Map<String, dynamic> j) => CharacterSheet(
        name: (j['name'] as String?) ?? '',
        race: (j['race'] as String?) ?? '',
        klass: (j['class'] as String?) ?? '',
        level: (j['level'] as num?)?.toInt() ?? 1,
        background: (j['background'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'race': race,
        'class': klass,
        'level': level,
        'background': background,
        'notes': notes,
      };
}

class Vitals {
  final int hpCur, hpMax, tempHp, ac, initiativeBonus, speed;

  Vitals({
    required this.hpCur,
    required this.hpMax,
    required this.tempHp,
    required this.ac,
    required this.initiativeBonus,
    required this.speed,
  });

  factory Vitals.fromJson(Map<String, dynamic> j) => Vitals(
        hpCur: (j['hp_cur'] as num?)?.toInt() ?? 0,
        hpMax: (j['hp_max'] as num?)?.toInt() ?? 0,
        tempHp: (j['temp_hp'] as num?)?.toInt() ?? 0,
        ac: (j['ac'] as num?)?.toInt() ?? 10,
        initiativeBonus: (j['initiative_bonus'] as num?)?.toInt() ?? 0,
        speed: (j['speed'] as num?)?.toInt() ?? 30,
      );

  Map<String, dynamic> toJson() => {
        'hp_cur': hpCur,
        'hp_max': hpMax,
        'temp_hp': tempHp,
        'ac': ac,
        'initiative_bonus': initiativeBonus,
        'speed': speed,
      };
}

class Stats {
  final int str, dex, con, int_, wis, cha;

  Stats({
    required this.str,
    required this.dex,
    required this.con,
    required this.int_,
    required this.wis,
    required this.cha,
  });

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        str: (j['str'] as num?)?.toInt() ?? 10,
        dex: (j['dex'] as num?)?.toInt() ?? 10,
        con: (j['con'] as num?)?.toInt() ?? 10,
        int_: (j['int'] as num?)?.toInt() ?? 10,
        wis: (j['wis'] as num?)?.toInt() ?? 10,
        cha: (j['cha'] as num?)?.toInt() ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'str': str,
        'dex': dex,
        'con': con,
        'int': int_,
        'wis': wis,
        'cha': cha,
      };
}

class SkillRow {
  final int proficient; // 0/1
  final int expertise; // 0/1
  final int bonus; // int

  SkillRow({required this.proficient, required this.expertise, required this.bonus});

  factory SkillRow.fromJson(Map<String, dynamic> j) => SkillRow(
        proficient: (j['proficient'] as num?)?.toInt() ?? 0,
        expertise: (j['expertise'] as num?)?.toInt() ?? 0,
        bonus: (j['bonus'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'proficient': proficient,
        'expertise': expertise,
        'bonus': bonus,
      };
}

class InventoryItem {
  final String name;
  final int qty;
  final String notes;

  InventoryItem({required this.name, required this.qty, required this.notes});

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        name: (j['name'] as String?) ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        notes: (j['notes'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'notes': notes};
}

class AttackRow {
  final String name, toHit, damage, dmgType, notes;

  AttackRow({required this.name, required this.toHit, required this.damage, required this.dmgType, required this.notes});

  factory AttackRow.fromJson(Map<String, dynamic> j) => AttackRow(
        name: (j['name'] as String?) ?? '',
        toHit: (j['to_hit'] as String?) ?? '',
        damage: (j['damage'] as String?) ?? '',
        dmgType: (j['dmg_type'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'to_hit': toHit,
        'damage': damage,
        'dmg_type': dmgType,
        'notes': notes,
      };
}

class SpellRow {
  final String name;
  final int level;
  final int prepared, ritual, concentration;
  final String school, castingTime, rangeText, components, duration, description, notes;

  SpellRow({
    required this.name,
    required this.level,
    required this.prepared,
    required this.ritual,
    required this.concentration,
    required this.school,
    required this.castingTime,
    required this.rangeText,
    required this.components,
    required this.duration,
    required this.description,
    required this.notes,
  });

  factory SpellRow.fromJson(Map<String, dynamic> j) => SpellRow(
        name: (j['name'] as String?) ?? '',
        level: (j['level'] as num?)?.toInt() ?? 0,
        prepared: (j['prepared'] as num?)?.toInt() ?? 0,
        ritual: (j['ritual'] as num?)?.toInt() ?? 0,
        concentration: (j['concentration'] as num?)?.toInt() ?? 0,
        school: (j['school'] as String?) ?? '',
        castingTime: (j['casting_time'] as String?) ?? '',
        rangeText: (j['range_text'] as String?) ?? '',
        components: (j['components'] as String?) ?? '',
        duration: (j['duration'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
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
      };
}

class TraitRow {
  final String name;
  final String? kind;
  final String? notes;

  TraitRow({required this.name, this.kind, this.notes});

  factory TraitRow.fromJson(Map<String, dynamic> j) => TraitRow(
        name: (j['name'] as String?) ?? '',
        kind: j['kind'] as String?,
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        'notes': notes,
      };
}

class SlotRow {
  final int cur;
  final int max;

  SlotRow({required this.cur, required this.max});

  factory SlotRow.fromJson(Map<String, dynamic> j) => SlotRow(
        cur: (j['cur'] as num?)?.toInt() ?? 0,
        max: (j['max'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'cur': cur, 'max': max};
}

class SpellPoints {
  final int cur;
  final int max;

  SpellPoints({required this.cur, required this.max});

  factory SpellPoints.fromJson(Map<String, dynamic> j) => SpellPoints(
        cur: (j['cur'] as num?)?.toInt() ?? 0,
        max: (j['max'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'cur': cur, 'max': max};
}

class DicePreset {
  final String name;
  final int diceCount;
  final int diceSides;
  final int modifier;

  DicePreset({required this.name, required this.diceCount, required this.diceSides, required this.modifier});

  factory DicePreset.fromJson(Map<String, dynamic> j) => DicePreset(
        name: (j['name'] as String?) ?? '',
        diceCount: (j['dice_count'] as num?)?.toInt() ?? 1,
        diceSides: (j['dice_sides'] as num?)?.toInt() ?? 20,
        modifier: (j['modifier'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dice_count': diceCount,
        'dice_sides': diceSides,
        'modifier': modifier,
      };
}
