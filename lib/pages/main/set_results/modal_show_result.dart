import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../database/db_firebase_helpers.dart';
import '../../../interface/if_app_state.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_exception.dart';
import '../../../models/md_set_result.dart';
import '../../../utilities/ui_helpers.dart';
import '../../../models/md_user.dart';
import '../../../utilities/ut_theme.dart';

final String _classString = 'ShowResultModal'.toUpperCase();

class ShowResultModal extends StatelessWidget {
  const ShowResultModal({super.key, required this.result});

  final SetResult result;

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building ShowResultModal', level: Level.FINE, indent: true);
    final AppState appState = context.read<AppState>();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: 8.0,
          children: [
            if (result.teamA != null) Expanded(child: _buildTeam(context, result.teamA!)),
            _buildScore(result),
            if (result.teamB != null) Expanded(child: _buildTeam(context, result.teamB!)),
          ],
        ),
        const SizedBox(height: 20),
        _buildBars(context, result),
        const Divider(
          height: 40,
        ),
        Row(
          mainAxisAlignment:
              appState.isLoggedUserAdminOrSuper ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
          spacing: 8.0,
          children: [
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Cerrar'),
            ),
            appState.isLoggedUserAdminOrSuper
                ? ElevatedButton(
                    onPressed: () async {
                      try {
                        bool erased = await _eraseResult(result, context);
                        if (context.mounted && erased) context.pop();
                      } catch (e) {
                        if (context.mounted) UiHelper.myAlertDialog(context, e.toString());
                      }
                    },
                    child: const Text('Eliminar resultado', style: TextStyle(color: Colors.red)),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _buildTeam(BuildContext context, TeamResult team) {
    MyLog.log(_classString, 'Building team: $team', level: Level.FINE, indent: true);
    return Column(
      spacing: 8.0,
      children: [
        ..._buildPlayer(context, team.player1, team.preRanking1),
        const SizedBox(height: 20),
        ..._buildPlayer(context, team.player2, team.preRanking2),
        const SizedBox(height: 20),
        _buildPoints(team.points),
      ],
    );
  }

  List<Widget> _buildPlayer(BuildContext context, MyUser player, int preRanking) {
    MyLog.log(_classString, 'Building player: $player', level: Level.FINE, indent: true);
    return [
      CircleAvatar(
        backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
        backgroundColor: Theme.of(context).colorScheme.surfaceBright,
        radius: 35,
        child: player.avatarUrl == null ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
      ),
      Text(player.name),
      Text(preRanking.toString()),
    ];
  }

  Widget _buildPoints(int points) {
    MyLog.log(_classString, 'Building points: $points', indent: true);
    return Container(
      color: points >= 0 ? kLightGreen : kLightRed,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '$points puntos',
        style: const TextStyle(
          fontSize: 12,
          // color: kLightest,
        ),
      ),
    );
  }

  Widget _buildScore(SetResult result) {
    MyLog.log(_classString, 'Building result: $result', indent: true);
    if (result.teamA != null && result.teamB != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${result.teamA!.score} - ${result.teamB!.score}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          Text('(${result.extraPoints})',
              style: TextStyle(fontSize: 18, fontStyle:  FontStyle.italic )),
        ],
      );
    } else {
      return Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
    }
  }

  Future<bool> _eraseResult(SetResult result, BuildContext context) async {
    MyLog.log(_classString, '_eraseResult: $result');

    // confirm erasing
    const String kYesOption = 'SI';
    const String kNoOption = 'NO';
    String response = await UiHelper.myReturnValueDialog(
        context, '¿Seguro que quieres eliminar el resultado?', kYesOption, kNoOption);
    if (response.isEmpty || response == kNoOption) return false;
    MyLog.log(_classString, 'build response = $response', indent: true);

    // erase the setResult
    try {
      await FbHelpers().deleteSetResult(result);
    } catch (e) {
      MyLog.log(_classString, 'Error erasing result: ${e.toString()}', level: Level.SEVERE, indent: true);
      throw MyException('Error al eliminar el resultado: $result', e: e, level: Level.SEVERE);
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
      throw MyException('Error al actualizar los puntos de los jugadores', e: e, level: Level.SEVERE);
    }

    return true; // success
  }

  Widget _buildBars(BuildContext context, SetResult result) {
    MyLog.log(_classString, 'Building bars', level: Level.FINE, indent: true);
    int rankingTeamA = result.teamA?.preRanking ?? 0;
    int rankingTeamB = result.teamB?.preRanking ?? 0;
    int scoreA = result.teamA?.score ?? 0;
    int scoreB = result.teamB?.score ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0,
      children: [
        const Text('Predicción'),
        _buildBar(context, rankingTeamA, rankingTeamB),
        const Text('Resultado'),
        _buildBar(context, scoreA, scoreB),
        SizedBox.shrink(),
      ],
    );
  }

  Widget _buildBar(BuildContext context, int valueA, int valueB) {
    if (valueA == 0 && valueB == 0) {
      return LinearProgressIndicator(value: 0);
    }
    double percentage = valueA / (valueA + valueB) * 100;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        LinearProgressIndicator(
          value: percentage / 100,
          valueColor:
              AlwaysStoppedAnimation<Color>(valueA >= valueB ? Theme.of(context).colorScheme.primary : kLightest),
          backgroundColor: valueA < valueB ? Theme.of(context).colorScheme.primary : kLightest,
          minHeight: 20,
        ),
        Positioned(
          left: 8.0,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(color: valueA >= valueB ? kWhite : kBlack),
          ),
        ),
        Positioned(
          right: 8.0,
          child: Text(
            '${(100 - percentage).toStringAsFixed(0)}%',
            style: TextStyle(color: valueA < valueB ? kWhite : kBlack),
          ),
        ),
      ],
    );
  }
}
