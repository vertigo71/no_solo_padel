import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debug.dart';
import '../../utilities/date.dart';
import 'players_panel.dart';
import 'config_panel.dart';
import 'sorting_panel.dart';
import '../../interface/app_state.dart';

final String _classString = 'MatchPage'.toUpperCase();

class MatchPage extends StatelessWidget {
  final Date matchDate;

  const MatchPage({super.key, required this.matchDate});

  MatchPage.now({super.key}) : matchDate = Date.now();

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    final bool isLoggedUserAdmin = context.read<AppState>().isLoggedUserAdmin;
    return DefaultTabController(
      length: isLoggedUserAdmin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(matchDate.toString()),
          bottom: TabBar(
            tabs: [
              if (isLoggedUserAdmin) const _TabBarText('Configurar'),
              const _TabBarText('Apuntarse'),
              const _TabBarText('Partidos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            if (isLoggedUserAdmin) ConfigurationPanel(matchDate),
            PlayersPanel(matchDate),
            SortingPanel(matchDate),
          ],
        ),
      ),
    );
  }
}

class _TabBarText extends StatelessWidget {
  const _TabBarText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
        ),
      ),
    );
  }
}
