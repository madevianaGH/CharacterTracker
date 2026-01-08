import 'package:flutter/material.dart';
import '../repositories/character_repository.dart';
import '../services/json_exchange_service.dart';
import 'character_detail_page.dart';
import '../main.dart';

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  final repo = CharacterRepository();
  late final exchange = JsonExchangeService(repo);

  Future<List<Map<String, Object?>>> _load() => repo.listCharacters();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CharacterTracker (offline)'),
        actions: [
          IconButton(
            tooltip: 'Importar JSON',
            icon: const Icon(Icons.file_open),

            onPressed: () async {
              final id = await exchange.importCharacterFromPicker();
              if (id == null) return;
              if (!context.mounted) return;

              setState(() {});
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CharacterDetailPage(charId: id),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Tema claro/oscuro',
            icon: const Icon(Icons.dark_mode),
            onPressed: () => themeService.toggleLightDark(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = await repo.createCharacter();
          if (!context.mounted) return;

          setState(() {});
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CharacterDetailPage(charId: id)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _load(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('Sin personajes. Creá uno con +'));
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = rows[i];
              final id = r['id'] as int;
              final name = (r['name'] as String?) ?? 'Sin nombre';
              final lvl = (r['level'] as int?) ?? 1;

              return ListTile(
                title: Text(name),
                subtitle: Text('Nv $lvl'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CharacterDetailPage(charId: id),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await repo.deleteCharacter(id);
                    if (!context.mounted) return;
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
