import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: 8.0,
          children: [
            if (result.teamA != null) Expanded(child: _buildTeam(context, result.teamA!)),
            _buildResult(result),
            if (result.teamB != null) Expanded(child: _buildTeam(context, result.teamB!)),
          ],
        ),
        const Divider( height: 80,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: 8.0,
          children: [
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  bool erased = await _eraseResult(result, context);
                  if (context.mounted && erased) context.pop();
                } on Exception catch (e) {
                  if (context.mounted) UiHelper.showMessage(context, e.toString());
                }
              },
              child: const Text('Eliminar resultado'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPoints(int points) {
    MyLog.log(_classString, 'Building points: $points', indent: true);
    return Text(points.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold));
  }

  Widget _buildTeam(BuildContext context, TeamResult team) {
    MyLog.log(_classString, 'Building team: $team', level: Level.INFO, indent: true);
    return Column(
      spacing: 8.0,
      children: [
        ..._buildPlayer(context, team.player1),
        const SizedBox(height: 20),
        ..._buildPlayer(context, team.player2),
        const SizedBox(height: 20),
        _buildPoints(team.points),
      ],
    );
  }

  List<Widget> _buildPlayer(BuildContext context, MyUser player) {
    MyLog.log(_classString, 'Building player: $player', level: Level.INFO, indent: true);
    return [
      CircleAvatar(
        backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        radius: 35,
      ),
      Text(player.name),
      Text(player.rankingPos.toString()),
    ];
  }

  Widget _buildResult(GameResult result) {
    MyLog.log(_classString, 'Building result: $result', indent: true);
    if (result.teamA != null && result.teamB != null) {
      return Text('${result.teamA!.score} - ${result.teamB!.score}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
    } else {
      return Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
    }
  }

  Future<bool> _eraseResult(GameResult result, BuildContext context) async {
    MyLog.log(_classString, '_eraseResult: $result');

    // confirm erasing
    const String kYesOption = 'SI';
    const String kNoOption = 'NO';
    String response = await UiHelper.myReturnValueDialog(
        context, '¿Seguro que quieres eliminar el resultado?', kYesOption, kNoOption);
    if (response.isEmpty || response == kNoOption) return false;
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

    return true; // success
  }
}
