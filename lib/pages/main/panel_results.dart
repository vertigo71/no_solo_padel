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
import '../../utilities/ui_helpers.dart';

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
                MyLog.log(_classString, 'Build: Error loading matches: ${snapshot.error}');
                return Center(child: Text('Error al obtener los partidos: \nError: ${snapshot.error}'));
              } else {
                return CircularProgressIndicator(); // Loading indicator
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, match.id.longFormat(),
              () => context.pushNamed(AppRoutes.addResult, extra: match.id.toYyyyMMdd())),
          StreamBuilder<List<GameResult>>(
            stream: FbHelpers().getResultsStream(appState: appState, matchId: match.id.toYyyyMMdd()),
            builder: (context, snapshot) {
              try {
                if (snapshot.hasData) {
                  final results = snapshot.data!;
                  MyLog.log(_classString, '_buildMatchItem Results: $results', indent: true);
                  return Column(
                    children: results.map((result) => _buildResultCard(result, context)).toList(),
                  );
                } else if (snapshot.hasError) {
                  MyLog.log(_classString, 'Error loading results: ${snapshot.error}',
                      level: Level.SEVERE, indent: true);
                  throw snapshot.error!;
                } else {
                  return CircularProgressIndicator();
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
          const Divider(),
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
        margin: const EdgeInsets.all(10),
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
      return Card(
        margin: const EdgeInsets.fromLTRB(30.0, 2.0, 8.0, 2.0),
        color: Theme.of(context).colorScheme.inversePrimary,
        elevation: 6.0,
        child: SizedBox(
          width: double.infinity, // Take up the full width of the Column
          child: Padding(
            padding: EdgeInsets.all(2.0),
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8.0,
              children: [
                Spacer(),
                _buildTeam(result.teamA!),
                _buildScore(result.teamA!.score, result.teamB!.score),
                SizedBox(width: 10),
                _buildTeam(result.teamB!),
                Spacer(),
                InkWell(
                  onTap: () async {
                    MyLog.log(_classString, '_buildResultCard. Result = $result');
                    try {
                      await _eraseResult(result, context);
                    } catch (e) {
                      if (context.mounted) {
                        UiHelper.showMessage(context, 'Error al eliminar el resultado\nError: ${e.toString()}');
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 25.0, // Optional: Adjust the icon size
                    ),
                  ),
                ),
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

  Widget _buildTeam(TeamResult team) {
    MyLog.log(_classString, 'Building team: $team', indent: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4.0,
      children: [
        _buildPlayer(team.player1, team.preRanking1),
        _buildPlayer(team.player2, team.preRanking2),
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

  Widget _buildPlayer(MyUser player, int preRanking) {
    MyLog.log(_classString, 'Building player: $player', indent: true);
    return IntrinsicWidth(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
        ),
        title: Text(player.name),
        subtitle: Text('$preRanking'),
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

  Future<void> _eraseResult(GameResult result, BuildContext context) async {
    MyLog.log(_classString, '_eraseResult: $result');

    // confirm erasing
    const String yesOption = 'SI';
    const String noOption = 'NO';
    String response =
        await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres eliminar el resultado?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return;
    MyLog.log(_classString, 'build response = $response', indent: true);

    // erase the gameResult
    try {
      await FbHelpers().deleteResult(result);
    } catch (e) {
      MyLog.log(_classString, 'Error erasing result: ${e.toString()}', level: Level.SEVERE, indent: true);
      throw Exception('Error al eliminar el resultado: $result \nError: ${e.toString()}');
    }

    // update users ranking points
    try {
      MyLog.log(_classString, 'Updating users ranking points', indent: true);
      if (result.teamA!.points != 0) {
        result.teamA!.player1.rankingPos -= result.teamA!.points;
        result.teamA!.player2.rankingPos -= result.teamA!.points;
        await Future.wait([
          FbHelpers().updateUser(result.teamA!.player1),
          FbHelpers().updateUser(result.teamA!.player2),
        ]);
      }
      if (result.teamB!.points != 0) {
        result.teamB!.player1.rankingPos -= result.teamB!.points;
        result.teamB!.player2.rankingPos -= result.teamB!.points;
        await Future.wait([
          FbHelpers().updateUser(result.teamB!.player1),
          FbHelpers().updateUser(result.teamB!.player2),
        ]);
      }
    } catch (e) {
      MyLog.log(_classString, 'Error updating users ranking points: ${e.toString()}',
          level: Level.SEVERE, indent: true);
      throw Exception('Error al actualizar los puntos de los jugadores \nError: ${e.toString()}');
    }
  }
}
