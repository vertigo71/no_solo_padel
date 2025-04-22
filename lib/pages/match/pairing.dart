import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/if_app_state.dart';
import '../../interface/if_match_notifier.dart';
import '../../models/md_debug.dart';
import '../../models/md_match.dart';
import '../../models/md_user.dart';
import '../../utilities/ut_list_view.dart';

final String _classString = 'PairingPanel'.toUpperCase();

class PairingPanel extends StatefulWidget {
  const PairingPanel({super.key});

  @override
  PairingPanelState createState() => PairingPanelState();
}

class PairingPanelState extends State<PairingPanel> {
  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'PairingPanel for match=$match');

    return Column(
      children: <Widget>[
        if (match.comment.isNotEmpty)
          Card(
            elevation: 6,
            margin: const EdgeInsets.all(10),
            child: ListTile(
              tileColor: Theme.of(context).appBarTheme.backgroundColor,
              titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
              title: Text(match.comment),
            ),
          ),
        Card(
          elevation: 6,
          margin: const EdgeInsets.all(10),
          child: ListTile(
            tileColor: Theme.of(context).appBarTheme.backgroundColor,
            titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
            title: Text('Tipo de emparejamiento: ${match.pairingType.label}'),
          ),
        ),
        Expanded(
          child: PairingSubPanel(pairingType: match.pairingType),
        ),
      ],
    );
  }
}

class PairingSubPanel extends StatelessWidget {
  const PairingSubPanel({super.key, required MatchPairingType pairingType}) : _pairingType = pairingType;
  final MatchPairingType _pairingType;

  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'PairingSubPanel pairingType=${_pairingType.name}, match=$match');

    Map<int, List<int>> courtPlayers;
    switch (_pairingType) {
      case MatchPairingType.ranking:
        courtPlayers = match.getRankingPlayerPairs();
        break;
      case MatchPairingType.palindromic:
        courtPlayers = match.getPalindromicPlayerPairs();
        break;
      case MatchPairingType.random:
        courtPlayers = match.getRandomPlayerPairs();
        break;
    }

    return _listViewOfMatches(context, courtPlayers);
  }

  Widget _listViewOfMatches(BuildContext context, Map<int, List<int>> pairingPlayers) {
    MyMatch match = context.read<MatchNotifier>().match;
    int filledCourts = match.numberOfFilledCourts;
    MyListView<MyUser> matchPlayers = match.players;
    MyLog.log(_classString, 'listOfMatches courts = $filledCourts', indent: true);
    MyLog.log(_classString, 'listOfMatches matchPlayers = $matchPlayers, courtPlayers = $pairingPlayers', indent: true);

    MyListView<MyUser> usersSortedByRanking = context.read<AppState>().usersSortedByRanking;

    if (pairingPlayers.isEmpty) {
      return const Center(child: Text('No hay jugadores apuntados'));
    } else {
      return ListView(children: [
        for (int court = 0; court < filledCourts; court++)
          Card(
            elevation: 6,
            margin: const EdgeInsets.all(10),
            child: ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceBright,
              leading: CircleAvatar(
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  child: Text(
                    match.courtNames[court],
                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                  )),
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${_getPlayerText(court, 0, matchPlayers, pairingPlayers, usersSortedByRanking)} y '
                  '${_getPlayerText(court, 1, matchPlayers, pairingPlayers, usersSortedByRanking)}\n\n'
                  '${_getPlayerText(court, 2, matchPlayers, pairingPlayers, usersSortedByRanking)} y '
                  '${_getPlayerText(court, 3, matchPlayers, pairingPlayers, usersSortedByRanking)}',
                ),
              ),
            ),
          ),
      ]);
    }
  }

  String _getPlayerText(int court, int index, MyListView<MyUser> matchPlayers, Map<int, List<int>> pairingPlayers,
          MyListView<MyUser> usersSortedByRanking) =>
      '${matchPlayers[pairingPlayers[court]![index]].name} '
      '<${usersSortedByRanking.indexOf(matchPlayers[pairingPlayers[court]![index]]) + 1}>';
}
