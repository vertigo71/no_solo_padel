import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../database/db_firebase_helpers.dart';
import '../../../interface/if_app_state.dart';
import '../../../interface/if_director.dart';
import '../../../models/md_result.dart';
import '../../../models/md_user.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_user_match_result.dart';
import '../../../utilities/ui_helpers.dart';
import '../../../utilities/ut_theme.dart';

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
  // games
  int _numberOfGames = -1;
  int _numberOfGameWins = -1;
  int _numberOfGameLosses = -1;

  // score
  int _sumOfScores = -1;
  int _sumOfScoresAgainst = -1;

  // last 5 games
  List<int?> _lastFiveGames = [];

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
                const Text(
                  'Estadísticas de Partidos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                FutureBuilder<void>(
                  future: _matchParameters(),
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
                            Text('Número de partidos: $_numberOfGames', style: const TextStyle(fontSize: 14)),
                            Text(
                                'Número partidos ganados: $_numberOfGameWins (${_percentage(_numberOfGameWins, _numberOfGames)})',
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                'Número partidos perdidos: $_numberOfGameLosses (${_percentage(_numberOfGameLosses, _numberOfGames)})',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 16.0),
                            Text(
                                'Número de juegos a favor: $_sumOfScores (${_percentage(_sumOfScores, _sumOfScores + _sumOfScoresAgainst)})',
                                style: const TextStyle(fontSize: 14)),
                            Text(
                                'Número de juegos en contra: $_sumOfScoresAgainst (${_percentage(_sumOfScoresAgainst, _sumOfScores + _sumOfScoresAgainst)})',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 16.0),
                            Text('Últimos juegos: ', style: const TextStyle(fontSize: 14)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              spacing: 8,
                              children: [
                                for (final int? score in _lastFiveGames)
                                  score == null
                                      ? const SizedBox.shrink()
                                      : Container(
                                          padding: const EdgeInsets.all(4),
                                          color: (score > 0 ? kLightGreen : kLightRed ),
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

  Future<bool> _matchParameters() async {
    MyLog.log(_classString, 'matchParameters', level: Level.FINE);

    // matches
    List<UserMatchResult> userMatchResults = await FbHelpers().getUserMatchResults(userId: _user!.id);
    _numberOfSignedInMatches = userMatchResults.where((item) => item.resultId == null).length;

    List<UserMatchResult> onlyWithGameResults = userMatchResults.where((item) => item.resultId != null).toList();
    Set<String> matchIdsWithGameResults = onlyWithGameResults.map((item) => item.matchId).toSet();
    _numberOfPlayedMatches = matchIdsWithGameResults.length;

    // games
    List<GameResult> gameResults = [];
    for (UserMatchResult userMatchResult in onlyWithGameResults) {
      GameResult? gameResult =
          await FbHelpers().getGameResult(resultId: userMatchResult.resultId!, appState: _director.appState);
      if (gameResult != null) gameResults.add(gameResult);
    }
    _numberOfGames = onlyWithGameResults.length;
    _numberOfGameWins = gameResults.where((item) => item.playerHasWon(_user!)).length;
    _numberOfGameLosses = _numberOfGames - _numberOfGameWins;

    // score
    _sumOfScores = 0;
    _sumOfScoresAgainst = 0;
    for (GameResult gameResult in gameResults) {
      List<int>? scores = gameResult.getScores(_user!);
      if (scores != null) {
        _sumOfScores += scores[0];
        _sumOfScoresAgainst += scores[1];
      }
    }

    // last 5 games
    gameResults.sort((a, b) => b.id.resultId.compareTo(a.id.resultId));
    _lastFiveGames = gameResults.take(5).map((item) => item.getPoints(_user!)).toList();

    return true;
  }

  String _percentage(int numberOfGameWins, int numberOfGames) {
    if (numberOfGames == 0) return '- %';
    return '${(numberOfGameWins / numberOfGames * 100).round()}%';
  }
}
