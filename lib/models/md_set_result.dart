import 'package:simple_logger/simple_logger.dart';

import '../interface/if_app_state.dart';
import 'md_date.dart';
import 'md_debug.dart';
import 'md_exception.dart';
import 'md_user.dart';

final String _classString = '<md> MyResult'.toLowerCase();

const String kFieldSeparator = '#';

// result fields in Firestore
enum SetResultFs {
  resultId,
  matchId,
  players,
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

/// Represents the outcome and details of a single set within a match.
///
/// This class focuses on the logical structure of a set result,
/// primarily holding information about the two teams (`teamA` and `teamB`).
///
/// **Firestore Data Modeling Note (allPlayers field):**
/// For efficient querying in Firestore, a 'allPlayers' field is added during
/// serialization (in `toJson()`). This field contains a list of all player IDs
/// involved in the set result.
///
/// This 'allPlayers' field is *not* a member of the `SetResult` class itself
/// because it serves as a denormalized index primarily for database queries
/// (e.g., finding all sets a specific player participated in using `array-contains`).
/// It's a storage optimization rather than a core property of the `SetResult`
/// domain model, as player information is already accessible via `teamA` and `teamB`.
class SetResult {
  final SetResultId id;
  final Date matchId;
  final TeamResult? teamA;
  final TeamResult? teamB;

  SetResult({required String userId, required this.matchId, this.teamA, this.teamB})
      : id = SetResultId(matchId: matchId, userId: userId);

  SetResult._({required this.id, required this.matchId, this.teamA, this.teamB});

  bool _checkResultOk() {
    if (teamA == null || teamB == null || teamA!.score == teamB!.score) {
      MyLog.log(_classString, 'ERROR: wrong result Team A = $teamA Team B = $teamB', level: Level.SEVERE);
      return false;
    }
    return true;
  }

  /// returns the score [in favor, against] of the player in the set
  /// returns null if the player is not in the set
  List<int>? getScores(MyUser player) {
    if (teamA?.isPlayerInTeam(player) ?? false) return [teamA!.score, teamB!.score];
    if (teamB?.isPlayerInTeam(player) ?? false) return [teamB!.score, teamA!.score];
    return null;
  }

  /// returns the points of the player in the set
  /// returns null if the player is not in the set
  int? getPoints(MyUser player) {
    if (teamA?.isPlayerInTeam(player) ?? false) return teamA!.points;
    if (teamB?.isPlayerInTeam(player) ?? false) return teamB!.points;
    return null;
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

  bool playerIsInSetResult(MyUser player) =>
      (teamA?.isPlayerInTeam(player) ?? false) || (teamB?.isPlayerInTeam(player) ?? false);

  bool playerHasWon(MyUser player) {
    if (teamA?.isPlayerInTeam(player) ?? false) return teamA!.score > (teamB?.score ?? 0);
    if (teamB?.isPlayerInTeam(player) ?? false) return teamB!.score > (teamA?.score ?? 0);
    return false;
  }

  SetResult copyWith({
    SetResultId? id,
    Date? matchId,
    TeamResult? teamA,
    TeamResult? teamB,
  }) {
    return SetResult._(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
    );
  }

  factory SetResult.fromJson(Map<String, dynamic> json, final AppState appState) {
    if (json[SetResultFs.resultId.name] == null || json[SetResultFs.matchId.name] == null) {
      MyLog.log(
          _classString,
          'Formato del resultado incorrecto. \nresultId or matchId son nulos\n'
          'resultId: ${json[SetResultFs.resultId.name]}, matchId: ${json[SetResultFs.matchId.name]}',
          myCustomObject: json,
          level: Level.SEVERE);
      throw MyException(
          'Formato del resultado incorrecto. \n'
          'resultId or matchId son nulos\n'
          'resultId: ${json[SetResultFs.resultId.name]}\n'
          'matchId: ${json[SetResultFs.matchId.name]}\n'
          'json: $json',
          level: Level.SEVERE);
    }

    try {
      return SetResult._(
        id: SetResultId.fromString(json[SetResultFs.resultId.name]),
        matchId: Date.parse(json[SetResultFs.matchId.name])!,
        teamA: json.containsKey('teamA') ? TeamResult.fromJson(json['teamA'], appState) : null,
        teamB: json.containsKey('teamB') ? TeamResult.fromJson(json['teamB'], appState) : null,
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creando el resultado de la base de datos: \nError: ${e.toString()}',
          level: Level.WARNING);
      throw MyException('Error creando el resultado de la base de datos', e: e, level: Level.WARNING);
    }
  }

  Map<String, dynamic> toJson() {
    if (id.resultId == '') {
      MyLog.log(
          _classString,
          'Identificador del resultado incorrecto al grabar en la BD. \n'
          'resultId: ${id.resultId}',
          level: Level.SEVERE);
      throw MyException(
          'Identificador del resultado incorrecto al grabar en la BD. \n'
          'resultId: ${id.resultId}',
          level: Level.SEVERE);
    }
    return {
      SetResultFs.resultId.name: id.resultId,
      SetResultFs.matchId.name: matchId.toYyyyMmDd(),
      SetResultFs.players.name: [teamA?.player1.id, teamA?.player2.id, teamB?.player1.id, teamB?.player2.id],
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
      other is SetResult &&
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
    MyUser? player1 = appState.getUserById(json[SetResultFs.player1.name]);
    MyUser? player2 = appState.getUserById(json[SetResultFs.player2.name]);
    if (player1 == null || player2 == null) {
      MyLog.log(
          _classString,
          'Error leyendo la base de datos. \n'
          'Los jugadores ($player1, $player2) no existen en \n',
          myCustomObject: json,
          level: Level.SEVERE);
      throw MyException(
          'Error leyendo la base de datos. \n'
          'Los jugadores ($player1, $player2) no existen en \n'
          '$json',
          level: Level.SEVERE);
    }

    return TeamResult(
      player1: player1,
      player2: player2,
      points: json[SetResultFs.points.name] ?? 0,
      score: json[SetResultFs.score.name] ?? 0,
      preRanking1: json[SetResultFs.preRanking1.name] ?? 0,
      preRanking2: json[SetResultFs.preRanking2.name] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      SetResultFs.player1.name: player1.id,
      SetResultFs.player2.name: player2.id,
      SetResultFs.points.name: points,
      SetResultFs.score.name: score,
      SetResultFs.preRanking1.name: preRanking1,
      SetResultFs.preRanking2.name: preRanking2,
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

class SetResultId {
  final Date _matchId;
  final DateTime _dateTime;
  final String _userId;

  SetResultId({required Date matchId, required String userId, DateTime? dateTime})
      : _matchId = matchId,
        _dateTime = dateTime ?? DateTime.now(),
        _userId = userId;

  factory SetResultId.fromString(String id) {
    try {
      final parts = id.split(kFieldSeparator);
      final matchId = Date.parse(parts[0])!;
      final dateTime = DateTime.parse(parts[1]);
      final userId = parts[2];
      return SetResultId(matchId: matchId, dateTime: dateTime, userId: userId);
    } catch (e) {
      MyLog.log(_classString, 'Invalid ResultId format: $id \nError: ${e.toString()}', level: Level.WARNING);
      throw MyException('ResultId formato Invalido: $id', e: e, level: Level.WARNING);
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
      other is SetResultId &&
          runtimeType == other.runtimeType &&
          _dateTime == other._dateTime &&
          _matchId == other._matchId &&
          _userId == other._userId;

  @override
  int get hashCode => _dateTime.hashCode ^ _userId.hashCode ^ _matchId.hashCode;
}
