import 'dart:core';

import 'package:simple_logger/simple_logger.dart';

import 'md_debug.dart';

final String _classString = '<md> UserMatchResult'.toLowerCase();

/// user fields in Firestore
enum UserMatchResultFs {
  userMatchResult,
  userId,
  matchId,
  resultId,
}

/// Represents a user in the application.
class UserMatchResult {
  String userId;
  String matchId;
  String? resultId;

  UserMatchResult({
    required this.userId,
    required this.matchId,
    this.resultId,
  });

  UserMatchResult copyWith({
    String? userId,
    String? matchId,
    String? resultId,
  }) {
    MyLog.log(_classString, 'copyWith', level: Level.INFO);
    return UserMatchResult(
      userId: userId ?? this.userId,
      matchId: matchId ?? this.matchId,
      resultId: resultId ?? this.resultId,
    );
  }

  void copyFrom(UserMatchResult other) {
    MyLog.log(_classString, 'copyFrom', level: Level.INFO);
    userId = other.userId;
    matchId = other.matchId;
    resultId = other.resultId;
  }

  factory UserMatchResult.fromJson(Map<String, dynamic> json) {
    return UserMatchResult(
      userId: json[UserMatchResultFs.userId.name] ?? '',
      matchId: json[UserMatchResultFs.matchId.name] ?? '',
      resultId: json[UserMatchResultFs.resultId.name],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      UserMatchResultFs.userId.name: userId,
      UserMatchResultFs.matchId.name: matchId,
      UserMatchResultFs.resultId.name: resultId,
    };
  }

  @override
  String toString() {
    return 'UserMatchResult{userId: $userId, matchId: $matchId, resultId: $resultId}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMatchResult &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          matchId == other.matchId &&
          resultId == other.resultId;

  @override
  int get hashCode => userId.hashCode ^ matchId.hashCode ^ resultId.hashCode;
}
