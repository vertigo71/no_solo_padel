import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../database/db_firebase_helpers.dart';
import '../../interface/if_app_state.dart';
import '../../models/md_debug.dart';
import '../../models/md_exception.dart';
import '../../models/md_match.dart';
import '../../models/md_parameter.dart';
import '../../models/md_user.dart';
import '../../routes/routes.dart';
import '../../models/md_date.dart';
import '../../utilities/ui_helpers.dart';

final String _classString = 'MatchesPanel'.toUpperCase();

class MatchesPanel extends StatelessWidget {
  const MatchesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Consumer<AppState>(
      builder: (context, appState, _) {
        Date fromDate = Date.now();
        Date maxDate = appState.maxDateOfMatchesToView;
        int numMatches = appState.getIntParamValue(ParametersEnum.matchDaysToView) ?? -1;
        MyLog.log(_classString, 'StreamBuilder from:$fromDate to:$maxDate', indent: true);

        return StreamBuilder<List<MyMatch>>(
          // StreamBuilder for List<MyMatch>
          stream:
              FbHelpers().getMatchesStream(appState: appState, fromDate: fromDate, toDate: maxDate, descending: false),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error al obtener los partidos: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // snapshot.data is now a List<MyMatch> (or null if there's an error)
            final List<MyMatch> fetchedMatches = snapshot.data ?? []; // Handle the null case

            MyLog.log(_classString, 'fetchedMatches = ${fetchedMatches.length}/$numMatches', indent: true);

            // build playableMatches list
            List<MyMatch> playableMatches = [];

            // Create missing matches or get the ones in fetchedMatches if they exist
            for (Date date = fromDate; date.isBefore(maxDate); date = date.add(const Duration(days: 1))) {
              if (appState.isDayPlayable(date)) {
                MyMatch? foundMatch = fetchedMatches.firstWhereOrNull((match) => match.id == date);
                if (foundMatch != null) {
                  playableMatches.add(foundMatch);
                } else {
                  // Create a new MyMatch in memory
                  MyLog.log(_classString, 'create missing match = $date', indent: true);
                  playableMatches.add(MyMatch(
                    id: date,
                    comment: appState.getParamValue(ParametersEnum.defaultCommentText),
                  ));
                }
              }
            }

            return ListView(
              children: ListTile.divideTiles(
                context: context,
                tiles: playableMatches.map((match) {
                  final MyUser? loggedUser = appState.loggedUser;
                  if (loggedUser == null) {
                    MyLog.log(_classString, 'build loggedUser is null', level: Level.SEVERE);
                    throw MyException('No se ha podido obtener el usuario conectado', level: Level.SEVERE);
                  }

                  String playingStateStr = match.getPlayingStateString(loggedUser);
                  PlayingState playingState = match.getPlayingState(loggedUser);
                  final String comment = match.comment.isEmpty ? '' : '\n${match.comment}';

                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      tileColor:
                          // light red: closed, stateColor: open
                          match.isOpen
                              ? UiHelper.getTilePlayingColor(context, playingState)
                              : UiHelper.getMatchTileColor(match),
                      leading: CircleAvatar(
                          backgroundColor: UiHelper.getMatchAvatarColor(match), child: Text(match.isOpen ? 'A' : 'C')),
                      title: match.isOpen
                          ? Text('${match.id.toString()}\n$playingStateStr$comment')
                          : Text('${match.id.toString()}\nCONVOCATORIA NO DISPONIBLE'),
                      subtitle: match.isOpen
                          ? Text(
                              'APUNTADOS: ${match.players.length} de ${match.numberOfCourts * 4}',
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            )
                          : null,
                      enabled: match.isOpen == true || appState.isLoggedUserAdminOrSuper,
                      onTap: () {
                        context.pushNamed(AppRoutes.kMatch, extra: match.toJson());
                      },
                    ),
                  );
                }),
              ).toList(),
            );
          },
        );
      },
    );
  }
}
