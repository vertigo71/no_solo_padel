import 'dart:math';


import '../database/fields.dart';
import '../utilities/date.dart';
import '../utilities/type_conversion.dart';
import 'user_model.dart';

enum PlayingState { playing, signedNotPlaying, reserve, unsigned }

const Map playingStateMap = {
  PlayingState.playing: '¡¡¡Juegas!!!',
  PlayingState.signedNotPlaying: 'Apuntado',
  PlayingState.reserve: 'Reserva',
  PlayingState.unsigned: 'No apuntado',
};

class MyMatch {
  Date date;
  final Set<MyUser> players = {};
  final Set<String> courtNames = {};
  String comment;
  bool isOpen;

  MyMatch(
      {required this.date,
      this.comment = '',
      this.isOpen = false,
      Set<MyUser>? players,
      Set<String>? courtNames}) {
    this.players.addAll(players ?? {});
    this.courtNames.addAll(courtNames ?? {});
  }

  bool isCourtInMatch(String court) => courtNames.contains(court);

  int getNumberOfFilledCourts() => min((players.length / 4).floor(), courtNames.length);

  int getNumberOfCourts() => courtNames.length;

  Set<MyUser> getPlayers({PlayingState? state}) {
    if (state == null) return players;
    Map<MyUser, PlayingState> map = getAllPlayingStates();
    Set<MyUser> list = {};

    map.forEach((_user, _state) => _state == state ? list.add(_user) : null);
    return list;
  }

  bool isInTheMatch(MyUser user) {
    for (var player in players) {
      if (player == user) return true;
    }
    return false;
  }

  MyUser? getPlayerByName(String name) {
    for (var player in players) {
      if (player.name == name) return player;
    }
    return null;
  }

  MyUser? getPlayerById(String id) {
    for (var player in players) {
      if (player.userId == id) return player;
    }
    return null;
  }

  MyUser? getPlayerByEmail(String email) {
    for (var player in players) {
      if (player.email == email) return player;
    }
    return null;
  }

  bool addPlayer(MyUser player) {
    return players.add(player);
  }

  bool insertPlayer(MyUser player, {int position = -1}) {
    if (position < 0) return addPlayer(player);
    int numPlayers = players.length;
    if (position > numPlayers) position = numPlayers;
    List<MyUser> _players = players.toList();
    _players.insert(position, player);
    players.clear();
    players.addAll(_players);
    if (numPlayers == players.length) return false;
    return true;
  }

  bool removePlayer(MyUser player) {
    return players.remove(player);
  }

  void addPlayerIfNameNotExists(MyUser user) {
    MyUser? _user = getPlayerByName(user.name);
    if (_user == null) {
      players.add(user);
    }
  }

  void addPlayerToMatch(MyUser user) {
    MyUser? _alreadyPlaying = getPlayerById(user.userId);
    if (_alreadyPlaying == null) {
      players.add(user);
    }
  }

  void deletePlayerIfNameExists(String name) {
    MyUser? _user = getPlayerByName(name);
    if (_user != null) {
      players.remove(_user);
    }
  }

  PlayingState getPlayingState(MyUser user) {
    Map<MyUser, PlayingState> map = getAllPlayingStates();
    PlayingState? playingState = map[user];
    if (playingState == null) {
      return PlayingState.unsigned;
    } else {
      return playingState;
    }
  }

  String getPlayingStateString(MyUser user) {
    return playingStateMap[getPlayingState(user)];
  }

  Map<MyUser, PlayingState> getAllPlayingStates() {
    Map<MyUser, PlayingState> map = {};

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
        date: json[DBFields.date.name] ?? '',
        players: {}, //TODO: to do
        courtNames: ((json[DBFields.courtNames.name] ?? []) as List<String>).toSet(),
        comment: json[DBFields.comment.name] ?? '',
        isOpen: strToBool(json[DBFields.isOpen.name]),
      );

  Map<String, dynamic> toJson() => {
        DBFields.date.name: date,
        DBFields.players.name: players.map((p) => p.userId).toList(),
        DBFields.courtNames.name: courtNames.toList(),
        DBFields.comment.name: comment, // int
        DBFields.isOpen.name: boolToStr(isOpen), // String
      };
}
