import 'package:flutter/material.dart';
import '../repositories/character_repository.dart';
import '../services/json_exchange_service.dart';
import 'tabs/ficha_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/inventory_tab.dart';
import 'tabs/attacks_tab.dart';
import 'tabs/spells_tab.dart';
import 'tabs/traits_tab.dart';
import 'tabs/dice_tab.dart';

class CharacterDetailPage extends StatefulWidget {
  final int charId;
  const CharacterDetailPage({super.key, required this.charId});

  @override
  State<CharacterDetailPage> createState() => _CharacterDetailPageState();
}

class _CharacterDetailPageState extends State<CharacterDetailPage>
    with SingleTickerProviderStateMixin {
  final repo = CharacterRepository();
  late final exchange = JsonExchangeService(repo);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Personaje'),
          actions: [
            IconButton(
              tooltip: 'Exportar JSON',
              icon: const Icon(Icons.ios_share),
              onPressed: () async =>
                  exchange.exportCharacterAndShare(widget.charId),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Ficha'),
              Tab(text: 'Stats'),
              Tab(text: 'Inventario'),
              Tab(text: 'Ataques'),
              Tab(text: 'Hechizos'),
              Tab(text: 'Rasgos'),
              Tab(text: 'Dados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FichaTab(charId: widget.charId),
            StatsTab(charId: widget.charId),
            InventoryTab(charId: widget.charId),
            AttacksTab(charId: widget.charId),
            SpellsTab(charId: widget.charId),
            TraitsTab(charId: widget.charId),
            DiceTab(charId: widget.charId),
          ],
        ),
      ),
    );
  }
}
