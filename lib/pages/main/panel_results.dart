import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/result_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../routes/routes.dart';
import '../../utilities/date.dart';

final String _classString = 'ResultsPanel'.toUpperCase();

class ResultsPanel extends StatelessWidget {
  const ResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    try {
      return Consumer<AppState>(
        builder: (context, appState, _) {
          FbHelpers fbHelpers = context.read<Director>().fbHelpers;

          Date maxDate = Date.now();
          MyLog.log(_classString, 'StreamBuilder  to:$maxDate', indent: true);

          return StreamBuilder<List<MyMatch>>(
            stream: fbHelpers.getMatchesStream(
                appState: appState, maxDate: maxDate, onlyOpenMatches: true, descending: true),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final matches = snapshot.data!;
                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _buildMatchItem(match, context);
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error al obtener los partidos: \nError: ${snapshot.error}'));
              } else {
                return CircularProgressIndicator(); // Loading indicator
              }
            },
          );
        },
      );
    } catch (e) {
      MyLog.log(_classString, 'Error building results panel: $e', level: Level.SEVERE, indent: true);
      return Text('Error construyendo el panel de resultados \n$e');
    }
  }

  Widget _buildMatchItem(MyMatch match, BuildContext context) {
    AppState appState = context.read<AppState>();

    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, match.id.longFormat(), () => _addNewResult(context, match)),
          StreamBuilder<List<GameResult>>(
            stream: FbHelpers().getResultsStream(appState: appState, matchId: match.id.toYyyyMMdd()),
            builder: (context, snapshot) {
              try {
                if (snapshot.hasData) {
                  final results = snapshot.data!;
                  return Column(
                    children: results.map((result) => _buildResultCard(result, context)).toList(),
                  );
                } else if (snapshot.hasError) {
                  MyLog.log(_classString, 'Error loading results: ${snapshot.error}',
                      level: Level.SEVERE, indent: true);
                  throw snapshot.error!;
                } else {
                  return CircularProgressIndicator(); // Loading indicator
                }
              } catch (e) {
                MyLog.log(_classString, 'Error building result card: $e', level: Level.SEVERE, indent: true);
                return Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text('Error al obtener los resultados del partido\n\n$e', style: TextStyle(color: Colors.red)),
                );
              }
            },
          ),
          const Divider(),
        ],
      );
    } catch (e) {
      MyLog.log(_classString, 'Error building match item: $e', level: Level.SEVERE, indent: true);
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child: Text('Error al obtener los resultados del partido\n\n$e', style: TextStyle(color: Colors.red)),
      );
    }
  }

  Widget _buildHeader(BuildContext context, String headerText, VoidCallback onSetResult) => Card(
        elevation: 6,
        margin: const EdgeInsets.all(10),
        child: ListTile(
          tileColor: Theme.of(context).appBarTheme.backgroundColor,
          titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
          title: Text(headerText),
          leading: GestureDetector(
            onTap: onSetResult,
            child: Tooltip(
              message: 'Agregar nuevo resultado',
              child: CircleAvatar(
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

  // Function to handle adding a new result
  void _addNewResult(BuildContext context, MyMatch match) {
    context.pushNamed(AppRoutes.setResult, extra: match.id.toYyyyMMdd() );
  }

  Widget _buildResultCard(GameResult result, BuildContext context) {
    MyLog.log(_classString, 'Building result card: $result', indent: true);
    try {
      return Card(
        margin: const EdgeInsets.fromLTRB(30.0, 2.0, 8.0, 2.0),
        color: Theme.of(context).colorScheme.inversePrimary,
        child: SizedBox(
          width: double.infinity, // Take up the full width of the Column
          child: Padding(
            padding: EdgeInsets.all(2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8.0,
              children: [
                _buildTeam(result.teamA!),
                _buildScore(result.teamA!.score, result.teamB!.score),
                SizedBox(width: 10),
                _buildTeam(result.teamB!),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      MyLog.log(_classString, 'Error building result card: $e', level: Level.SEVERE, indent: true);
      throw Exception('Error obteniendo datos del resultado: \n'
          '$result \n'
          'Error: $e');
    }
  }

  Widget _buildTeam(TeamResult team) {
    MyLog.log(_classString, 'Building team: $team', indent: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4.0,
      children: [
        _buildPlayer(team.player1),
        _buildPlayer(team.player2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 50),
            _buildPoints(team.points),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayer(MyUser player) {
    MyLog.log(_classString, 'Building player: $player', indent: true);
    return IntrinsicWidth(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
        ),
        title: Text(player.name),
      ),
    );
  }

  Widget _buildPoints(int points) {
    MyLog.log(_classString, 'Building points: $points', indent: true);
    return Text(points.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
  }

  Widget _buildScore(int scoreA, int scoreB) {
    MyLog.log(_classString, 'Building score: $scoreA - $scoreB', indent: true);
    return Text('$scoreA - $scoreB', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
  }
}
