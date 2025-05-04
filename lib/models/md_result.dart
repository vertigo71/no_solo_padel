import 'package:simple_logger/simple_logger.dart';

import '../interface/if_app_state.dart';
import 'md_date.dart';
import 'md_debug.dart';
import 'md_user.dart';

final String _classString = '<md> MyResult'.toLowerCase();

const String kFieldSeparator = '#';

// result fields in Firestore
enum GameResultFs {
  resultId,
  matchId,
  player1,
  player2,
  points,
  preRanking1,
  preRanking2,
  score,
  teamA,
  teamB,
  results,
}

class GameResult {
  final GameResultId id;
  final Date matchId;
  final TeamResult? teamA;
  final TeamResult? teamB;

  GameResult({required String userId, required this.matchId, this.teamA, this.teamB})
      : id = GameResultId(matchId: matchId, userId: userId);

  GameResult._({required this.id, required this.matchId, this.teamA, this.teamB});

  bool _checkResultOk() {
    if (teamA == null || teamB == null || teamA!.score == teamB!.score) {
      MyLog.log(_classString, 'ERROR: wrong result Team A = $teamA Team B = $teamB', level: Level.SEVERE);
      return false;
    }
    return true;
  }

  List<MyUser> get winningPlayers {
    if (!_checkResultOk()) return [];
    if (teamA!.score > teamB!.score) return [teamA!.player1, teamA!.player2];
    return [teamB!.player1, teamB!.player2];
  }

  List<MyUser> get loosingPlayers {
    if (!_checkResultOk()) return [];
    if (teamA!.score < teamB!.score) return [teamA!.player1, teamA!.player2];
    return [teamB!.player1, teamB!.player2];
  }

  bool playerIsInResult(MyUser player) =>
      (teamA?.isPlayerInTeam(player) ?? false) || (teamB?.isPlayerInTeam(player) ?? false);

  bool playerHasWon(MyUser player) {
    if (!playerIsInResult(player)) return false;
    if (teamA?.isPlayerInTeam(player) ?? false) return teamA!.score > (teamB?.score ?? 0);
    if (teamB?.isPlayerInTeam(player) ?? false) return teamB!.score > (teamA?.score ?? 0);
    return false;
  }

  /// returns <0 if player has lost
  /// returns 0 if player is not in the result
  /// returns >0 if player has won
  int playerStatus(MyUser player) {
    if (!_checkResultOk()) return 0;
    if (teamA!.isPlayerInTeam(player)) return teamA!.score.compareTo(teamB!.score);
    if (teamB!.isPlayerInTeam(player)) return teamB!.score.compareTo(teamA!.score);

    return 0;
  }

  GameResult copyWith({
    GameResultId? id,
    Date? matchId,
    TeamResult? teamA,
    TeamResult? teamB,
  }) {
    return GameResult._(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
    );
  }

  factory GameResult.fromJson(Map<String, dynamic> json, final AppState appState) {
    if (json[GameResultFs.resultId.name] == null || json[GameResultFs.matchId.name] == null) {
      MyLog.log(
          _classString,
          'Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[GameResultFs.resultId.name]}, matchId: ${json[GameResultFs.matchId.name]}',
          myCustomObject: json,
          level: Level.SEVERE);
      throw FormatException('Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[GameResultFs.resultId.name]}, matchId: ${json[GameResultFs.matchId.name]}, json: $json');
    }

    try {
      return GameResult._(
        id: GameResultId.fromString(json[GameResultFs.resultId.name]),
        matchId: Date.parse(json[GameResultFs.matchId.name])!,
        teamA: json.containsKey('teamA') ? TeamResult.fromJson(json['teamA'], appState) : null,
        teamB: json.containsKey('teamB') ? TeamResult.fromJson(json['teamB'], appState) : null,
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creando el resultado de la base de datos: \nError: ${e.toString()}');
      throw Exception('Error creando el resultado de la base de datos: \nError: ${e.toString()}');
    }
  }

  @Deprecated('To be removed')
  factory GameResult.fromJsonOldFormat(Map<String, dynamic> json, final AppState appState) {
    if (json[GameResultFs.resultId.name] == null || json[GameResultFs.matchId.name] == null) {
      MyLog.log(
          _classString,
          'Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[GameResultFs.resultId.name]}, matchId: ${json[GameResultFs.matchId.name]}',
          myCustomObject: json,
          level: Level.SEVERE);
      throw FormatException('Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[GameResultFs.resultId.name]}, matchId: ${json[GameResultFs.matchId.name]}, json: $json');
    }

    // old format is like: date#user
    String id = json[GameResultFs.resultId.name];
    try {
      return GameResult._(
        id: GameResultId(
            userId: id.split(kFieldSeparator)[1],
            matchId: Date.parse(json[GameResultFs.matchId.name])!,
            dateTime: DateTime.parse(id.split(kFieldSeparator)[0])),
        matchId: Date.parse(json[GameResultFs.matchId.name])!,
        teamA: json.containsKey('teamA') ? TeamResult.fromJson(json['teamA'], appState) : null,
        teamB: json.containsKey('teamB') ? TeamResult.fromJson(json['teamB'], appState) : null,
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creando el resultado de la base de datos: \nError: ${e.toString()}');
      throw Exception('Error creando el resultado de la base de datos: \nError: ${e.toString()}');
    }
  }

  Map<String, dynamic> toJson() {
    if (id.resultId == '') {
      MyLog.log(
          _classString,
          'Identificador del resultado incorrecto al grabar en la BD. \n'
          'resultId: ${id.resultId}',
          level: Level.SEVERE);
      throw FormatException('Identificador del resultado incorrecto al grabar en la BD. \n'
          'resultId: ${id.resultId}');
    }
    return {
      GameResultFs.resultId.name: id.resultId,
      GameResultFs.matchId.name: matchId.toYyyyMmDd(),
      'teamA': teamA?.toJson(),
      'teamB': teamB?.toJson(),
    };
  }

  @override
  String toString() {
    return 'MyResult(id: $id, matchId: $matchId, teamA: $teamA, teamB: $teamB)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          matchId == other.matchId &&
          teamA == other.teamA &&
          teamB == other.teamB;

  @override
  int get hashCode => id.hashCode ^ matchId.hashCode ^ teamA.hashCode ^ teamB.hashCode;
}

class TeamResult {
  final MyUser player1;
  final MyUser player2;
  final int points;
  final int score;
  final int preRanking1; // ranking of player1 before the match
  final int preRanking2; // ranking of player2 before the match

  TeamResult({
    required this.player1,
    required this.player2,
    required this.points,
    required this.score,
    required this.preRanking1,
    required this.preRanking2,
  });

  bool isPlayerInTeam(MyUser player) => player1 == player || player2 == player;

  TeamResult copyWith({
    MyUser? player1,
    MyUser? player2,
    int? points,
    int? score,
    int? preRanking1,
    int? preRanking2,
  }) {
    return TeamResult(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      points: points ?? this.points,
      score: score ?? this.score,
      preRanking1: preRanking1 ?? this.preRanking1,
      preRanking2: preRanking2 ?? this.preRanking2,
    );
  }

  factory TeamResult.fromJson(Map<String, dynamic> json, final AppState appState) {
    MyUser? player1 = appState.getUserById(json[GameResultFs.player1.name]);
    MyUser? player2 = appState.getUserById(json[GameResultFs.player2.name]);
    if (player1 == null || player2 == null) {
      MyLog.log(
          _classString,
          'Error leyendo la base de datos. \n'
          'Los jugadores ($player1, $player2) no existen en \n',
          myCustomObject: json,
          level: Level.SEVERE);
      throw Exception('Error leyendo la base de datos. \n'
          'Los jugadores ($player1, $player2) no existen en \n'
          '$json');
    }

    return TeamResult(
      player1: player1,
      player2: player2,
      points: json[GameResultFs.points.name] ?? 0,
      score: json[GameResultFs.score.name] ?? 0,
      preRanking1: json[GameResultFs.preRanking1.name] ?? 0,
      preRanking2: json[GameResultFs.preRanking2.name] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      GameResultFs.player1.name: player1.id,
      GameResultFs.player2.name: player2.id,
      GameResultFs.points.name: points,
      GameResultFs.score.name: score,
      GameResultFs.preRanking1.name: preRanking1,
      GameResultFs.preRanking2.name: preRanking2,
    };
  }

  @override
  String toString() {
    return 'TeamResult(player1: $player1, player2: $player2, points: $points, '
        'preRanking1: $preRanking1, preRanking2: $preRanking2, score: $score)';
  }

  int get preRanking => preRanking1 + preRanking2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamResult &&
          runtimeType == other.runtimeType &&
          player1 == other.player1 &&
          player2 == other.player2 &&
          points == other.points &&
          score == other.score &&
          preRanking1 == other.preRanking1 &&
          preRanking2 == other.preRanking2;

  @override
  int get hashCode =>
      player1.hashCode ^
      player2.hashCode ^
      points.hashCode ^
      score.hashCode ^
      preRanking1.hashCode ^
      preRanking2.hashCode;
}

class GameResultId {
  final Date _matchId;
  final DateTime _dateTime;
  final String _userId;

  GameResultId({required Date matchId, required String userId, DateTime? dateTime})
      : _matchId = matchId,
        _dateTime = dateTime ?? DateTime.now(),
        _userId = userId;

  factory GameResultId.fromString(String id) {
    try {
      final parts = id.split(kFieldSeparator);
      final matchId = Date.parse(parts[0])!;
      final dateTime = DateTime.parse(parts[1]);
      final userId = parts[2];
      return GameResultId(matchId: matchId, dateTime: dateTime, userId: userId);
    } catch (e) {
      MyLog.log(_classString, 'Invalid ResultId format: $id \nError: ${e.toString()}');
      throw FormatException('ResultId formato Invalido: $id \nError: ${e.toString()}');
    }
  }

  String get resultId => [_matchId.toYyyyMmDd(), _dateTime.toIso8601String(), _userId].join(kFieldSeparator);

  String get matchId => _matchId.toYyyyMmDd();

  String get userId => _userId;

  DateTime get dateTime => _dateTime;

  Date getMatchId() => _matchId;

  @override
  String toString() => '{$resultId}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameResultId &&
          runtimeType == other.runtimeType &&
          _dateTime == other._dateTime &&
          _matchId == other._matchId &&
          _userId == other._userId;

  @override
  int get hashCode => _dateTime.hashCode ^ _userId.hashCode ^ _matchId.hashCode;
}
