import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/if_app_state.dart';
import '../../interface/if_match_notifier.dart';
import '../../models/md_debug.dart';
import '../../models/md_match.dart';
import '../../models/md_user.dart';

final String _classString = 'SortingPanel'.toUpperCase();

enum SortingType {
  ranking('Ranking'),
  palindromic('Capicúa'),
  random('Aleatorio');

  final String label;

  const SortingType(this.label);
}

class SortingPanel extends StatefulWidget {
  const SortingPanel({super.key});

  @override
  SortingPanelState createState() => SortingPanelState();
}

class SortingPanelState extends State<SortingPanel> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'SortingPanel for match=$match');

    // Calculate the total estimated text width.
    double totalTextWidth =
        SortingType.values.map((type) => type.label.length * 10.0).reduce((value, element) => value + element);

    // Calculate the horizontal padding.
    double widthPadding = (MediaQuery.of(context).size.width - totalTextWidth) / 8.0;

    MyLog.log(
        _classString,
        'SortingPanel totalWidth=${MediaQuery.of(context).size.width}, '
        'totalTextWidth=$totalTextWidth, widthPadding=$widthPadding',
        indent: true);

    // Ensure padding is not negative.
    if (widthPadding < 0) {
      widthPadding = 0;
    }

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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black87, // Border color
                width: 0.5, // Border width
              ),
              borderRadius: BorderRadius.circular(6.0), // Rounded corners
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ToggleButtons(
                    renderBorder: false,
                    fillColor: Theme.of(context).colorScheme.surfaceBright,
                    isSelected: List.generate(
                      // create a list of booleans. True for the selected toggle index
                      SortingType.values.length,
                      (index) => index == _selectedIndex,
                    ),
                    onPressed: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: SortingType.values
                        .map((type) => Padding(
                              padding: EdgeInsets.symmetric(horizontal: widthPadding),
                              child: Text(type.label),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const <Widget>[
              // better be const, so it is not rebuilt every time the index changes
              SortingSubPanel(sortingType: SortingType.ranking),
              SortingSubPanel(sortingType: SortingType.palindromic),
              SortingSubPanel(sortingType: SortingType.random),
            ],
          ),
        ),
      ],
    );
  }
}

class SortingSubPanel extends StatelessWidget {
  const SortingSubPanel({super.key, required SortingType sortingType}) : _sortingType = sortingType;
  final SortingType _sortingType;

  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'SortingSubPanel sortingType=${_sortingType.name}, match=$match');

    Map<int, List<int>> courtPlayers;
    switch (_sortingType) {
      case SortingType.ranking:
        courtPlayers = match.getRankingPlayerPairs();
        break;
      case SortingType.palindromic:
        courtPlayers = match.getPalindromicPlayerPairs();
        break;
      case SortingType.random:
        courtPlayers = match.getRandomPlayerPairs();
        break;
    }

    return _listViewOfMatches(context, courtPlayers);
  }

  Widget _listViewOfMatches(BuildContext context, Map<int, List<int>> sortedPlayers) {
    MyMatch match = context.read<MatchNotifier>().match;
    int filledCourts = match.getNumberOfFilledCourts();
    List<MyUser> matchPlayers = match.playersReference;
    MyLog.log(_classString, 'listOfMatches courts = $filledCourts', indent: true);
    MyLog.log(_classString, 'listOfMatches matchPlayers = $matchPlayers, courtPlayers = $sortedPlayers', indent: true);

    List<MyUser> rankingSortedUsers = context.read<AppState>().getSortedUsers(sortBy: UsersSortBy.ranking);

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
                    match.courtNamesReference.elementAt(court),
                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                  )),
              title: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${_getPlayerText(court, 0, matchPlayers, sortedPlayers, rankingSortedUsers)} y '
                  '${_getPlayerText(court, 1, matchPlayers, sortedPlayers, rankingSortedUsers)}\n\n'
                  '${_getPlayerText(court, 2, matchPlayers, sortedPlayers, rankingSortedUsers)} y '
                  '${_getPlayerText(court, 3, matchPlayers, sortedPlayers, rankingSortedUsers)}',
                ),
              ),
            ),
          ),
      ]);
    }
  }

  String _getPlayerText(int court, int index, List<MyUser> matchPlayers, Map<int, List<int>> sortedPlayers,
      List<MyUser> rankingSortedUsers) {
    // return '${sortedPlayers[court]![index] + 1} - ${matchPlayers[sortedPlayers[court]![index]].name} '
    //     '<${rankingSortedUsers.indexOf(matchPlayers[sortedPlayers[court]![index]]) + 1}>';
    return '${matchPlayers[sortedPlayers[court]![index]].name} '
        '<${rankingSortedUsers.indexOf(matchPlayers[sortedPlayers[court]![index]]) + 1}>';
  }
}
