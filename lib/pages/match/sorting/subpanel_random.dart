import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../interface/match_notifier.dart';
import '../../../models/debug.dart';
import '../../../models/match_model.dart';
import '../../../models/user_model.dart';

final String _classString = 'RandomPanel'.toUpperCase();

class RandomPanel extends StatelessWidget {
  const RandomPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Form for match=$match');

    return Builder(
      builder: (context) {
        int filledCourts = match.getNumberOfFilledCourts();
        Map<int, List<int>> courtPlayers = match.getRandomPlayerPairs();
        List<MyUser> players = match.players;
        MyLog.log(_classString, 'build players = $players', indent: true);
        MyLog.log(_classString, 'build courts = $filledCourts', indent: true);

        return ListView(children: [
          for (int court = 0; court < filledCourts; court++)
            Card(
              elevation: 6,
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                    child: Text(
                      match.courtNames.elementAt(court),
                      style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                    )),
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '(${courtPlayers[court]![0] + 1}) ${players[courtPlayers[court]![0]].name} y '
                    '(${courtPlayers[court]![1] + 1}) ${players[courtPlayers[court]![1]].name}\n\n'
                    '(${courtPlayers[court]![2] + 1}) ${players[courtPlayers[court]![2]].name} y '
                    '(${courtPlayers[court]![3] + 1}) ${players[courtPlayers[court]![3]].name}',
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
