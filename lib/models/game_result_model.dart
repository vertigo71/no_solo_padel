import 'package:simple_logger/simple_logger.dart';

import '../database/fields.dart';
import '../interface/app_state.dart';
import '../utilities/date.dart';
import 'debug.dart';
import 'user_model.dart';

final String _classString = '<md> MyResult'.toLowerCase();

const String fieldSeparator = '#';

class GameResult {
  ResultId id;
  Date matchId;
  TeamResult teamA;
  TeamResult teamB;

  GameResult({required this.id, required this.matchId, required this.teamA, required this.teamB});

  GameResult copyFrom({
    ResultId? id,
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
    if (json[fName(Fields.resultId)] == null || json[fName(Fields.matchId)] == null) {
      MyLog.log(
          _classString,
          'Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[fName(Fields.resultId)]}, matchId: ${json[fName(Fields.matchId)]}',
          myCustomObject: json,
          level: Level.SEVERE);
      throw FormatException('Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[fName(Fields.resultId)]}, matchId: ${json[fName(Fields.matchId)]}, json: $json');
    }

    try {
      return GameResult(
        id: ResultId.fromString(json[fName(Fields.resultId)]),
        matchId: Date.parse(json[fName(Fields.matchId)])!,
        teamA: TeamResult.fromJson(json['teamA'], appState),
        teamB: TeamResult.fromJson(json['teamB'], appState),
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creando el resultado de la base de datos: \nError: $e');
      throw Exception('Error creando el resultado de la base de datos: \nError: $e');
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
      fName(Fields.resultId): id.resultId,
      fName(Fields.matchId): matchId.toYyyyMMdd(),
      'teamA': teamA.toJson(),
      'teamB': teamB.toJson(),
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
  final int preRanking1; // ranking of player1 before the match
  final int preRanking2; // ranking of player2 before the match
  final int score;

  TeamResult({
    required this.player1,
    required this.player2,
    required this.points,
    required this.preRanking1,
    required this.preRanking2,
    required this.score,
  });

  TeamResult copyFrom({
    MyUser? player1,
    MyUser? player2,
    int? points,
    int? preRanking1,
    int? preRanking2,
    int? score,
  }) {
    return TeamResult(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      points: points ?? this.points,
      preRanking1: preRanking1 ?? this.preRanking1,
      preRanking2: preRanking2 ?? this.preRanking2,
      score: score ?? this.score,
    );
  }

  factory TeamResult.fromJson(Map<String, dynamic> json, final AppState appState) {
    MyUser? player1 = appState.getUserById(json[fName(Fields.player1)]);
    MyUser? player2 = appState.getUserById(json[fName(Fields.player2)]);
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
      points: json[fName(Fields.points)],
      preRanking1: json[fName(Fields.preRanking1)],
      preRanking2: json[fName(Fields.preRanking2)],
      score: json[fName(Fields.score)],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      fName(Fields.player1): player1.id,
      fName(Fields.player2): player2.id,
      fName(Fields.points): points,
      fName(Fields.preRanking1): preRanking1,
      fName(Fields.preRanking2): preRanking2,
      fName(Fields.score): score,
    };
  }

  @override
  String toString() {
    return 'TeamResult(player1: $player1, player2: $player2, points: $points, preRanking1: $preRanking1, preRanking2: $preRanking2, score: $score)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamResult &&
          runtimeType == other.runtimeType &&
          player1 == other.player1 &&
          player2 == other.player2 &&
          points == other.points &&
          preRanking1 == other.preRanking1 &&
          preRanking2 == other.preRanking2 &&
          score == other.score;

  @override
  int get hashCode =>
      player1.hashCode ^
      player2.hashCode ^
      points.hashCode ^
      preRanking1.hashCode ^
      preRanking2.hashCode ^
      score.hashCode;
}

class ResultId {
  final DateTime dateTime;
  final String userId;

  ResultId(this.dateTime, this.userId);

  factory ResultId.fromString(String id) {
    try {
      final parts = id.split(fieldSeparator);
      final dateTime = DateTime.parse(parts[0]);
      final userId = parts[1];
      return ResultId(dateTime, userId);
    } catch (e) {
      MyLog.log(_classString, 'Invalid ResultId format: $id \nError: $e');
      throw FormatException('ResultId formato Invalido: $id \nError: $e');
    }
  }

  String get resultId => toString();

  @override
  String toString() => '${dateTime.toIso8601String()}$fieldSeparator$userId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultId && runtimeType == other.runtimeType && dateTime == other.dateTime && userId == other.userId;

  @override
  int get hashCode => dateTime.hashCode ^ userId.hashCode;
}
