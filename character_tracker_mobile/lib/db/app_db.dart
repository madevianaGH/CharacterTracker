import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppDb {
  static final AppDb instance = AppDb._();
  AppDb._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'characters.db');

    final database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (d, v) async {
        await _createSchema(d);
      },
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON;');
      },
    );

    _db = database;
    return database;
  }

  Future<void> _createSchema(Database d) async {
    await d.execute('''
      CREATE TABLE IF NOT EXISTS characters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL DEFAULT 'Nuevo personaje',
        race TEXT DEFAULT '',
        class TEXT DEFAULT '',
        level INTEGER NOT NULL DEFAULT 1,
        background TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        updated_at TEXT DEFAULT ''
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS stats (
        character_id INTEGER PRIMARY KEY,
        str INTEGER NOT NULL DEFAULT 10,
        dex INTEGER NOT NULL DEFAULT 10,
        con INTEGER NOT NULL DEFAULT 10,
        int INTEGER NOT NULL DEFAULT 10,
        wis INTEGER NOT NULL DEFAULT 10,
        cha INTEGER NOT NULL DEFAULT 10,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS skills (
        character_id INTEGER NOT NULL,
        skill_key TEXT NOT NULL,
        proficient INTEGER NOT NULL DEFAULT 0,
        expertise INTEGER NOT NULL DEFAULT 0,
        bonus INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(character_id, skill_key),
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS attacks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        to_hit TEXT NOT NULL DEFAULT '',
        damage TEXT NOT NULL DEFAULT '',
        dmg_type TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS spells (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 0,
        duration TEXT NOT NULL,
        prepared INTEGER NOT NULL DEFAULT 0,
        ritual INTEGER NOT NULL DEFAULT 0,
        concentration INTEGER NOT NULL DEFAULT 0,
        school TEXT NULL,
        casting_time TEXT NULL,
        range_text TEXT NULL,
        components TEXT NULL,
        description TEXT NULL,
        notes TEXT NULL,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS spell_slots (
        character_id INTEGER NOT NULL,
        slot_level INTEGER NOT NULL,
        cur INTEGER NOT NULL DEFAULT 0,
        max INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(character_id, slot_level),
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS spell_points (
        character_id INTEGER PRIMARY KEY,
        cur INTEGER NOT NULL DEFAULT 0,
        max INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS traits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        kind TEXT NULL,
        notes TEXT NULL,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS vitals (
        character_id INTEGER PRIMARY KEY,
        hp_cur INTEGER NOT NULL DEFAULT 0,
        hp_max INTEGER NOT NULL DEFAULT 0,
        temp_hp INTEGER NOT NULL DEFAULT 0,
        ac INTEGER NOT NULL DEFAULT 10,
        initiative_bonus INTEGER NOT NULL DEFAULT 0,
        speed INTEGER NOT NULL DEFAULT 30,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS dice_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        dice_count INTEGER NOT NULL DEFAULT 1,
        dice_sides INTEGER NOT NULL DEFAULT 20,
        modifier INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(character_id) REFERENCES characters(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final d = _db;
    _db = null;
    await d?.close();
  }
}
