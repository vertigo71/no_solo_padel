import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../routes/routes.dart';
import '../../utilities/theme.dart';

final String _classString = 'HomePage'.toUpperCase();

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Consumer<AppState>(
      builder: (context, appState, _) => ListView(
        children: [
          ...ListTile.divideTiles(
            context: context,
              tiles: appState.getSortedMatchesIfDayPlayable().map(((match) {
                String playingStateStr = match.getPlayingStateString(appState.getLoggedUser().userId);
                PlayingState playingState = match.getPlayingState(appState.getLoggedUser().userId);
                final String comment = match.comment.isEmpty ? '' : '\n${match.comment}';

                return Card(
                  elevation: 6,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    tileColor: match.isOpen
                        ? getPlayingStateColor(context, playingState)
                        : lighten(getMatchColor(match), 0.2),
                    leading: CircleAvatar(
                        child: Text(match.isOpen ? 'A' : 'C'),
                        backgroundColor: getMatchColor(match)),
                    title: Text('${match.date.toString()}\n$playingStateStr$comment'),
                    subtitle: match.isOpen
                        ? Text(
                            'APUNTADOS: ${match.players.length} de ${match.getNumberOfCourts() * 4}',
                            style:
                                const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          )
                        : null,
                    enabled: match.isOpen == true || appState.isLoggedUserAdmin,
                    onTap: () {
                      Navigator.pushNamed(context, RouteManager.matchPage, arguments: match.date);
                    },
                  ),
                );
              })).toList()),
        ],
      ),
    );
  }
}

Color getMatchColor(MyMatch match) {
  switch (match.isOpen) {
    case true:
      return Colors.green;
    default:
      return Colors.red;
  }
}

Color getPlayingStateColor(BuildContext context, PlayingState playingState) {
  switch (playingState) {
    case PlayingState.unsigned:
      return darken(Theme.of(context).canvasColor, .2);
    case PlayingState.playing:
    case PlayingState.signedNotPlaying:
    case PlayingState.reserve:
    default:
      return Theme.of(context).listTileTheme.tileColor?? Theme.of(context).backgroundColor;
  }
}
