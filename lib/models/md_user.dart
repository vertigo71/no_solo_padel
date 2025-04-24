import 'package:collection/collection.dart';
import 'package:simple_logger/simple_logger.dart';
import 'dart:core';

import '../utilities/ut_list_view.dart';
import '../utilities/ut_misc.dart';
import 'md_date.dart';
import 'md_debug.dart';

final String _classString = '<md> MyUser'.toLowerCase();

/// Enum representing the types of users in the application.
enum UserType {
  basic('Básico'), // Basic user type.
  admin('Administrador'), // Administrator user type.
  superuser('Super usuario'), // Superuser user type.
  ;

  // The display name of the user type.
  final String displayName;

  // Constructor for UserType enum.
  const UserType(this.displayName);
}

/// user fields in Firestore
enum UserFs {
  users,
  userId,
  name,
  emergencyInfo,
  email,
  userType,
  lastLogin,
  loginCount,
  avatarUrl,
  rankingPos,
  avatars,
  isActive,
  matchIds,
}

/// users sort order
enum UsersSortBy {
  ranking,
  name,
}

/// Represents a user in the application.
class MyUser {
  /// Suffix added to user emails.
  static const String kEmailSuffix = '@nsp.com';

  String id;
  String name;
  String emergencyInfo;
  String _email;
  UserType userType;
  Date? lastLogin;
  int loginCount;
  String? avatarUrl;
  int _rankingPos;
  bool _isActive;
  final List<String> _matchIds = [];

  factory MyUser({
    // Public factory constructor
    required String id,
    required String name,
    required String email,
    String emergencyInfo = '',
    UserType userType = UserType.basic,
    Date? lastLogin,
    int loginCount = 0,
    String? avatarUrl,
    int rankingPos = 0,
  }) {
    return MyUser._(
      id: id,
      name: name,
      emergencyInfo: emergencyInfo,
      email: email,
      userType: userType,
      lastLogin: lastLogin,
      loginCount: loginCount,
      avatarUrl: avatarUrl,
      rankingPos: rankingPos,
    );
  }

  /// Private Constructor for MyUser class.
  MyUser._({
    this.id = '',
    this.name = '',
    this.emergencyInfo = '',
    String email = '',
    this.userType = UserType.basic,
    this.lastLogin,
    this.loginCount = 0,
    this.avatarUrl,
    int rankingPos = 0,
    bool isActive = false,
    List<String>? matchIds,
  })  : _rankingPos = rankingPos,
        _isActive = isActive,
        _email = email.toLowerCase() {
    _matchIds.addAll(matchIds ?? []);
  }

  // methods por _rankingPos
  int get rankingPos => _rankingPos;

  set rankingPos(int newRankingPos) => setRankingPos(newRankingPos, true);

  void setRankingPos(int newRankingPos, [bool isActive = true]) {
    _rankingPos = newRankingPos;
    _isActive = isActive;
  }

  bool get isActive => matchIds.isNotEmpty;

  MyListView<String> get matchIds => MyListView(_matchIds);

  List<String> get copyOfMatchIds => List.from(_matchIds);

  // methods por _matchIds
  bool addMatchId(String matchId, [bool sort = false]) {
    if (!_matchIds.contains(matchId)) {
      _matchIds.add(matchId);
      if (sort) _matchIds.sort();
      return true;
    } else {
      MyLog.log(_classString, 'addMatchId: matchId=$matchId already exists');
      return false;
    }
  }

  void addAllMatchIds(Iterable<String> newMatchIds) {
    for (final matchId in newMatchIds) {
      addMatchId(matchId, false);
    }
    _matchIds.sort();
  }

  bool removeMatchId(String matchId) {
    bool removed = _matchIds.remove(matchId);
    if (!removed) MyLog.log(_classString, 'removeMatchId: matchId=$matchId not found');
    return removed;
  }

  void clearMatchId() {
    _matchIds.clear();
  }

  void setMatchIds(List<String> newMatchIds) {
    _matchIds.clear();
    _matchIds.addAll(newMatchIds);
    _matchIds.sort();
  }

  /// Getter for the user's email.
  String get email => _email;

  /// Setter for the user's email, converting it to lowercase.
  set email(String email) => _email = email.toLowerCase();

  /// Creates a new MyUser object with updated fields.
  MyUser copyWith({
    String? id,
    String? name,
    String? emergencyInfo,
    String? email,
    UserType? userType,
    Date? lastLogin,
    int? loginCount,
    String? avatarUrl,
    int? rankingPos,
    bool? isActive,
    List<String>? matchIds,
  }) {
    return MyUser._(
      id: id ?? this.id,
      name: name ?? this.name,
      emergencyInfo: emergencyInfo ?? this.emergencyInfo,
      email: email ?? _email,
      userType: userType ?? this.userType,
      lastLogin: lastLogin ?? this.lastLogin,
      loginCount: loginCount ?? this.loginCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rankingPos: rankingPos ?? _rankingPos,
      isActive: isActive ?? _isActive,
      matchIds: matchIds ?? _matchIds,
    );
  }

  /// Updates the fields of the *current* MyUser object from another MyUser object.
  void copyFrom(MyUser user) {
    id = user.id;
    name = user.name;
    emergencyInfo = user.emergencyInfo;
    _email = user._email;
    userType = user.userType;
    lastLogin = user.lastLogin;
    loginCount = user.loginCount;
    avatarUrl = user.avatarUrl;
    _rankingPos = user._rankingPos;
    _isActive = user._isActive;
    setMatchIds(user._matchIds);
  }

  /// Checks if the user has non-empty id, name, and email fields.
  bool hasBasicInfo() => id.isNotEmpty && name.isNotEmpty && email.isNotEmpty;

  /// Returns a string representation of the MyUser object.
  @override
  String toString() {
    return ('$id:$name');
  }

  /// Creates a MyUser object from a JSON map.
  factory MyUser.fromJson(Map<String, dynamic> json) {
    /// Checks if the userId is null or empty.
    if (json[UserFs.userId.name] == null || json[UserFs.userId.name] == '') {
      MyLog.log(_classString, 'Missing userId in Firestore document', myCustomObject: json, level: Level.SEVERE);
      throw FormatException('Error de formato. Usuario sin identificador al leer de la base de datos.\n'
          'objeto: $json');
    }

    try {
      /// Creates a MyUser object from the provided data.
      return MyUser._(
        id: json[UserFs.userId.name],
        name: json[UserFs.name.name] ?? '',
        emergencyInfo: json[UserFs.emergencyInfo.name] ?? '',
        email: json[UserFs.email.name] ?? '',
        userType: _intToUserType(json[UserFs.userType.name]),
        lastLogin: Date.parse(json[UserFs.lastLogin.name]),
        loginCount: json[UserFs.loginCount.name] ?? 0,
        avatarUrl: json[UserFs.avatarUrl.name],
        rankingPos: json[UserFs.rankingPos.name] ?? 0,
        isActive: json[UserFs.isActive.name] ?? false,
        matchIds: json[UserFs.matchIds.name]?.cast<String>() ?? [],
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creating MyUser from Firestore: ${e.toString()}',
          myCustomObject: json, level: Level.SEVERE);
      throw Exception('Error creando un usuario desde la base de datos: ${e.toString()}');
    }
  }

  /// Converts the MyUser object to a JSON map.
  Map<String, dynamic> toJson() {
    /// Checks if the id is empty.
    if (id == '') {
      MyLog.log(_classString, 'userId is empty', myCustomObject: this, level: Level.SEVERE);
      throw FormatException('Error creando los datos para la BdD. \n'
          'Usuario vacío. $this');
    }

    /// Returns a map containing all of the data, including the userId.
    return {
      UserFs.userId.name: id,
      UserFs.name.name: name,
      UserFs.emergencyInfo.name: emergencyInfo,
      UserFs.email.name: email,
      UserFs.userType.name: userType.index,
      UserFs.lastLogin.name: lastLogin?.toYyyyMmDd() ?? '',
      UserFs.loginCount.name: loginCount,
      UserFs.avatarUrl.name: avatarUrl,
      UserFs.rankingPos.name: _rankingPos,
      UserFs.isActive.name: _isActive,
      UserFs.matchIds.name: List.from(_matchIds), // generate a copy for inmutability
    };
  }

  /// Overrides the equality operator.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MyUser) return false;
    final listEquals = const DeepCollectionEquality().equals; // Use collection package
    return id == other.id &&
        name == other.name &&
        emergencyInfo == other.emergencyInfo &&
        _email == other._email &&
        userType == other.userType &&
        lastLogin == other.lastLogin &&
        loginCount == other.loginCount &&
        avatarUrl == other.avatarUrl &&
        _rankingPos == other._rankingPos &&
        _isActive == other._isActive &&
        listEquals(_matchIds, other._matchIds);
  }

  /// Overrides the hashCode getter.
  @override
  int get hashCode => Object.hash(
        id,
        name,
        emergencyInfo,
        _email,
        userType,
        lastLogin,
        loginCount,
        avatarUrl,
        _rankingPos,
        _isActive,
        Object.hashAll(_matchIds),
      );

  static UserType _intToUserType(int? type) {
    try {
      return UserType.values[type!];
    } catch (e) {
      MyLog.log(_classString, 'Invalid UserType index: $type, Error: ${e.toString()}', level: Level.WARNING);
      return UserType.basic;
    }
  }
}

Comparator<MyUser> getMyUserComparator(UsersSortBy sortBy) {
  switch (sortBy) {
    case UsersSortBy.ranking:
      return (a, b) {
        // Primary sort: non-active users go to the end
        if (a.isActive && !b.isActive) {
          return -1; // a (active) comes before b (not active)
        }
        if (!a.isActive && b.isActive) {
          return 1; // a (not active) comes after b (active)
        }
        // Tertiary sort: by ranking (descending)
        final rankingCompare = b.rankingPos.compareTo(a.rankingPos);
        return rankingCompare == 0 ? compareToNoDiacritics(a.name, b.name) : rankingCompare;
      }; // Descending ranking
    case UsersSortBy.name:
      return (a, b) => compareToNoDiacritics(a.name, b.name); // Ascending name (no diacritics)
  }
}
