import 'dart:math';

import '../database/fields.dart';
import '../utilities/date.dart';
import '../utilities/misc.dart';
import 'debug.dart';

final String _classString = 'MyMatch'.toUpperCase();

enum PlayingState { playing, signedNotPlaying, reserve, unsigned }

const Map playingStateMap = {
  PlayingState.playing: '¡¡¡Juegas!!!',
  PlayingState.signedNotPlaying: 'Apuntado',
  PlayingState.reserve: 'Reserva',
  PlayingState.unsigned: 'No apuntado',
};

class MyMatch {
  Date date;
  final Set<String> players = {};
  final Set<String> courtNames = {};
  String comment;
  bool isOpen;

  MyMatch(
      {required this.date,
      this.comment = '',
      this.isOpen = false,
      Set<String>? players,
      Set<String>? courtNames}) {
    this.players.addAll(players ?? {});
    this.courtNames.addAll(courtNames ?? {});
  }

  bool isCourtInMatch(String court) => courtNames.contains(court);

  int getNumberOfFilledCourts() => min((players.length / 4).floor(), courtNames.length);

  int getNumberOfCourts() => courtNames.length;

  // null for all
  Set<String> getPlayers({PlayingState? state}) {
    if (state == null) return players;
    Map<String, PlayingState> map = getAllPlayingStates();
    Set<String> list = {};
    map.forEach((player, playerState) => playerState == state ? list.add(player) : null);
    return list;
  }

  /// return -1 if not found
  int getPlayerPosition(String userId) => players.toList().indexOf(userId);

  bool isInTheMatch(String userId) => players.contains(userId);

  bool isPlaying(String userId) => getPlayingState(userId) == PlayingState.playing;

  /// return position it was inserted [0 .. length-1]. -1 if already existed
  int insertPlayer(String player, {int position = -1}) {
    if (players.contains(player)) return -1;
    if (position < 0 || position >= players.length) {
      players.add(player);
      return players.length - 1;
    }
    List<String> allPlayers = players.toList()..insert(position, player);
    players.clear();
    players.addAll(allPlayers);
    return position;
  }

  /// Returns `true` if [player] was in the set, and `false` if not.
  bool removePlayer(String player) => players.remove(player);

  PlayingState getPlayingState(String player) {
    Map<String, PlayingState> map = getAllPlayingStates();
    PlayingState? playingState = map[player];
    if (playingState == null) {
      return PlayingState.unsigned;
    } else {
      return playingState;
    }
  }

  String getPlayingStateString(String player) => playingStateMap[getPlayingState(player)];

  Map<String, PlayingState> getAllPlayingStates() {
    Map<String, PlayingState> map = {};
    int numberOfFilledCourts = getNumberOfFilledCourts();
    for (int i = 0; i < players.length; i++) {
      if (i < numberOfFilledCourts * 4) {
        // the player is playing
        map[players.elementAt(i)] = PlayingState.playing;
      } else if (i < courtNames.length * 4) {
        // the player is waiting for the court to fill
        map[players.elementAt(i)] = PlayingState.signedNotPlaying;
      } else {
        // all available courts are full
        map[players.elementAt(i)] = PlayingState.reserve;
      }
    }
    return map;
  }

  /// list of who plays with who in this match
  List<int> getCouplesPlainList() => getRandomList(getNumberOfFilledCourts() * 4, date);

  /// true if they play together
  bool arePlayingTogether(String userId1, String userId2) {
    int posUser1 = getPlayerPosition(userId1);
    int posUser2 = getPlayerPosition(userId2);
    if (posUser1 != -1 &&
        posUser2 != -1 &&
        getPlayingState(userId1) == PlayingState.playing &&
        getPlayingState(userId2) == PlayingState.playing) {
      List<int> sortedList = getCouplesPlainList();
      for (int pos = 0; pos < sortedList.length; pos += 2) {
        if (sortedList[pos] == posUser1 && sortedList[pos + 1] == posUser2 ||
            sortedList[pos] == posUser2 && sortedList[pos + 1] == posUser1) {
          MyLog().log(_classString, '$date $userId1 played with $userId2 sorting=$sortedList',
              myCustomObject: players);
          return true;
        }
      }
    }
    return false;
  }

  @override
  String toString() {
    return ('($date,$isOpen,$courtNames,$players)');
  }

  static MyMatch fromJson(Map<String, dynamic> json) => MyMatch(
        date: Date.parse(json[DBFields.date.name]) ?? Date.ymd(1971),
        players: ((json[DBFields.players.name] ?? []).cast<String>()).toSet(),
        courtNames: ((json[DBFields.courtNames.name] ?? []).cast<String>()).toSet(),
        comment: json[DBFields.comment.name] ?? '',
        isOpen: json[DBFields.isOpen.name], // bool
      );

  Map<String, dynamic> toJson({bool core = true, bool matchPlayers = true}) => {
        DBFields.date.name: date.toYyyyMMdd(),
        if (matchPlayers) DBFields.players.name: players.toList(),
        if (core) DBFields.courtNames.name: courtNames.toList(),
        if (core) DBFields.comment.name: comment,
        if (core) DBFields.isOpen.name: isOpen, // bool
      };
}
