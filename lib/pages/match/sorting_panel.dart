import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/match_notifier.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';

final String _classString = 'SortingPanel'.toUpperCase();

class SortingPanel extends StatelessWidget {
  const SortingPanel(this.initialMatch, {super.key});

  final MyMatch initialMatch;

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    final matchNotifier = context.watch<MatchNotifier>(); // Watch for changes in the match

    return Builder(
      builder: (context) {
        int filledCourts = matchNotifier.match.getNumberOfFilledCourts();
        List<int> sortedList = matchNotifier.match.getCouplesPlainList(); // how players play
        List<MyUser> players = matchNotifier.match.players;
        MyLog.log(_classString, 'build players = $players', indent: true);
        MyLog.log(_classString, 'build courts = $filledCourts', indent: true);

        return ListView(children: [
          if (matchNotifier.match.comment.isNotEmpty)
            Card(
              elevation: 6,
              margin: const EdgeInsets.all(10),
              child: ListTile(
                tileColor: Theme.of(context).appBarTheme.backgroundColor,
                titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                title: Text(matchNotifier.match.comment),
              ),
            ),
          for (int index = 0; index < filledCourts; index++)
            Card(
              elevation: 6,
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                    child: Text(
                      matchNotifier.match.courtNames.elementAt(index),
                      style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                    )),
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('(${sortedList[4 * index] + 1}) ${players.elementAt(sortedList[4 * index]).name} y '
                      '(${sortedList[4 * index + 1] + 1}) ${players.elementAt(sortedList[4 * index + 1]).name}\n\n'
                      '(${sortedList[4 * index + 2] + 1}) ${players.elementAt(sortedList[4 * index + 2]).name} y '
                      '(${sortedList[4 * index + 3] + 1}) ${players.elementAt(sortedList[4 * index + 3]).name}'),
                ),
              ),
            ),
        ]);
      },
    );
  }
}
