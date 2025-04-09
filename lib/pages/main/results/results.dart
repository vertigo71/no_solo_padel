import 'dart:math';

import 'package:flutter/material.dart';
import 'package:no_solo_padel/pages/main/results/modal_add_result.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../database/db_firebase_helpers.dart';
import '../../../interface/if_app_state.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_result.dart';
import '../../../models/md_match.dart';
import '../../../models/md_user.dart';
import '../../../models/md_date.dart';
import '../../../utilities/ut_theme.dart';
import 'modal_show_result.dart';

final String _classString = 'ResultsPanel'.toUpperCase();

class ResultsPanel extends StatelessWidget {
  const ResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    try {
      return Consumer<AppState>(
        builder: (context, appState, _) {
          Date maxDate = Date.now();
          MyLog.log(_classString, 'StreamBuilder  to:$maxDate', indent: true);

          return StreamBuilder<List<MyMatch>>(
            stream: FbHelpers()
                .getMatchesStream(appState: appState, maxDate: maxDate, onlyOpenMatches: true, descending: true),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final matches = snapshot.data!;
                return ListView.separated(
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildMatchItem(match, context);
                  },
                );
              } else if (snapshot.hasError) {
                MyLog.log(_classString, 'Build: Error loading matches: ${snapshot.error}');
                return Center(child: Text('Error al obtener los partidos: \nError: ${snapshot.error}'));
              } else {
                return const Center(child: CircularProgressIndicator()); // Loading indicator
              }
            },
          );
        },
      );
    } catch (e) {
      MyLog.log(_classString, 'Error building results panel: ${e.toString()}', level: Level.SEVERE, indent: true);
      return Text('Error construyendo el panel de resultados \n${e.toString()}');
    }
  }

  Widget _buildMatchItem(MyMatch match, BuildContext context) {
    AppState appState = context.read<AppState>();

    try {
      return Column(
        children: [
          _buildHeader(context, match.id.longFormat(), () => _addResultModal(context, match)),
          StreamBuilder<List<GameResult>>(
            stream: FbHelpers().getResultsStream(appState: appState, matchId: match.id.toYyyyMMdd()),
            builder: (context, snapshot) {
              try {
                if (snapshot.hasData) {
                  final results = snapshot.data!;
                  MyLog.log(_classString, '_buildMatchItem Results: $results', level: Level.FINE, indent: true);
                  return Column(
                    children: results.map((result) => _buildResultCard(result, context)).toList(),
                  );
                } else if (snapshot.hasError) {
                  MyLog.log(_classString, 'Error loading results: ${snapshot.error}',
                      level: Level.SEVERE, indent: true);
                  throw snapshot.error!;
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              } catch (e) {
                MyLog.log(_classString, 'Error building result card: ${e.toString()}',
                    level: Level.SEVERE, indent: true);
                return Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text('Error al obtener los resultados del partido\n\n${e.toString()}',
                      style: TextStyle(color: Colors.red)),
                );
              }
            },
          ),
        ],
      );
    } catch (e) {
      MyLog.log(_classString, 'Error building match item: ${e.toString()}', level: Level.SEVERE, indent: true);
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child:
            Text('Error al obtener los resultados del partido\n\n${e.toString()}', style: TextStyle(color: Colors.red)),
      );
    }
  }

  Widget _buildHeader(BuildContext context, String headerText, VoidCallback onAddResult) => Card(
        elevation: 6,
        margin: const EdgeInsets.all(1.0),
        child: ListTile(
          tileColor: Theme.of(context).appBarTheme.backgroundColor,
          titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
          title: Text(headerText),
          leading: GestureDetector(
            onTap: onAddResult,
            child: Tooltip(
              message: 'Agregar nuevo resultado',
              child: CircleAvatar(
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

  Widget _buildResultCard(GameResult result, BuildContext context) {
    MyLog.log(_classString, 'Building result card: $result', indent: true);
    try {
      return InkWell(
        onTap: () => _showResultModal(context, result),
        child: Card(
          margin: const EdgeInsets.all(2.0),
          color: Theme.of(context).colorScheme.surfaceDim,
          elevation: 6.0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 18.0),
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPlayer(result.teamA!.player1, result.teamA!.points),
                _buildPlayer(result.teamA!.player2, result.teamA!.points),
                _buildScore(result.teamA!.score, result.teamB!.score),
                _buildPlayer(result.teamB!.player1, result.teamB!.points),
                _buildPlayer(result.teamB!.player2, result.teamB!.points),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      MyLog.log(_classString, 'Error building result card: ${e.toString()}', level: Level.SEVERE, indent: true);
      throw Exception('Error obteniendo datos del resultado: \n'
          '$result \n'
          'Error: ${e.toString()}');
    }
  }

  Widget _buildPlayer(MyUser player, int points) {
    MyLog.log(_classString, 'Building player: $player', indent: true);
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
          child: player.avatarUrl == null ? Text(player.name.substring(0, min(3, player.name.length))) : null,
        ),
        Positioned(
          bottom: -15,
          child: Container(
            color: points >= 0 ? kLightGreen : kLightRed,
            child: Text(points.toString(), style: const TextStyle(color: kLightest, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildScore(int scoreA, int scoreB) {
    MyLog.log(_classString, 'Building score: $scoreA - $scoreB', indent: true);
    return Text('$scoreA - $scoreB', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
  }

  Future _addResultModal(BuildContext context, MyMatch match) {
    return UiHelper.modalPanel(context, match.id.longFormat(), AddResultModal(match: match));
  }

  Future _showResultModal(BuildContext context, GameResult result) {
    return UiHelper.modalPanel(context, result.matchId.longFormat(), ShowResultModal(result: result));
  }
}
