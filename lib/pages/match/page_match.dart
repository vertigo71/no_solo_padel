import 'package:flutter/material.dart';
import 'package:no_solo_padel/models/match_model.dart';
import 'package:provider/provider.dart';

import '../../interface/director.dart';
import '../../interface/match_notifier.dart';
import '../../models/debug.dart';
import 'panel_players.dart';
import 'panel_config.dart';
import 'sorting/panel_sorting.dart';
import '../../interface/app_state.dart';

final String _classString = 'MatchPage'.toUpperCase();

class MatchPage extends StatelessWidget {
  // argument matchJson vs matchId
  // matchJson: initialValue for FormBuilder will hold the correct initial values
  //   If another user changes any field, the form will not update
  //   A new matchJson will be received. But Form fields won't be updated.
  //   Good for configuration panel
  // matchId: _formKey.currentState?.fields[commentId]?.didChange(match.comment); should be implemented
  //   If any user changes any field, the form will update. Or if any rebuild is made, changes would be lost.
  final Map<String, dynamic> matchJson;

  const MatchPage({super.key, required this.matchJson});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building match $matchJson');

    final bool isLoggedUserAdmin = context.read<AppState>().isLoggedUserAdmin;

    late MyMatch match;
    try {
      match = MyMatch.fromJson(matchJson, context.read<AppState>());
      MyLog.log(_classString, 'match = $match', indent: true);
    } catch (e) {
      return Center(child: Text('No se ha podido acceder al partido'));
    }

    try {
      return ChangeNotifierProvider<MatchNotifier>(
        // create and dispose of MatchNotifier
        create: (context) => MatchNotifier(match, context.read<Director>()),
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
