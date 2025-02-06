import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel_dev/database/firebase.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../routes/routes.dart';
import '../../utilities/theme.dart';
import '../../utilities/date.dart';

final String _classString = 'HomePage'.toUpperCase();

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Consumer<AppState>(
      builder: (context, appState, _) {
        Date fromDate = Date.now();
        Date maxDate = appState.maxDateOfMatchesToView;

        FirebaseHelper firebaseHelper = context.read<Director>().firebaseHelper;
        return StreamBuilder<List<MyMatch>>(
          // StreamBuilder for List<MyMatch>
          stream: firebaseHelper.getMatchesStream(fromDate: fromDate, maxDate: maxDate), // Use your stream function
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // snapshot.data is now a List<MyMatch> (or null if there's an error)
            final List<MyMatch> matches = snapshot.data ?? []; // Handle the null case

            final List<MyMatch> playableMatches = matches.where((match) => appState.isDayPlayable(match.date)).toList();

            return ListView(
              children: [
                ...ListTile.divideTiles(
                  context: context,
                  tiles: playableMatches.map((match) {
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
                        leading:
                            CircleAvatar(backgroundColor: getMatchColor(match), child: Text(match.isOpen ? 'A' : 'C')),
                        title: match.isOpen
                            ? Text('${match.date.toString()}\n$playingStateStr$comment')
                            : Text('${match.date.toString()}\nCONVOCATORIA NO DISPONIBLE'),
                        subtitle: match.isOpen
                            ? Text(
                                'APUNTADOS: ${match.players.length} de ${match.getNumberOfCourts() * 4}',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              )
                            : null,
                        enabled: match.isOpen == true || appState.isLoggedUserAdmin,
                        onTap: () {
                          context.pushNamed(AppRoutes.match, extra: match);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        );
      },
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
      return Theme.of(context).listTileTheme.tileColor ?? Theme.of(context).colorScheme.surface;
  }
}
