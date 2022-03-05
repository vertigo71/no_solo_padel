import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debug.dart';
import 'players_panel.dart';
import 'config_panel.dart';
import 'sorting_panel.dart';
import '../../utilities/misc.dart';
import '../../interface/app_state.dart';

final String _classString = 'MatchPage'.toUpperCase();

class MatchPage extends StatelessWidget {
  const MatchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    final Date date = ModalRoute.of(context)!.settings.arguments as Date;
    final bool isLoggedUserAdmin = context.read<AppState>().isLoggedUserAdmin;
    return DefaultTabController(
      length: isLoggedUserAdmin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(date.toString()),
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
            if (isLoggedUserAdmin) ConfigurationPanel(date),
            PlayersPanel(date),
            SortingPanel(date),
          ],
        ),
      ),
    );
  }
}

class _TabBarText extends StatelessWidget {
  const _TabBarText(this.text, {Key? key}) : super(key: key);

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
