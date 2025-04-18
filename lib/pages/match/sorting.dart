import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/if_app_state.dart';
import '../../interface/if_match_notifier.dart';
import '../../models/md_debug.dart';
import '../../models/md_match.dart';
import '../../models/md_user.dart';

final String _classString = 'SortingPanel'.toUpperCase();

class SortingPanel extends StatefulWidget {
  const SortingPanel({super.key});

  @override
  SortingPanelState createState() => SortingPanelState();
}

class SortingPanelState extends State<SortingPanel> {
  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'SortingPanel for match=$match');

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
            title: Text('Tipo de sorteo: ${match.sortingType.label}'),
          ),
        ),
        Expanded(
          child: SortingSubPanel(sortingType: match.sortingType),
        ),
      ],
    );
  }
}

class SortingSubPanel extends StatelessWidget {
  const SortingSubPanel({super.key, required MatchSortingType sortingType}) : _sortingType = sortingType;
  final MatchSortingType _sortingType;

  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'SortingSubPanel sortingType=${_sortingType.name}, match=$match');

    Map<int, List<int>> courtPlayers;
    switch (_sortingType) {
      case MatchSortingType.ranking:
        courtPlayers = match.getRankingPlayerPairs();
        break;
      case MatchSortingType.palindromic:
        courtPlayers = match.getPalindromicPlayerPairs();
        break;
      case MatchSortingType.random:
        courtPlayers = match.getRandomPlayerPairs();
        break;
    }

    return _listViewOfMatches(context, courtPlayers);
  }

  Widget _listViewOfMatches(BuildContext context, Map<int, List<int>> sortedPlayers) {
    MyMatch match = context.read<MatchNotifier>().match;
    int filledCourts = match.numberOfFilledCourts;
    UnmodifiableListView<MyUser> roMatchPlayers = match.unmodifiablePlayers;
    MyLog.log(_classString, 'listOfMatches courts = $filledCourts', indent: true);
    MyLog.log(_classString, 'listOfMatches matchPlayers = $roMatchPlayers, courtPlayers = $sortedPlayers',
        indent: true);

    UnmodifiableListView<MyUser> roRankingSortedUsers =
        context.read<AppState>().getUnmodifiableSortedUsers(sortBy: UsersSortBy.ranking);

    if (sortedPlayers.isEmpty) {
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
                    match.unmodifiableCourtNames.elementAt(court),
                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                  )),
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${_getPlayerText(court, 0, roMatchPlayers, sortedPlayers, roRankingSortedUsers)} y '
                  '${_getPlayerText(court, 1, roMatchPlayers, sortedPlayers, roRankingSortedUsers)}\n\n'
                  '${_getPlayerText(court, 2, roMatchPlayers, sortedPlayers, roRankingSortedUsers)} y '
                  '${_getPlayerText(court, 3, roMatchPlayers, sortedPlayers, roRankingSortedUsers)}',
                ),
              ),
            ),
          ),
      ]);
    }
  }

  String _getPlayerText(int court, int index, UnmodifiableListView<MyUser> roMatchPlayers,
          Map<int, List<int>> sortedPlayers, UnmodifiableListView<MyUser> roRankingSortedUsers) =>
      '${roMatchPlayers[sortedPlayers[court]![index]].name} '
      '<${roRankingSortedUsers.indexOf(roMatchPlayers[sortedPlayers[court]![index]]) + 1}>';
}
