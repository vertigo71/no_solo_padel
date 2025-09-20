import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:no_solo_padel/models/md_user.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../database/db_firebase_helpers.dart';
import '../../interface/if_director.dart';
import '../../models/md_debug.dart';
import '../../models/md_exception.dart';
import '../../models/md_parameter.dart';
import '../../models/md_set_result.dart';

final String _classString = 'CheckPanel'.toUpperCase();

enum PlayerIds { playerA1, playerA2, playerB1, playerB2 }

class CheckPanel extends StatefulWidget {
  const CheckPanel({super.key});

  @override
  CheckPanelState createState() => CheckPanelState();
}

class CheckPanelState extends State<CheckPanel> {
  final List<String> _output = [];
  final ScrollController _scrollController = ScrollController();
  late final Director _director;

  @override
  void initState() {
    super.initState();
    _director = context.read<Director>();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _checkAllResults,
              child: const Text('Check all results'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recalculateResults,
              child: const Text('Recalculate all results'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _output.clear()),
              child: const Text('Clear all'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceDim,
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _output.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _output[index],
                      style: const TextStyle(fontSize: 14),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: erase all subcollections

  Future<void> _checkAllResults() async {
    MyLog.log(_classString, '_checkResults', level: Level.FINE);
    _addOutput("Check all results");

    final int resetValue;
    try {
      resetValue = int.parse(_director.appState.getParamValue(ParametersEnum.bDefaultRanking));
      _addOutput("Reset value = $resetValue");
    } catch (e) {
      MyLog.log(_classString, 'Error parsing reset value ${e.toString()}', level: Level.SEVERE, indent: true);
      throw MyException('Error al obtener el parámetro del ranking por defecto.', e: e, level: Level.SEVERE);
    }

    // create a new user object with the updated rankingPos
    List<MyUser> users =
        _director.appState.usersSortedByName.map((user) => user.copyWith(rankingPos: resetValue)).toList();

    // iterate through every result
    _addOutput("Getting all results");
    final List<SetResult> allResults = await FbHelpers().getSetResults(appState: _director.appState)
      ..sort((a, b) => a.id.resultId.compareTo(b.id.resultId)); // natural order
    bool ok = true;
    for (SetResult result in allResults) {
      MyLog.log(_classString, '_checkResults result=${result.id}', level: Level.FINE, indent: true);
      try {
        _addOutput("Checking result=${result.id}");
        ok = _checkResult(result, users);
        if (!ok) {
          _addOutput("Aborting....");
          break;
        }
      } catch (e) {
        MyLog.log(_classString, 'Error in result=${result.id}, error=${e.toString()}',
            level: Level.SEVERE, indent: true);
        throw MyException('Error al chequear los puntos del resultado ${result.id}.', e: e, level: Level.SEVERE);
      }
    }

    if (ok) {
      // users rankingPos == usersInAppState.rankingPos
      _addOutput("Checking current rankingPos for all users...");
      for (MyUser user in users) {
        MyUser? userInAppState = _director.appState.getUserById(user.id);
        if (userInAppState == null) {
          MyLog.log(_classString, 'User not found in appState: ${user.name}', level: Level.SEVERE, indent: true);
          _addOutput("User not found in appState: ${user.name}");
        } else if (userInAppState.rankingPos != user.rankingPos) {
          MyLog.log(_classString, 'User rankingPos is not the same: ${user.name}', level: Level.WARNING, indent: true);
          _addOutput("User rankingPos is not the same: ${user.name}");
          _addOutput("-- appState ranking = ${userInAppState.rankingPos}, calculated = ${user.rankingPos}");
        }
      }
      _addOutput("Checking current rankingPos for all users finished");
    }
  }

  bool _checkResult(SetResult result, List<MyUser> users) {
    MyLog.log(_classString, '_checkResult', level: Level.FINE, indent: true);

    MyUser? playerA1 = users.firstWhereOrNull((user) => user.id == result.teamA!.player1.id);
    MyUser? playerA2 = users.firstWhereOrNull((user) => user.id == result.teamA!.player2.id);
    MyUser? playerB1 = users.firstWhereOrNull((user) => user.id == result.teamB!.player1.id);
    MyUser? playerB2 = users.firstWhereOrNull((user) => user.id == result.teamB!.player2.id);
    if (playerA1 == null || playerA2 == null || playerB1 == null || playerB2 == null) {
      MyLog.log(_classString, 'Player not found: $playerA1, $playerA2, $playerB1, $playerB2',
          level: Level.SEVERE, indent: true);
      _addOutput("Player not found: $playerA1, $playerA2, $playerB1, $playerB2");
      return false;
    }

    // check if preRanking is the same
    bool somethingHasChanged = _compareRankings(result.teamA!.preRanking1, "TeamA Player1", playerA1) ||
        _compareRankings(result.teamA!.preRanking2, "TeamA Player2", playerA2) ||
        _compareRankings(result.teamB!.preRanking1, "TeamB Player1", playerB1) ||
        _compareRankings(result.teamB!.preRanking2, "TeamB Player2", playerB2);

    if (somethingHasChanged) {
      _addOutput("Result = \n$result");
      return false;
    }

    // update user rankings
    playerA1.rankingPos += result.teamA!.points;
    playerA2.rankingPos += result.teamA!.points;
    playerB1.rankingPos += result.teamB!.points;
    playerB2.rankingPos += result.teamB!.points;

    return true;
  }

  // Function to rebuild matches in users
  Future<void> _recalculateResults() async {
    MyLog.log(_classString, '_recalculateResults', level: Level.FINE);
    _addOutput("Recalculate all results");

    // set all user points to initial value
    final int resetValue;
    try {
      resetValue = int.parse(_director.appState.getParamValue(ParametersEnum.bDefaultRanking));
      _addOutput("Reset value = $resetValue");
    } catch (e) {
      MyLog.log(_classString, 'Error parsing reset value ${e.toString()}', level: Level.SEVERE, indent: true);
      throw MyException('Error al obtener el parámetro del ranking por defecto.', e: e, level: Level.SEVERE);
    }

    try {
      _addOutput("Resetting users points to default ranking = $resetValue");
      await FbHelpers().resetUsersBatch(newRanking: resetValue);
      _addOutput("Resetting users points to default ranking FINISHED");
    } catch (e) {
      MyLog.log(_classString, 'Error resetting user points to default ranking ${e.toString()}',
          level: Level.SEVERE, indent: true);
      throw MyException('Error al resetear los puntos de los usuarios.', e: e, level: Level.SEVERE);
    }

    // iterate through every result updating users points
    _addOutput("Getting all results");
    final List<SetResult> allResults = await FbHelpers().getSetResults(appState: _director.appState)
      ..sort((a, b) => a.id.resultId.compareTo(b.id.resultId)); // natural order
    for (SetResult result in allResults) {
      MyLog.log(_classString, '_recalculateResults result=${result.id}', level: Level.FINE, indent: true);
      try {
        _addOutput("Updating for result=${result.id}");
        await _updateResult(result);
      } catch (e) {
        MyLog.log(_classString, 'Error updating result=${result.id}, error=${e.toString()}',
            level: Level.SEVERE, indent: true);
        throw MyException('Error al actualizar los puntos del resultado ${result.id}.', e: e, level: Level.SEVERE);
      }
    }
  }

  Future<void> _updateResult(SetResult result) async {
    MyLog.log(_classString, '_updateResult', level: Level.FINE, indent: true);

    // check if preRanking is the same
    bool somethingHasChanged = _compareRankings(result.teamA!.preRanking1, "TeamA Player1", result.teamA!.player1) ||
        _compareRankings(result.teamA!.preRanking2, "TeamA Player2", result.teamA!.player2) ||
        _compareRankings(result.teamB!.preRanking1, "TeamB Player1", result.teamB!.player1) ||
        _compareRankings(result.teamB!.preRanking2, "TeamB Player2", result.teamB!.player2);

    List<int> points = [result.teamA!.points, result.teamB!.points];

    if (somethingHasChanged) {
      // calculate the points that each team will get
      points = _director.calculateScoreRankingPoints(
        result.teamA!.score,
        result.teamB!.score,
        result.extraPoints,
        result.teamA!.player1.rankingPos + result.teamA!.player2.rankingPos,
        result.teamB!.player1.rankingPos + result.teamB!.player2.rankingPos,
      );

      // create teamA
      TeamResult teamA = TeamResult(
        player1: result.teamA!.player1,
        player2: result.teamA!.player2,
        points: points[0],
        score: result.teamA!.score,
        preRanking1: result.teamA!.player1.rankingPos,
        preRanking2: result.teamA!.player2.rankingPos,
      );

      // create teamB
      TeamResult teamB = TeamResult(
        player1: result.teamB!.player1,
        player2: result.teamB!.player2,
        points: points[1],
        score: result.teamB!.score,
        preRanking1: result.teamB!.player1.rankingPos,
        preRanking2: result.teamB!.player2.rankingPos,
      );

      // create SetResult
      SetResult newSetResult = result.copyWith(
        teamA: teamA,
        teamB: teamB,
      );

      // save result to Firestore
      try {
        MyLog.log(_classString, 'Saving result: $newSetResult', indent: true);
        _addOutput("-- Updating result: $newSetResult");
        await FbHelpers().updateSetResult(result: newSetResult);
      } catch (e) {
        MyLog.log(_classString, 'Error updating result: ${e.toString()}', level: Level.WARNING, indent: true);
        _addOutput("-- Error updating result: ${e.toString()}");
        throw MyException('Error al actualizar el resultado ${result.id}.', e: e, level: Level.SEVERE);
      }
    } else {
      _addOutput("-- Result is ok");
    }

    // add points to players
    try {
      MyLog.log(_classString, 'Updating players points', indent: true);
      _addOutput("-- Updating players points");
      // players
      List<MyUser> players = [
        result.teamA!.player1,
        result.teamA!.player2,
        result.teamB!.player1,
        result.teamB!.player2
      ];
      players.sublist(0, 2).forEach((player) => player.rankingPos += points[0]);
      players.sublist(2, 4).forEach((player) => player.rankingPos += points[1]);
      await Future.wait(players.map((e) async => await FbHelpers().updateUser(e)));
    } catch (e) {
      MyLog.log(_classString, 'Updating players points: ${e.toString()}', level: Level.WARNING, indent: true);
      _addOutput("-- Error updating players points: ${e.toString()}");
      throw MyException('Error al actualizar los puntos de los jugadores', e: e, level: Level.SEVERE);
    }
  }

  // Helper function to add output and scroll to the bottom
  void _addOutput(String text) {
    setState(() {
      _output.add(text);
    });

    // Use a Future to ensure the ListView has been updated before scrolling.
    Future.delayed(Duration.zero, () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _compareRankings(int preRanking, String player, MyUser user) {
    if (preRanking != user.rankingPos) {
      MyLog.log(_classString, 'preRanking is not the same for $user', level: Level.FINE, indent: true);
      _addOutput("-- preRanking is not the same for $player= ${user.name}");
      _addOutput("---- preRanking = $preRanking, actual = ${user.rankingPos}");
      return true;
    }
    return false;
  }
}
