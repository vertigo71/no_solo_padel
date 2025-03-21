import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/director.dart';
import '../../interface/match_notifier.dart';
import '../../models/debug.dart';
import '../../utilities/date.dart';
import 'players_panel.dart';
import 'config_panel.dart';
import 'sorting_panel.dart';
import '../../interface/app_state.dart';

final String _classString = 'MatchPage'.toUpperCase();

class MatchPage extends StatelessWidget {
  final String matchIdStr;

  const MatchPage({super.key, required this.matchIdStr});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building match $matchIdStr');

    final bool isLoggedUserAdmin = context.read<AppState>().isLoggedUserAdmin;

    Date? matchId = Date.parse(matchIdStr);
    MyLog.log(_classString, 'Parsed date = $matchId', indent: true);

    if (matchId == null) {
      return Center(child: Text('No se ha podido acceder al partido $matchIdStr'));
    }

    try {
      return ChangeNotifierProvider<MatchNotifier>(
        // create and dispose of MatchNotifier
        create: (context) => MatchNotifier(matchId, context.read<Director>()),
        child: Consumer<MatchNotifier>(builder: (context, matchNotifier, _) {
          return DefaultTabController(
            length: isLoggedUserAdmin ? 3 : 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(matchNotifier.match.id.toString()),
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
                  if (isLoggedUserAdmin) ConfigurationPanel(),
                  PlayersPanel(),
                  SortingPanel(),
                ],
              ),
            ),
          );
        }),
      );
    } catch (e) {
      return Center(child: Text(e.toString())); // Display the error message
    }
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
