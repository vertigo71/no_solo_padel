import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_multi_select_items/flutter_multi_select_items.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel/utilities/ut_theme.dart';
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

enum ScoreFields { teamA, teamB }

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
  final _formKey = GlobalKey<FormBuilderState>(); // Form key

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
          _buildMultiSelection(),
          const Divider(
            height: 8.0,
          ),
          // add Team A
          Wrap(
            children: [
              _buildPlayer(0),
              _buildPlayer(1),
            ],
          ),
          // add score
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FormBuilder(
              key: _formKey,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [_buildResults()],
              ),
            ),
          ),
          // add Team B
          Wrap(
            children: [
              _buildPlayer(2),
              _buildPlayer(3),
            ],
          ),
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

  Widget _buildMultiSelection() {
    MyLog.log(_classString, '_buildMultiSelection', level: Level.FINE, indent: true);
    List<MyUser> players = _match.getPlayers(state: PlayingState.playing);
    players.sort(getMyUserComparator(UsersSortBy.name));

    return MultiSelectContainer(
        itemsPadding: const EdgeInsets.all(12.0),
        maxSelectableCount: kNumPlayers,
        items: [
          ...players.map((player) => MultiSelectCard(
              value: player,
              label: player.name,
              textStyles: MultiSelectItemTextStyles(textStyle: TextStyle(fontSize: 12, color: kBlack))))
        ],
        onChange: (allSelectedItems, selectedItem) {
          if (allSelectedItems.contains(selectedItem) && _selectedPlayers.contains(null)) {
            // add player
            setState(() {
              _selectedPlayers[_selectedPlayers.indexOf(null)] = selectedItem;
            });
          }
          if (!allSelectedItems.contains(selectedItem) && _selectedPlayers.contains(selectedItem)) {
            setState(() {
              _selectedPlayers[_selectedPlayers.indexOf(selectedItem)] = null;
            });
          }
        });
  }

  Widget _buildPlayer(int numValue) {
    MyLog.log(_classString, '_buildPlayer numValue=$numValue', indent: true, level: Level.FINE);
    return Card(
      elevation: 6.0,
      margin: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceBright,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 100,
          maxWidth: 300,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0), // Add padding for better visual appearance
          child: Text(
            _selectedPlayers[numValue]?.name ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            softWrap: true, // Allow text to wrap to multiple lines
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    MyLog.log(_classString, '_buildResult', level: Level.FINE, indent: true);
    return Expanded(
      child: Column(
        spacing: 8.0,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildOneResult(ScoreFields.teamA),
          _buildOneResult(ScoreFields.teamB),
        ],
      ),
    );
  }

  Widget _buildOneResult(ScoreFields field) {
    MyLog.log(_classString, '_buildOneResult team=$field', indent: true, level: Level.FINE);
    return SizedBox(
      width: 100.0,
      child: Card(
        elevation: 6.0,
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surfaceBright,
        child: FormBuilderDropdown<int>(
          name: field.name,
          initialValue: 0,
          menuWidth: 70,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.only(top: 8.0, bottom: 8.0), // Remove padding
            isDense: true, //important
          ),
          items: List.generate(kMaxGamesPerSet, (result) {
            return DropdownMenuItem<int>(
              value: result,
              child: Center(child: Text(result.toString())),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    MyLog.log(_classString, '_save', indent: true);

    // Check if the form is valid before proceeding
    if (_formKey.currentState!.saveAndValidate()) {
      final formValues = _formKey.currentState!.value;
      int scoreA = formValues[ScoreFields.teamA.name];
      int scoreB = formValues[ScoreFields.teamB.name];

      MyLog.log(_classString, 'players = $_selectedPlayers scoreA=$scoreA scoreB=$scoreB', indent: true);

      bool isAnyPlayerNull = _selectedPlayers.contains(null);
      bool areAllResultsZero = (scoreA == 0 && scoreB == 0);
      if (isAnyPlayerNull) {
        MyLog.log(_classString, 'Null player. players=$_selectedPlayers', indent: true);
        throw 'Añadir todos los jugadores';
      }

      if (areAllResultsZero) {
        MyLog.log(_classString, 'All results 0.', indent: true);
        throw 'El resultado no puede ser 0-0';
      }

      // check if there are repeated players
      Set<MyUser> uniquePlayers = Set.from(_selectedPlayers);
      if (uniquePlayers.length != kNumPlayers) {
        MyLog.log(_classString, 'Repeated players. players=$_selectedPlayers', indent: true);
        throw 'No se puede repetir un jugador';
      }

      // calculate the points that each team will get
      List<int> points = _calculatePoints(scoreA, scoreB);

      // create teamA
      TeamResult teamA = TeamResult(
        player1: _selectedPlayers[0]!,
        player2: _selectedPlayers[1]!,
        points: points[0],
        score: scoreA,
        preRanking1: _selectedPlayers[0]!.rankingPos,
        preRanking2: _selectedPlayers[1]!.rankingPos,
      );

      // create teamB
      TeamResult teamB = TeamResult(
        player1: _selectedPlayers[2]!,
        player2: _selectedPlayers[3]!,
        points: points[1],
        score: scoreB,
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
        await FbHelpers().updateResult(result: gameResult, matchId: _match.id.toYyyyMmDd());
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
    }
  }

  /// list of 2 ints with the points of each team A and B
  List<int> _calculatePoints(int scoreA, int scoreB) {
    MyLog.log(_classString, '_calculatePointsA', indent: true);

    if (_selectedPlayers.length != 4) {
      throw ArgumentError('No se ha podido obtener los cuatro jugadores');
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
        scoreA: scoreA,
        scoreB: scoreB,
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
