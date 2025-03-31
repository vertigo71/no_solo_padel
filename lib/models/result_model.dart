import 'package:simple_logger/simple_logger.dart';

import '../interface/app_state.dart';
import '../utilities/date.dart';
import 'debug.dart';
import 'user_model.dart';

final String _classString = '<md> MyResult'.toLowerCase();

const String fieldSeparator = '#';

// result fields in Firestore
enum ResultFs { resultId, matchId, player1, player2, points, preRanking1, preRanking2, score, teamA, teamB, results }

class GameResult {
  GameResultId id;
  Date matchId;
  TeamResult? teamA;
  TeamResult? teamB;

  GameResult({required this.id, required this.matchId, this.teamA, this.teamB});

  GameResult copyFrom({
    GameResultId? id,
    Date? matchId,
    TeamResult? teamA,
    TeamResult? teamB,
  }) {
    return GameResult(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
    );
  }

  factory GameResult.fromJson(Map<String, dynamic> json, final AppState appState) {
    if (json[ResultFs.resultId.name] == null || json[ResultFs.matchId.name] == null) {
      MyLog.log(
          _classString,
          'Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[ResultFs.resultId.name]}, matchId: ${json[ResultFs.matchId.name]}',
          myCustomObject: json,
          level: Level.SEVERE);
      throw FormatException('Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[ResultFs.resultId.name]}, matchId: ${json[ResultFs.matchId.name]}, json: $json');
    }

    try {
      return GameResult(
        id: GameResultId.fromString(json[ResultFs.resultId.name]),
        matchId: Date.parse(json[ResultFs.matchId.name])!,
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
      ResultFs.resultId.name: id.resultId,
      ResultFs.matchId.name: matchId.toYyyyMMdd(),
      'teamA': teamA!.toJson(),
      'teamB': teamB!.toJson(),
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
  final int points; // positive if team has won, negative if team has lost
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

  TeamResult copyFrom({
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
    MyUser? player1 = appState.getUserById(json[ResultFs.player1.name]);
    MyUser? player2 = appState.getUserById(json[ResultFs.player2.name]);
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
      points: json[ResultFs.points.name]??0,
      score: json[ResultFs.score.name]??0,
      preRanking1: json[ResultFs.preRanking1.name]??0,
      preRanking2: json[ResultFs.preRanking2.name]??0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ResultFs.player1.name: player1.id,
      ResultFs.player2.name: player2.id,
      ResultFs.points.name: points,
      ResultFs.score.name: score,
      ResultFs.preRanking1.name: preRanking1,
      ResultFs.preRanking2.name: preRanking2,
    };
  }

  @override
  String toString() {
    return 'TeamResult(player1: $player1, player2: $player2, points: $points, '
        'preRanking1: $preRanking1, preRanking2: $preRanking2, score: $score)';
  }

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
  final DateTime _dateTime;
  final String _userId;

  GameResultId({required String userId, DateTime? dateTime})
      : _userId = userId,
        _dateTime = dateTime ?? DateTime.now();

  factory GameResultId.fromString(String id) {
    try {
      final parts = id.split(fieldSeparator);
      final dateTime = DateTime.parse(parts[0]);
      final userId = parts[1];
      return GameResultId(dateTime: dateTime, userId: userId);
    } catch (e) {
      MyLog.log(_classString, 'Invalid ResultId format: $id \nError: ${e.toString()}');
      throw FormatException('ResultId formato Invalido: $id \nError: ${e.toString()}');
    }
  }

  String get resultId => '${_dateTime.toIso8601String()}$fieldSeparator$_userId';

  @override
  String toString() => '{${_dateTime.toIso8601String()},$_userId}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameResultId &&
          runtimeType == other.runtimeType &&
          _dateTime == other._dateTime &&
          _userId == other._userId;

  @override
  int get hashCode => _dateTime.hashCode ^ _userId.hashCode;
}
