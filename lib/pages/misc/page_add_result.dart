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
  const AddResultPage({super.key, required this.matchId });

  // argument matchJson vs matchId
  // matchJson: initialValue for FormBuilder will hold the correct initial values
  //   If another user changes any field, the form will not update
  //   A new matchJson will be received. But Form fields won't be updated.
  //   Good for configuration panel
  // matchId: _formKey.currentState?.fields[commentId]?.didChange(match.comment); should be implemented
  //   If any user changes any field, the form will update. Or if any rebuild is made, changes would be lost.
  final String matchId;

  @override
  State<AddResultPage> createState() => _AddResultPageState();
}

class _AddResultPageState extends State<AddResultPage> {
  MyMatch? _match;
  late AppState _appState;
  bool _matchLoaded = false;
  String _errorMessage = '';
  final List<MyUser?> _selectedPlayer = List.filled(numPlayers, null);
  final List<int> _scores = [0, 0];

  @override
  void initState() {
    super.initState();
    try {
      _appState = context.read<AppState>();
      _initialize();
    } catch (e) {
      MyLog.log(_classString, 'Error initializing resultPage: ${e.toString()}', level: Level.SEVERE, indent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    if (!_matchLoaded) {
      MyLog.log(_classString, 'Building: match still not loaded', indent: true);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 40),
            _errorMessage != '' ? Text(_errorMessage) : Text('Cargando el partido ...', style: TextStyle(fontSize: 24)),
          ],
        ),
      );
    } else if (_match == null) {
      MyLog.log(_classString, 'Building: match is null', indent: true);
      return Center(child: Text('Error al cargar el partido ...'));
    }

    MyLog.log(_classString, 'Building: match loaded match=$_match', indent: true);

    // match is correct
    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(_match!.id.longFormat()),
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
                  children: [_selectAddResult()],
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
                        MyLog.log(_classString, 'Error saving result: ${e.toString()}', indent: true);
                        if (context.mounted) {
                          UiHelper.showMessage(context, 'No se ha podido añadir el resultado\n${e.toString()}');
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
        ),
      );
    } catch (e) {
      return Text('Error cargando el partido ...\n${e.toString()}', style: TextStyle(fontSize: 24));
    }
  }

  Widget _selectPlayer(int numValue) {
    MyLog.log(_classString, '_selectPlayer numValue=$numValue', indent: true);
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.inversePrimary,
      child: DropdownMenu<MyUser>(
        width: double.infinity,
        initialSelection: _selectedPlayer[numValue],
        onSelected: (MyUser? value) {
          setState(() {
            _selectedPlayer[numValue] = value;
          });
        },
        dropdownMenuEntries:
            _match!.getPlayers(state: PlayingState.playing).map<DropdownMenuEntry<MyUser>>((MyUser user) {
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
            backgroundImage: _selectedPlayer[numValue]?.avatarUrl != null
                ? NetworkImage(_selectedPlayer[numValue]!.avatarUrl!)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _selectAddResult() {
    MyLog.log(_classString, '_selectAddResult', indent: true);
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
    MyLog.log(_classString, '_selectPartialResult team=$team', indent: true);
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(0.0),
      color: Theme.of(context).colorScheme.inversePrimary,
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
    MyLog.log(_classString, '_save', indent: true);

    bool isAnyPlayerNull = _selectedPlayer.contains(null);
    bool areAllResultsZero = _scores.every((result) => result == 0);

    if (isAnyPlayerNull) {
      MyLog.log(_classString, 'Null player. players=$_selectedPlayer', indent: true);
      throw 'Añadir todos los jugadores';
    }

    if (areAllResultsZero) {
      MyLog.log(_classString, 'All results 0. results=$_scores', indent: true);
      throw 'El resultado no puede ser 0-0';
    }

    // check if there are repeated players
    Set<MyUser> uniquePlayers = Set.from(_selectedPlayer);
    if (uniquePlayers.length != numPlayers) {
      MyLog.log(_classString, 'Repeated players. players=$_selectedPlayer', indent: true);
      throw 'No se puede repetir un jugador';
    }

    // create teamA
    TeamResult teamA = TeamResult(
      player1: _selectedPlayer[0]!,
      player2: _selectedPlayer[1]!,
      points: _calculatePoints(true),
      score: _scores[0],
    );

    // create teamB
    TeamResult teamB = TeamResult(
      player1: _selectedPlayer[2]!,
      player2: _selectedPlayer[3]!,
      points: _calculatePoints(false),
      score: _scores[1],
    );

    // create GameResult
    GameResult gameResult = GameResult(
      id: GameResultId(userId: _appState.getLoggedUser().id),
      matchId: _match!.id,
      teamA: teamA,
      teamB: teamB,
    );

    // save result to Firestore
    try {
      MyLog.log(_classString, 'Saving result: $gameResult', indent: true);
      await FbHelpers().updateResult(result: gameResult, matchId: _match!.id.toYyyyMMdd());
    } catch (e) {
      MyLog.log(_classString, 'Error saving result: ${e.toString()}', level: Level.WARNING, indent: true);
      throw 'Error al guardar el resultado.\n ${e.toString()}';
    }

    // add points to players
    try {
      MyLog.log(_classString, 'Updating players points', indent: true);
      _selectedPlayer.sublist(0, 2).forEach((player) => player!.rankingPos += teamA.points);
      _selectedPlayer.sublist(2, 4).forEach((player) => player!.rankingPos += teamB.points);
      await Future.wait(_selectedPlayer.map((e) async => await FbHelpers().updateUser(e!)));
    } catch (e) {
      MyLog.log(_classString, 'Updating players points: ${e.toString()}', level: Level.WARNING, indent: true);
      throw ('Error al actualizar los puntos de los jugadores. \n${e.toString()}');
    }
  }

  int _calculatePoints(bool teamA) {
    MyLog.log(_classString, '_calculatePointsA', indent: true);
    if (_selectedPlayer.length != 4) {
      throw ArgumentError('selectedPlayer must have 4 elements.');
    }
    if (teamA) {
      return _scores[0] > _scores[1] ? 100 : 0;
    } else {
      return _scores[1] > _scores[0] ? 100 : 0;
    }
  }

  void _initialize() async {
    MyLog.log(_classString, '_initialize: Initializing parameters: ${widget.matchId}');
    try {
      // get match
      _match = await FbHelpers().getMatch(widget.matchId, _appState);
      MyLog.log(_classString, '_initialize: match = $_match', indent: true);

      // all loaded
      setState(() {
        _matchLoaded = true;
      });
    } catch (e) {
      MyLog.log(_classString, 'Error initializing resultPage: ${e.toString()}', level: Level.SEVERE, indent: true);
      setState(() {
        _errorMessage = 'Error al cargar el partido.\n${e.toString()}';
      });
    }
  }
}
