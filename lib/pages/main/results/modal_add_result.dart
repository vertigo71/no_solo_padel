import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../interface/if_app_state.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_match.dart';
import '../../../models/md_parameter.dart';
import '../../../models/md_result.dart';
import '../../../utilities/ut_misc.dart';
import '../../../database/db_firebase_helpers.dart';
import '../../../models/md_user.dart';
import '../../../utilities/ui_helpers.dart';

final String _classString = 'AddResultModal'.toUpperCase();
const int kNumPlayers = 4;
const int kMaxGamesPerSet = 16;

class AddResultModal extends StatefulWidget {
  const AddResultModal({super.key, required this.match});

  // argument matchJson vs matchId
  // matchJson: initialValue for FormBuilder will hold the correct initial values
  //   If another user changes any field, the form will not update
  //   A new matchJson will be received. But Form fields won't be updated.
  //   Good for configuration panel
  // matchId: _formKey.currentState?.fields[commentId]?.didChange(match.comment); should be implemented
  //   If any user changes any field, the form will update. Or if any rebuild is made, changes would be lost.
  final MyMatch match;

  @override
  State<AddResultModal> createState() => _AddResultModalState();
}

class _AddResultModalState extends State<AddResultModal> {
  late MyMatch _match;
  late AppState _appState;
  final List<MyUser?> _selectedPlayers = List.filled(kNumPlayers, null);
  final List<int> _scores = [0, 0];

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _appState = context.read<AppState>();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8.0,
        children: [
          // add Team A
          _buildPlayer(0),
          _buildPlayer(1),
          // add score
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [_buildResults()],
            ),
          ),
          // add Team B
          _buildPlayer(2),
          _buildPlayer(3),
          Divider(
            height: 8.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _save();
                    MyLog.log(_classString, 'Result saved', indent: true);
                    if (context.mounted) context.pop();
                  } catch (e) {
                    MyLog.log(_classString, 'Error saving result: ${e.toString()}', indent: true);
                    if (context.mounted) {
                      UiHelper.myAlertDialog(context, 'No se ha podido añadir el resultado\n${e.toString()}');
                    }
                  }
                },
                child: Text('Guardar'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                child: Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer(int numValue) {
    MyLog.log(_classString, '_buildPlayer numValue=$numValue', indent: true, level: Level.FINE);
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceBright,
      child: DropdownMenu<MyUser>(
        width: double.infinity,
        initialSelection: _selectedPlayers[numValue],
        onSelected: (MyUser? value) {
          setState(() {
            _selectedPlayers[numValue] = value;
          });
        },
        dropdownMenuEntries: () {
          final List<MyUser> players = _match.getPlayers(state: PlayingState.playing);
          players.sort(getMyUserComparator(UsersSortBy.name));
          return players.map<DropdownMenuEntry<MyUser>>((MyUser user) {
            return DropdownMenuEntry<MyUser>(
              value: user,
              label: user.name,
              leadingIcon: CircleAvatar(
                backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white)) : null,
              ),
            );
          }).toList();
        }(),
        leadingIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surfaceBright,
            backgroundImage: _selectedPlayers[numValue]?.avatarUrl != null
                ? NetworkImage(_selectedPlayers[numValue]!.avatarUrl!)
                : null,
            child: _selectedPlayers[numValue] != null && _selectedPlayers[numValue]!.avatarUrl == null
                ? Text('?', style: TextStyle(fontSize: 24, color: Colors.white))
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    MyLog.log(_classString, '_buildResult', level: Level.FINE, indent: true);
    return Column(
      spacing: 8.0,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildOneResult(0),
        Text('Resultado', style: TextStyle(fontWeight: FontWeight.bold)),
        _buildOneResult(1),
      ],
    );
  }

  Widget _buildOneResult(int team) {
    MyLog.log(_classString, '_buildOneResult team=$team', indent: true, level: Level.FINE);
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(0.0),
      color: Theme.of(context).colorScheme.surfaceBright,
      child: DropdownMenu<int>(
        width: 90,
        initialSelection: _scores[team],
        onSelected: (int? value) {
          if (value != null) {
            setState(() {
              _scores[team] = value;
            });
          }
        },
        dropdownMenuEntries: List.generate(kMaxGamesPerSet, (result) {
          return DropdownMenuEntry<int>(
            value: result,
            label: result.toString(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _save() async {
    MyLog.log(_classString, '_save', indent: true);

    bool isAnyPlayerNull = _selectedPlayers.contains(null);
    bool areAllResultsZero = _scores.every((result) => result == 0);

    if (isAnyPlayerNull) {
      MyLog.log(_classString, 'Null player. players=$_selectedPlayers', indent: true);
      throw 'Añadir todos los jugadores';
    }

    if (areAllResultsZero) {
      MyLog.log(_classString, 'All results 0. results=$_scores', indent: true);
      throw 'El resultado no puede ser 0-0';
    }

    // check if there are repeated players
    Set<MyUser> uniquePlayers = Set.from(_selectedPlayers);
    if (uniquePlayers.length != kNumPlayers) {
      MyLog.log(_classString, 'Repeated players. players=$_selectedPlayers', indent: true);
      throw 'No se puede repetir un jugador';
    }

    // calculate the points that each team will get
    List<int> points = _calculatePoints();

    // create teamA
    TeamResult teamA = TeamResult(
      player1: _selectedPlayers[0]!,
      player2: _selectedPlayers[1]!,
      points: points[0],
      score: _scores[0],
      preRanking1: _selectedPlayers[0]!.rankingPos,
      preRanking2: _selectedPlayers[1]!.rankingPos,
    );

    // create teamB
    TeamResult teamB = TeamResult(
      player1: _selectedPlayers[2]!,
      player2: _selectedPlayers[3]!,
      points: points[1],
      score: _scores[1],
      preRanking1: _selectedPlayers[2]!.rankingPos,
      preRanking2: _selectedPlayers[3]!.rankingPos,
    );

    // logged user
    final MyUser? loggedUser = _appState.loggedUser;

    if (loggedUser == null) {
      MyLog.log(_classString, '_save loggedUser is null', level: Level.SEVERE);
      throw Exception('No se ha podido obtener el usuario conectado');
    }

    // create GameResult
    GameResult gameResult = GameResult(
      id: GameResultId(userId: loggedUser.id),
      matchId: _match.id,
      teamA: teamA,
      teamB: teamB,
    );

    // save result to Firestore
    try {
      MyLog.log(_classString, 'Saving result: $gameResult', indent: true);
      await FbHelpers().updateResult(result: gameResult, matchId: _match.id.toYyyyMMdd());
    } catch (e) {
      MyLog.log(_classString, 'Error saving result: ${e.toString()}', level: Level.WARNING, indent: true);
      throw 'Error al guardar el resultado.\n ${e.toString()}';
    }

    // add points to players
    try {
      MyLog.log(_classString, 'Updating players points', indent: true);
      _selectedPlayers.sublist(0, 2).forEach((player) => player!.rankingPos += teamA.points);
      _selectedPlayers.sublist(2, 4).forEach((player) => player!.rankingPos += teamB.points);
      await Future.wait(_selectedPlayers.map((e) async => await FbHelpers().updateUser(e!)));
    } catch (e) {
      MyLog.log(_classString, 'Updating players points: ${e.toString()}', level: Level.WARNING, indent: true);
      throw ('Error al actualizar los puntos de los jugadores. \n${e.toString()}');
    }

    // log to Sentry
    MyLog.log(_classString, 'SENTRY result created', myCustomObject: gameResult, captureSentryMessage: true);
  }

  /// list of 2 ints with the points of each team A and B
  List<int> _calculatePoints() {
    MyLog.log(_classString, '_calculatePointsA', indent: true);

    if (_selectedPlayers.length != 4) {
      throw ArgumentError('No se ha podido obtener los cuatro jugadores');
    }
    if (_scores.length != 2) {
      throw ArgumentError('No se ha podido obtener los dos resultados');
    }

    int? step = _appState.getIntParamValue(ParametersEnum.step);
    int? range = _appState.getIntParamValue(ParametersEnum.range);
    int? rankingDiffToHalf = _appState.getIntParamValue(ParametersEnum.rankingDiffToHalf);
    int? freePoints = _appState.getIntParamValue(ParametersEnum.freePoints);

    if (step == null || range == null || rankingDiffToHalf == null || freePoints == null) {
      throw ArgumentError('No se han podido obtener los parámetros para el cálculo de puntos');
    }

    final int rankingA = _selectedPlayers[0]!.rankingPos + _selectedPlayers[1]!.rankingPos;
    final int rankingB = _selectedPlayers[2]!.rankingPos + _selectedPlayers[3]!.rankingPos;

    try {
      return RankingPoints(
        step: step,
        range: range,
        rankingDiffToHalf: rankingDiffToHalf,
        freePoints: freePoints,
        rankingA: rankingA,
        rankingB: rankingB,
        scoreA: _scores[0],
        scoreB: _scores[1],
      ).calculatePoints();
    } catch (e) {
      MyLog.log(_classString, 'Error calculating points: ${e.toString()}', indent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UiHelper.showMessage(context, 'Error al calcular los puntos.\n${e.toString()}');
      });
      return [0, 0];
    }
  }
}
