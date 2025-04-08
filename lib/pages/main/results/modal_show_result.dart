import 'package:flutter/material.dart';
import 'package:no_solo_padel/models/md_user.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../database/db_firebase_helpers.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_result.dart';
import '../../../utilities/ui_helpers.dart';

final String _classString = 'ShowResultModal'.toUpperCase();

class ShowResultModal extends StatelessWidget {
  const ShowResultModal({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  _buildTeam(result.teamA),
                ],
              ),
              const Column(
                children: [
                  Text('Result'),
                ],
              ),
              const Column(
                children: [
                  Text('Team B'),
                ],
              ),
            ],
          ),
          const Text('Buttons'),
        ],
      ),
    );
  }

  Widget _buildPoints(int points) {
    MyLog.log(_classString, 'Building points: $points', indent: true);
    return Text(points.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
  }

  Future<void> _eraseResult(GameResult result, BuildContext context) async {
    MyLog.log(_classString, '_eraseResult: $result');

    // confirm erasing
    const String kYesOption = 'SI';
    const String kNoOption = 'NO';
    String response = await UiHelper.myReturnValueDialog(
        context, '¿Seguro que quieres eliminar el resultado?', kYesOption, kNoOption);
    if (response.isEmpty || response == kNoOption) return;
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

  Widget _buildTeam(TeamResult team) {
    MyLog.log(_classString, 'Building team: $team', level: Level.INFO, indent: true);
    return Column( children: [
      _buildPlayer(team.player1),
      _buildPlayer(team.player2),
      _buildPoints(team.points),
    ], );
  }

  Widget _buildPlayer(MyUser player1) {
    MyLog.log(_classString, 'Building player: $player1', level: Level.INFO, indent: true);

  }
}
