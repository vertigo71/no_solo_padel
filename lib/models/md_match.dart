import 'dart:math';
import 'package:collection/collection.dart';

import '../interface/if_app_state.dart';
import 'md_date.dart';
import '../utilities/ut_misc.dart';
import '../utilities/ut_list_view.dart';
import 'md_debug.dart';
import 'md_user.dart';

final String _classString = '<md> MyMatch'.toLowerCase();

enum PlayingState {
  playing('¡¡¡Juegas!!!'),
  signedNotPlaying('Apuntado'),
  reserve('Reserva'),
  unsigned('No apuntado');

  final String displayText;

  const PlayingState(this.displayText);
}

// match fields in Firestore
enum MatchFs { matches, date, comment, isOpen, courtNames, players, pairingType }

enum MatchPairingType {
  ranking('Ranking'),
  palindromic('Capicúa'),
  random('Aleatorio');

  final String label;

  const MatchPairingType(this.label);
}

class MyMatch {
  Date id;
  final List<MyUser> _players = [];
  final List<String> _courtNames = [];
  String comment;
  bool isOpen;
  MatchPairingType pairingType;

  MyMatch(
      {required this.id,
      required this.comment, // set default comment
      this.isOpen = false,
      this.pairingType = MatchPairingType.ranking,
      List<MyUser>? players,
      List<String>? courtNames}) {
    _players.addAll(players ?? []);
    _courtNames.addAll(courtNames ?? []);
  }

  MyListView<MyUser> get players => MyListView(_players);

  MyListView<String> get courtNames => MyListView(_courtNames);

  List<MyUser> get copyOfPlayers => List.from(_players);

  List<String> get copyOfCourtNames => List.from(_courtNames);

  // methods por _players
  void addPlayer(MyUser player) {
    if (!_players.contains(player)) _players.add(player);
  }

  void addAllPlayers(Iterable<MyUser> newPlayers) {
    for (final player in newPlayers) {
      addPlayer(player);
    }
  }

  bool removePlayer(MyUser player) {
    return _players.remove(player);
  }

  void clearPlayers() {
    _players.clear();
  }

  // Methods for _courtNames
  void addCourtName(String courtName) {
    if (!_courtNames.contains(courtName)) {
      _courtNames.add(courtName);
    }
  }

  void addAllCourtNames(Iterable<String> newCourtNames) {
    for (final courtName in newCourtNames) {
      addCourtName(courtName);
    }
  }

  bool removeCourtName(String courtName) {
    return _courtNames.remove(courtName);
  }

  void clearCourtNames() {
    _courtNames.clear();
  }

  MyMatch copyWith({
    Date? id,
    List<MyUser>? players,
    List<String>? courtNames,
    String? comment,
    bool? isOpen,
    MatchPairingType? pairingType,
  }) {
    return MyMatch(
      id: id ?? this.id,
      players: players ?? _players,
      courtNames: courtNames ?? _courtNames,
      comment: comment ?? this.comment,
      isOpen: isOpen ?? this.isOpen,
      pairingType: pairingType ?? this.pairingType,
    );
  }

  factory MyMatch.fromJson(Map<String, dynamic> json, AppState appState) {
    // .cast<String>() is a method that attempts to create a new List<String> view of an existing list.
    final playerIds = json[MatchFs.players.name]?.cast<String>() ?? [];
    final players = <MyUser>[];

    for (final playerId in playerIds) {
      final user = appState.getUserById(playerId);
      if (user != null) {
        players.add(user);
      }
    }

    return MyMatch(
      id: Date.parse(json[MatchFs.date.name]) ?? Date.ymd(1971),
      players: players,
      courtNames: json[MatchFs.courtNames.name]?.cast<String>() ?? [],
      comment: json[MatchFs.comment.name] ?? '',
      isOpen: json[MatchFs.isOpen.name] ?? false,
      pairingType: MatchPairingType.values[json[MatchFs.pairingType.name] ?? 0],
    );
  }

  Map<String, dynamic> toJson({bool core = true, bool matchPlayers = true}) => {
        MatchFs.date.name: id.toYyyyMmDd(),
        if (matchPlayers) MatchFs.players.name: _players.map((user) => user.id).toList(),
        if (core) MatchFs.courtNames.name: _courtNames.toList(),
        if (core) MatchFs.comment.name: comment,
        if (core) MatchFs.isOpen.name: isOpen, // bool
        if (core) MatchFs.pairingType.name: pairingType.index, // int
      };

  bool isCourtInMatch(String court) => _courtNames.contains(court);

  int get numberOfFilledCourts => min((_players.length / 4).floor(), numberOfCourts);

  int get numberOfCourts => _courtNames.length;

  /// Retrieves a list of players, optionally filtered by their playing state.
  ///
  /// If [state] is null, this function returns all players. Otherwise, it returns
  /// a list of players whose playing state matches the provided [state].
  ///
  /// The playing states are retrieved from the [getAllPlayingStates] map, which
  /// associates each player ([MyUser]) with their corresponding [PlayingState].
  ///
  /// [state]: The playing state to filter by. If null, all players are returned.
  ///
  /// Returns: A list of [MyUser] objects, either all players or those matching the
  ///          specified playing state.
  List<MyUser> getPlayers({PlayingState? state}) {
    if (state == null) return copyOfPlayers;
    return getAllPlayingStates()
        .entries
        .where((entry) => entry.value == state) // Filter by playing state
        .map((entry) => entry.key) // Extract the player
        .toList(); // Convert to list
  }

  /// Generates a map that associates each player ([MyUser]) in the [_players] list with their corresponding
  /// [PlayingState]. The state is determined based on the player's position in the list relative to the number
  /// of filled courts and the total number of available court slots.
  ///
  /// - Players within the first [getnumberOfFilledCourts * 4] positions are assigned [PlayingState.playing].
  /// - Players within the next [_courtNames.length * 4] positions are assigned [PlayingState.signedNotPlaying].
  /// - Remaining players are assigned [PlayingState.reserve].
  ///
  /// This function relies on the [getnumberOfFilledCourts] and [_courtNames] properties to determine the
  /// appropriate playing states.
  ///
  /// Returns: A [Map<MyUser, PlayingState>] containing the playing state of each player.
  Map<MyUser, PlayingState> getAllPlayingStates() {
    final int numberOfPlayingPlayers = numberOfFilledCourts * 4;
    final int numberOfCourtCapacityInPlayers = _courtNames.length * 4;

    final Map<MyUser, PlayingState> playerStates = {};

    for (int i = 0; i < _players.length; i++) {
      if (i < numberOfPlayingPlayers) {
        playerStates[_players[i]] = PlayingState.playing;
      } else if (i < numberOfCourtCapacityInPlayers) {
        playerStates[_players[i]] = PlayingState.signedNotPlaying;
      } else {
        playerStates[_players[i]] = PlayingState.reserve;
      }
    }

    return playerStates;
  }

  PlayingState getPlayingState(MyUser player) {
    Map<MyUser, PlayingState> map = getAllPlayingStates();
    PlayingState? playingState = map[player];
    if (playingState == null) {
      return PlayingState.unsigned;
    } else {
      return playingState;
    }
  }

  String getPlayingStateString(MyUser player) => getPlayingState(player).displayText;

  /// return -1 if not found
  int getPlayerPosition(MyUser player) => _players.indexOf(player);

  bool isInTheMatch(MyUser player) => _players.contains(player);

  bool isPlaying(MyUser player) => getPlayingState(player) == PlayingState.playing;

  /// Inserts a player into the player list at the specified position.
  ///
  /// If the player already exists in the list, it returns -1.
  /// If the [position] is invalid (less than 0 or greater than or equal to the
  /// list's length), the player is added to the end of the list.
  ///
  /// Returns: The index at which the player was inserted, or -1 if the player
  ///          already exists.
  int insertPlayer(MyUser player, {int position = -1}) {
    if (_players.contains(player)) {
      // uses operator==
      return -1;
    }

    if (position < 0 || position >= _players.length) {
      _players.add(player);
      return _players.length - 1;
    }

    _players.insert(position, player); // Directly insert into _players.
    return position;
  }

  /// Generates a map representing player positions to courts for the match.
  ///
  /// This function calculates player pairings based on the number of filled courts
  /// and assigns player positions to each court. Each court is represented as a
  /// key-value pair in the returned map, where the key is the court number
  /// (starting from 0) and the value is a list of four integer positions
  /// representing the players assigned to that court.
  ///
  /// The player assignments are determined using a pseudo-random list of indices
  /// generated by the [getRandomList] function, which uses the match ID ([id])
  /// as a seed to ensure consistent results for the same match.
  ///
  /// Returns:
  ///   A [Map<int, List<int>>] where:
  ///     - The keys are court numbers (0, 1, 2, ...).
  ///     - The values are lists of four integer positions representing the players
  ///       assigned to each court.
  Map<int, List<int>> getRandomPlayerPairs() {
    int numFilledCourts = numberOfFilledCourts;
    List<int> randomIndexes = getRandomList(numFilledCourts * 4, id);

    Map<int, List<int>> courtPlayers = {};

    for (int i = 0; i < numFilledCourts; i++) {
      courtPlayers[i] = [
        randomIndexes[i * 4],
        randomIndexes[i * 4 + 1],
        randomIndexes[i * 4 + 2],
        randomIndexes[i * 4 + 3],
      ];
    }

    return courtPlayers;
  }

  Map<int, List<int>> getRankingPlayerPairs() {
    int numFilledCourts = numberOfFilledCourts;
    // use cascade (..) operator as sort returns void
    List<MyUser> sortedMatchPlayers = getPlayers(state: PlayingState.playing)
      ..sort(getMyUserComparator(UsersSortBy.ranking));
    MyLog.log(
        _classString,
        'getRankingPlayerPairs numOfCourts=$numFilledCourts, '
        'sortedMatchPlayers=$sortedMatchPlayers');
    Map<int, List<int>> courtPlayers = {};

    for (int i = 0; i < numFilledCourts; i++) {
      courtPlayers[i] = [
        _players.indexOf(sortedMatchPlayers[i * 4]),
        _players.indexOf(sortedMatchPlayers[i * 4 + 3]),
        _players.indexOf(sortedMatchPlayers[i * 4 + 1]),
        _players.indexOf(sortedMatchPlayers[i * 4 + 2]),
      ];
    }

    return courtPlayers;
  }

  Map<int, List<int>> getPalindromicPlayerPairs() {
    int numFilledCourts = numberOfFilledCourts;
    // use cascade (..) operator as sort returns void
    List<MyUser> sortedMatchPlayers = getPlayers(state: PlayingState.playing)
      ..sort(getMyUserComparator(UsersSortBy.ranking));
    MyLog.log(
        _classString, 'getRankingPlayerPairs numOfCourts=$numFilledCourts, sortedMatchPlayers=$sortedMatchPlayers');
    Map<int, List<int>> courtPlayers = {};

    for (int i = 0; i < numFilledCourts; i++) {
      courtPlayers[i] = [
        _players.indexOf(sortedMatchPlayers[i * 2]),
        _players.indexOf(sortedMatchPlayers[4 * numFilledCourts - 1 - i * 2]),
        _players.indexOf(sortedMatchPlayers[i * 2 + 1]),
        _players.indexOf(sortedMatchPlayers[4 * numFilledCourts - 2 - i * 2]),
      ];
    }

    return courtPlayers;
  }

  @override
  String toString() => ('($id,open=$isOpen,courts=$_courtNames,names=$_players,comment=$comment)');

  // must compare all fields
  // match_notifier requires that in _notifyIfChanged method
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals; // Use collection package
    return other is MyMatch &&
        id == other.id &&
        listEquals(_players, other._players) && // Compare lists using collection package
        listEquals(_courtNames, other._courtNames) && // Compare lists using collection package
        comment == other.comment &&
        isOpen == other.isOpen &&
        pairingType == other.pairingType;
  }

  @override
  int get hashCode => Object.hash(
        id,
        const DeepCollectionEquality().hash(_players), // Hash lists using collection package
        const DeepCollectionEquality().hash(_courtNames), // Hash lists using collection package
        comment,
        isOpen,
        pairingType,
      );
}
