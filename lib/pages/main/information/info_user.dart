import 'package:flutter/material.dart';
import 'package:no_solo_padel/models/md_match.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../database/db_firebase_helpers.dart';
import '../../../interface/if_app_state.dart';
import '../../../interface/if_director.dart';
import '../../../models/md_set_result.dart';
import '../../../models/md_user.dart';
import '../../../models/md_debug.dart';
import '../../../utilities/ui_helpers.dart';
import '../../../utilities/ut_theme.dart';
import 'modal_modify_user.dart';

final String _classString = 'InfoUserPanel'.toUpperCase();

class InfoUserPanel extends StatefulWidget {
  final String userId;

  const InfoUserPanel({super.key, required this.userId});

  @override
  State<InfoUserPanel> createState() => InfoUserPanelState();
}

class InfoUserPanelState extends State<InfoUserPanel> {
  late final MyUser? _user;
  late final Director _director;

  int _rankingPos = -1;

  // matches
  int _numberOfPlayedMatches = -1; // days played
  int _numberOfSignedInMatches = -1; // days user has signed in
  // sets
  int _numberOfSets = -1;
  int _numberOfSetWins = -1;
  int _numberOfSetLoses = -1;

  // score
  int _sumOfScores = -1;
  int _sumOfScoresAgainst = -1;

  // last 5 sets
  List<int?> _lastFiveSets = [];

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);
    _user = context.read<AppState>().getUserById(widget.userId);
    _director = context.read<Director>();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return UiHelper.buildErrorMessage(
          errorMessage: 'Usuario no encontrado',
          buttonText: 'Reintentar',
          onPressed: () async {
            UiHelper.reloadPage();
          });
    }

    try {
      ImageProvider? imageProvider = _user!.avatarUrl != null ? NetworkImage(_user!.avatarUrl!) : null;

      // calculate rankingPos
      _rankingPos = _director.appState.getUserRankingPos(_user!);
      bool isLoggedUserAdminOrSuper = _director.appState.isLoggedUserAdminOrSuper;
      MyLog.log(_classString, 'isLoggedUserAdminOrSuper=$isLoggedUserAdminOrSuper', level: Level.INFO);

      return Scaffold(
        appBar: AppBar(title: Text(_user?.name ?? 'Profile')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Text('?', style: TextStyle(fontSize: 24, color: Colors.white))
                          : null,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Text(
                        'Ranking: ${_user?.rankingPos ?? '-'}\n\n'
                        'Posición: $_rankingPos',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                if (isLoggedUserAdminOrSuper)
                  ElevatedButton(
                      onPressed: () async {
                        await _modifyUserModal(context, _user!);
                      },
                      child: const Text('Editar jugador')),
                if (isLoggedUserAdminOrSuper) const SizedBox(height: 24.0),
                const Text(
                  'Estadísticas de Partidos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                FutureBuilder<void>(
                  future: _matchStatistics(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      try {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Número de días que ha jugado: $_numberOfPlayedMatches',
                                style: const TextStyle(fontSize: 14)),
                            Text('Número de días a los que está apuntado: $_numberOfSignedInMatches',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 16.0),
                            Text('Número de sets: $_numberOfSets', style: const TextStyle(fontSize: 14)),
                            Text(
                                'Número de sets ganados: $_numberOfSetWins (${_percentage(_numberOfSetWins, _numberOfSets)})',
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                'Número de sets perdidos: $_numberOfSetLoses (${_percentage(_numberOfSetLoses, _numberOfSets)})',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 16.0),
                            Text(
                                'Número de juegos a favor: $_sumOfScores (${_percentage(_sumOfScores, _sumOfScores + _sumOfScoresAgainst)})',
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                'Número de juegos en contra: $_sumOfScoresAgainst (${_percentage(_sumOfScoresAgainst, _sumOfScores + _sumOfScoresAgainst)})',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 16.0),
                            Text('Últimos sets: ', style: const TextStyle(fontSize: 14)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 8,
                              children: [
                                for (final int? score in _lastFiveSets)
                                  score == null
                                      ? const SizedBox.shrink()
                                      : Container(
                                          padding: const EdgeInsets.all(4),
                                          color: (score > 0 ? kLightGreen : kLightRed),
                                          child: Text('$score', style: const TextStyle(fontSize: 14)),
                                        )
                              ],
                            ),
                          ],
                        );
                      } catch (e) {
                        return UiHelper.buildErrorMessage(
                            errorMessage: 'Error en el cálculo de estadísticas\n'
                                'Error: ${e.toString()}',
                            buttonText: 'Reintentar',
                            onPressed: () async {
                              UiHelper.reloadPage();
                            });
                      }
                    } else if (snapshot.hasError) {
                      MyLog.log(_classString, 'Future builder error', exception: snapshot.error, level: Level.WARNING);
                      return UiHelper.buildErrorMessage(
                          errorMessage: 'Error cargando datos\n'
                              'Error: ${snapshot.error}',
                          buttonText: 'Reintentar',
                          onPressed: () async {
                            UiHelper.reloadPage();
                          });
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cargando los partidos ...', style: TextStyle(fontSize: 14)),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const CircularProgressIndicator(),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return UiHelper.buildErrorMessage(
          errorMessage: e.toString(),
          buttonText: 'Reintentar',
          onPressed: () async {
            UiHelper.reloadPage();
          });
    }
  }

  Future<bool> _matchStatistics() async {
    MyLog.log(_classString, 'matchParameters', level: Level.FINE);

    List<MyMatch> matchesWithPlayer =
        await FbHelpers().getAllMatchesWithPlayer(appState: _director.appState, playerId: _user!.id);
    List<SetResult> setResultsWithPlayer =
        await FbHelpers().getSetResults(appState: _director.appState, playerId: _user!.id);

    MyLog.log(_classString, '*********** setResultsWithPlayer.length=${setResultsWithPlayer.length}');

    // matches
    _numberOfSignedInMatches = matchesWithPlayer.length;
    _numberOfPlayedMatches = setResultsWithPlayer.map((item) => item.id.matchId).toSet().length;

    // sets
    _numberOfSets = setResultsWithPlayer.length;
    _numberOfSetWins = setResultsWithPlayer.where((item) => item.playerHasWon(_user!)).length;
    _numberOfSetLoses = _numberOfSets - _numberOfSetWins;

    // score
    _sumOfScores = 0;
    _sumOfScoresAgainst = 0;
    for (SetResult setResult in setResultsWithPlayer) {
      List<int>? scores = setResult.getScores(_user!);
      if (scores != null) {
        _sumOfScores += scores[0];
        _sumOfScoresAgainst += scores[1];
      }
    }

    // last 5 sets
    setResultsWithPlayer.sort((a, b) => b.id.resultId.compareTo(a.id.resultId));
    _lastFiveSets = setResultsWithPlayer.take(5).map((item) => item.getPoints(_user!)).toList();

    return true;
  }

  String _percentage(int numberOfSetWins, int numberOfSets) {
    if (numberOfSets == 0) return '- %';
    return '${(numberOfSetWins / numberOfSets * 100).round()}%';
  }

  Future _modifyUserModal(BuildContext context, MyUser user) {
    return UiHelper.modalPanel(context, user.name, ModifyUserModal(user: user));
  }
}
