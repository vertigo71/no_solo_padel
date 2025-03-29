import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel/database/firebase_helpers.dart';
import 'package:no_solo_padel/models/user_model.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../models/result_model.dart';

final String _classString = 'AddResultPage'.toUpperCase();
const int numPlayers = 4;
const int maxGamesPerSet = 16;

class AddResultPage extends StatefulWidget {
  const AddResultPage({super.key, required this.matchJson});

  // argument matchJson vs matchId
  // matchJson: initialValue for FormBuilder will hold the correct initial values
  //   If another user changes any field, the form will not update
  //   A new matchJson will be received. But Form fields won't be updated.
  //   Good for configuration panel
  // matchId: _formKey.currentState?.fields[commentId]?.didChange(match.comment); should be implemented
  //   If any user changes any field, the form will update. Or if any rebuild is made, changes would be lost.
  final Map<String, dynamic> matchJson;

  @override
  State<AddResultPage> createState() => _AddResultPageState();
}

class _AddResultPageState extends State<AddResultPage> {
  late final MyMatch _match;
  bool _initStateError = false;
  List<MyUser?> selectedPlayer = List.filled(numPlayers, null);
  List<int> results = [0, 0];

  @override
  void initState() {
    super.initState();
    try {
      _match = MyMatch.fromJson(widget.matchJson, context.read<AppState>());
      MyLog.log(_classString, 'match = $_match', indent: true);
    } catch (e) {
      _initStateError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    if (_initStateError) return Center(child: Text('No se ha podido acceder al partido'));

    return Scaffold(
      appBar: AppBar(
        title: Text(_match.id.longFormat()),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8.0,
          children: [
            // add Team A
            _selectPlayer(0),
            _selectPlayer(1),
            // add score
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [_selectSetResult()],
              ),
            ),
            // add Team B
            _selectPlayer(2),
            _selectPlayer(3),
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
                      MyLog.log(_classString, 'Error saving result: $e', indent: true);
                      if (context.mounted) UiHelper.showMessage(context, 'No se ha podido añadir el resultado\n$e');
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
      ),
    );
  }

  Widget _selectPlayer(int numValue) {
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: DropdownMenu<MyUser>(
        width: double.infinity,
        initialSelection: selectedPlayer[numValue],
        onSelected: (MyUser? value) {
          setState(() {
            selectedPlayer[numValue] = value;
          });
        },
        dropdownMenuEntries:
            _match.getPlayers(state: PlayingState.playing).map<DropdownMenuEntry<MyUser>>((MyUser user) {
          return DropdownMenuEntry<MyUser>(
            value: user,
            label: user.name,
            leadingIcon: CircleAvatar(
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            ),
          );
        }).toList(),
        leadingIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            backgroundImage:
                selectedPlayer[numValue]?.avatarUrl != null ? NetworkImage(selectedPlayer[numValue]!.avatarUrl!) : null,
          ),
        ),
      ),
    );
  }

  Widget _selectSetResult() {
    return Column(
      spacing: 8.0,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _selectPartialResult(0),
        Text('Resultado', style: TextStyle(fontWeight: FontWeight.bold)),
        _selectPartialResult(1),
      ],
    );
  }

  Widget _selectPartialResult(int team) {
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(0.0),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: DropdownMenu<int>(
        width: 90,
        initialSelection: results[team],
        onSelected: (int? value) {
          if (value != null) {
            setState(() {
              results[team] = value;
            });
          }
        },
        dropdownMenuEntries: List.generate(maxGamesPerSet, (result) {
          return DropdownMenuEntry<int>(
            value: result,
            label: result.toString(),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _save() async {
    bool isAnyPlayerNull = selectedPlayer.contains(null);
    bool areAllResultsZero = results.every((result) => result == 0);

    if (isAnyPlayerNull) {
      MyLog.log(_classString, 'Null player. players=$selectedPlayer', indent: true);
      throw 'Añadir todos los jugadores';
    }

    if (areAllResultsZero) {
      MyLog.log(_classString, 'All results 0. results=$results', indent: true);
      throw 'El resultado no puede ser 0-0';
    }

    // create teamA
    TeamResult teamA = TeamResult(
      player1: selectedPlayer[0]!,
      player2: selectedPlayer[1]!,
      points: _calculatePointsA(),
      preRanking1: selectedPlayer[0]!.rankingPos,
      preRanking2: selectedPlayer[1]!.rankingPos,
      score: results[0],
    );

    // create teamB
    TeamResult teamB = TeamResult(
      player1: selectedPlayer[2]!,
      player2: selectedPlayer[3]!,
      points: -_calculatePointsA(),
      preRanking1: selectedPlayer[2]!.rankingPos,
      preRanking2: selectedPlayer[3]!.rankingPos,
      score: results[1],
    );

    // create GameResult
    GameResult gameResult = GameResult(
      id: GameResultId(userId: context.read<AppState>().getLoggedUser().id),
      matchId: _match.id,
      teamA: teamA,
      teamB: teamB,
    );

    // save result
    try {
      MyLog.log(_classString, 'Saving result: $gameResult', indent: true);
      await FbHelpers().updateResult(result: gameResult, matchId: _match.id.toYyyyMMdd());
    } catch (e) {
      MyLog.log(_classString, 'Error saving result: $e', level: Level.WARNING, indent: true);
      throw 'Error al guardar el resultado.\n $e';
    }

    // add points to users
    try {
      MyLog.log(_classString, 'Updating players points', indent: true);
      selectedPlayer.sublist(0, 2).forEach((player) => player!.rankingPos += teamA.points);
      selectedPlayer.sublist(2, 4).forEach((player) => player!.rankingPos += teamB.points);
      await Future.wait(selectedPlayer.map((e) async => await FbHelpers().updateUser(e!)));
    } catch (e) {
      MyLog.log(_classString, 'Updating players points: $e', level: Level.WARNING, indent: true);
      throw ('Error al actualizar los puntos de los jugadores. \n$e');
    }
  }

  int _calculatePointsA() {
    if (selectedPlayer.length != 4) {
      throw ArgumentError('selectedPlayer must have 4 elements.');
    }
    return results[0] > results[1] ? 100 : -100;
  }
}
