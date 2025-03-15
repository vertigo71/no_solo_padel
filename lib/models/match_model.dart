import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:simple_logger/simple_logger.dart';

import '../database/fields.dart';
import '../interface/app_state.dart';
import '../utilities/date.dart';
import '../utilities/misc.dart';
import 'debug.dart';
import 'user_model.dart';

final String _classString = '<md> MyMatch'.toLowerCase();

enum PlayingState { playing, signedNotPlaying, reserve, unsigned }

const Map playingStateMap = {
  PlayingState.playing: '¡¡¡Juegas!!!',
  PlayingState.signedNotPlaying: 'Apuntado',
  PlayingState.reserve: 'Reserva',
  PlayingState.unsigned: 'No apuntado',
};

class MyMatch {
  Date id;
  final List<MyUser> players = [];
  final List<String> courtNames = [];
  String comment;
  bool isOpen;

  MyMatch({required this.id, this.comment = '', this.isOpen = false, List<MyUser>? players, List<String>? courtNames}) {
    this.players.addAll(players ?? {});
    this.courtNames.addAll(courtNames ?? {});
  }

  factory MyMatch.fromJson(Map<String, dynamic> json, AppState appState) {
    final playerIds = List<String>.from(json[DBFields.players.name] ?? []);
    final players = <MyUser>[];

    for (final playerId in playerIds) {
      final user = appState.getUserById(playerId);
      if (user != null) {
        players.add(user);
      }
    }

    return MyMatch(
      id: Date.parse(json[DBFields.date.name]) ?? Date.ymd(1971),
      players: players,
      courtNames: List<String>.from(json[DBFields.courtNames.name] ?? []),
      comment: json[DBFields.comment.name] ?? '',
      isOpen: json[DBFields.isOpen.name] ?? false,
    );
  }

  factory MyMatch.fromJsonString(String jsonString, AppState appState) {
    // Make jsonString nullable
    try {
      return MyMatch.fromJson(jsonDecode(jsonString), appState);
    } catch (e) {
      MyLog.log(_classString, 'fromJsonString: Error decoding JSON: $e', level: Level.SEVERE);
      throw Exception('Error: no se ha podido acceder al partido\n$e');
    }
  }

  MyMatch copyWith({
    Date? id,
    List<MyUser>? players,
    List<String>? courtNames,
    String? comment,
    bool? isOpen,
  }) {
    return MyMatch(
      id: id ?? this.id,
      players: players ?? List.from(this.players),
      courtNames: courtNames ?? List.from(this.courtNames),
      comment: comment ?? this.comment,
      isOpen: isOpen ?? this.isOpen,
    );
  }

  bool isCourtInMatch(String court) => courtNames.contains(court);

  int getNumberOfFilledCourts() => min((players.length / 4).floor(), courtNames.length);

  int getNumberOfCourts() => courtNames.length;

  // null for all
  List<MyUser> getPlayers({PlayingState? state}) {
    if (state == null) return players;
    Map<MyUser, PlayingState> map = getAllPlayingStates();
    List<MyUser> list = [];
    map.forEach((player, playerState) => playerState == state ? list.add(player) : null);
    return list;
  }

  /// return -1 if not found
  int getPlayerPosition(MyUser user) => players.toList().indexOf(user);

  bool isInTheMatch(MyUser player) => players.contains(player);

  bool isPlaying(MyUser player) => getPlayingState(player) == PlayingState.playing;

  /// return position it was inserted [0 .. length-1]. -1 if already existed
  int insertPlayer(MyUser player, {int position = -1}) {
    if (players.contains(player)) return -1;
    if (position < 0 || position >= players.length) {
      players.add(player);
      return players.length - 1;
    }
    List<MyUser> allPlayers = players.toList()..insert(position, player);
    players.clear();
    players.addAll(allPlayers);
    return position;
  }

  /// Returns `true` if [player] was in the list, and `false` if not.
  bool removePlayer(MyUser player) => players.remove(player);

  PlayingState getPlayingState(MyUser player) {
    Map<MyUser, PlayingState> map = getAllPlayingStates();
    PlayingState? playingState = map[player];
    if (playingState == null) {
      return PlayingState.unsigned;
    } else {
      return playingState;
    }
  }

  String getPlayingStateString(MyUser player) => playingStateMap[getPlayingState(player)];

  Map<MyUser, PlayingState> getAllPlayingStates() {
    Map<MyUser, PlayingState> map = {};
    int numberOfFilledCourts = getNumberOfFilledCourts();
    for (int i = 0; i < players.length; i++) {
      if (i < numberOfFilledCourts * 4) {
        // the player is playing
        map[players[i]] = PlayingState.playing;
      } else if (i < courtNames.length * 4) {
        // the player is waiting for the court to fill
        map[players[i]] = PlayingState.signedNotPlaying;
      } else {
        // all available courts are full
        map[players[i]] = PlayingState.reserve;
      }
    }
    return map;
  }

  /// Generates a random list of player pairs for the match.
  ///
  /// The returned list `c` follows this format:
  /// - `players[c[0]]` plays with `players[c[1]]`
  /// - `players[c[2]]` plays with `players[c[3]]`
  /// - And so on...
  ///
  /// The number of pairs is based on the number of filled courts.
  /// Each court has 4 players, so the total number of players is:
  /// `getNumberOfFilledCourts() * 4`.
  ///
  /// Returns a list of integers where each pair of indices represents teammates.
  List<int> getRandomPlayerPairs() => getRandomList(getNumberOfFilledCourts() * 4, id);

  /// true if they play together in this match
  bool arePlayingTogether(MyUser user1, MyUser user2) {
    int posUser1 = getPlayerPosition(user1);
    int posUser2 = getPlayerPosition(user2);
    if (posUser1 != -1 &&
        posUser2 != -1 &&
        getPlayingState(user1) == PlayingState.playing &&
        getPlayingState(user2) == PlayingState.playing) {
      List<int> sortedList = getRandomPlayerPairs();
      for (int pos = 0; pos < sortedList.length; pos += 2) {
        if (sortedList[pos] == posUser1 && sortedList[pos + 1] == posUser2 ||
            sortedList[pos] == posUser2 && sortedList[pos + 1] == posUser1) {
          MyLog.log(_classString, 'arePlayingTogether $id $user1 played with $user2 sorting=$sortedList',
              myCustomObject: players, indent: true);
          return true;
        }
      }
    }
    return false;
  }

  @override
  String toString() => ('($id,open=$isOpen,courts=$courtNames,names=$players)');

  Map<String, dynamic> toJson({bool core = true, bool matchPlayers = true}) => {
        DBFields.date.name: id.toYyyyMMdd(),
        if (matchPlayers) DBFields.players.name: players.map((user) => user.id).toList(),
        if (core) DBFields.courtNames.name: courtNames.toList(),
        if (core) DBFields.comment.name: comment,
        if (core) DBFields.isOpen.name: isOpen, // bool
      };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals; // Use collection package
    return other is MyMatch &&
        id == other.id &&
        listEquals(players, other.players) && // Compare lists using collection package
        listEquals(courtNames, other.courtNames) && // Compare lists using collection package
        comment == other.comment &&
        isOpen == other.isOpen;
  }

  @override
  int get hashCode => Object.hash(
        id,
        const DeepCollectionEquality().hash(players), // Hash lists using collection package
        const DeepCollectionEquality().hash(courtNames), // Hash lists using collection package
        comment,
        isOpen,
      );
}
