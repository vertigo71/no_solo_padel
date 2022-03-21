import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../interface/app_state.dart';
import '../../utilities/date.dart';
import '../../utilities/misc.dart';

final String _classString = 'SortingPanel'.toUpperCase();

class SortingPanel extends StatelessWidget {
  const SortingPanel(this.date, {Key? key}) : super(key: key);

  final Date date;

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');
    return Consumer<AppState>(
      builder: (context, appState, _) {
        MyMatch? match = appState.getMatch(date);

        if (match == null) {
          return const Text('ERROR! Partido no encontrado sorteando los equipos.');
        } else {
          int filledCourts = match.getNumberOfFilledCourts();
          List<int> sortedList = getRandomList(filledCourts * 4, match.date);
          List<MyUser> players = appState.userIdsToUsers(match.players);
          MyLog().log(_classString, 'players = $players');
          MyLog().log(_classString, 'courts = $filledCourts');

          return ListView(children: [
            if (match.comment.isNotEmpty)
              Card(
                elevation: 6,
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  tileColor: Theme.of(context).appBarTheme.backgroundColor,
                  title: Text(match.comment),
                ),
              ),
            for (int index = 0; index < filledCourts; index++)
              Card(
                elevation: 6,
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: CircleAvatar(
                      child: Text(
                        match.courtNames.elementAt(index),
                        style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                      ),
                      backgroundColor: Theme.of(context).appBarTheme.backgroundColor),
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        '(${sortedList[4 * index] + 1}) ${players.elementAt(sortedList[4 * index]).name} y '
                        '(${sortedList[4 * index + 1] + 1}) ${players.elementAt(sortedList[4 * index + 1]).name}\n\n'
                        '(${sortedList[4 * index + 2] + 1}) ${players.elementAt(sortedList[4 * index + 2]).name} y '
                        '(${sortedList[4 * index + 3] + 1}) ${players.elementAt(sortedList[4 * index + 3]).name}'),
                  ),
                ),
              ),
          ]);
        }
      },
    );
  }
}
