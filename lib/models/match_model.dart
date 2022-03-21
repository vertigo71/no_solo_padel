import 'dart:math';

import '../database/fields.dart';
import '../utilities/date.dart';

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
    map.forEach((_user, _state) => _state == state ? list.add(_user) : null);
    return list;
  }

  bool isInTheMatch(String userId) => players.contains(userId);

  /// true if it was inserted, false if already existed
  bool addPlayer(String player) => players.add(player);

  /// true if it was inserted, false if already existed
  bool insertPlayer(String player, {int position = -1}) {
    if (players.contains(player)) return false;
    if (position < 0) return addPlayer(player);
    int numPlayers = players.length;
    if (position > numPlayers) position = numPlayers;
    List<String> _players = players.toList();
    _players.insert(position, player);
    players.clear();
    players.addAll(_players);
    return true;
  }

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

  @override
  String toString() {
    return ('<$date,$isOpen,$courtNames,$players>');
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
