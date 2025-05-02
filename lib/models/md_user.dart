import 'dart:collection';

import 'package:simple_logger/simple_logger.dart';
import 'dart:core';

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
  matchIds,
  resultIds,
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
  int rankingPos;
  final SplayTreeSet<String> _matchIds =
      SplayTreeSet<String>(); // ordered set with all the matches that user has joined
  final SplayTreeSet<String> _resultIds = SplayTreeSet<String>(); // ordered set with all the games that user has played

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
    this.rankingPos = 0,
    Iterable<String>? matchIds, // format YYYYMMDD
    Iterable<String>? resultIds,
  }) : _email = email.toLowerCase() {
    _matchIds.addAll(matchIds ?? []);
    _resultIds.addAll(resultIds ?? []);
  }

  bool get isActive => _matchIds.isNotEmpty;

  SplayTreeSet<String> get matchIds => _matchIds;

  SplayTreeSet<String> get resultIds => _resultIds;

  /// Returns a list of match IDs, optionally filtered by a 'to date' and sorted.
  ///
  /// The match IDs in the internal `_matchIds` list and the `toDate` parameter
  /// are expected to be strings in the format 'YYYYMMDD' for correct
  /// chronological sorting and filtering.
  ///
  /// Parameters:
  ///   toDate: An optional string representing the latest date (inclusive)
  ///           for the match IDs to include, in 'YYYYMMDD' format. If null, all
  ///           match IDs are considered.
  ///   reversed: If true, the list is sorted in descending order; otherwise,
  ///             it's sorted in ascending order (chronologically based on the
  ///             'YYYYMMDD' format).
  List<String> _getIdsSorted({required bool matchIds, String? toDate, bool reversed = false}) {
    List<String> sortedIds;
    if (matchIds) {
      sortedIds = List.from(_matchIds);
    } else {
      sortedIds = List.from(_resultIds);
    }
    if (reversed) {
      sortedIds.sort((a, b) => b.compareTo(a));
    }
    // else already sorted
    if (toDate != null) {
      sortedIds = sortedIds.where((id) => id.compareTo(toDate) <= 0).toList();
    }

    return sortedIds;
  }

  List<String> getMatchIdsSorted({String? toDate, bool reversed = false}) =>
      _getIdsSorted(matchIds: true, toDate: toDate, reversed: reversed);

  List<String> getResultIdsSorted({String? toDate, bool reversed = false}) =>
      _getIdsSorted(matchIds: false, toDate: toDate, reversed: reversed);

  void setMatchIds(Iterable<String> newMatchIds) {
    _matchIds.clear();
    _matchIds.addAll(newMatchIds);
  }

  void setResultIds(Iterable<String> newResultIds) {
    _resultIds.clear();
    _resultIds.addAll(newResultIds);
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
    List<String>? matchIds,
    List<String>? resultIds,
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
      rankingPos: rankingPos ?? this.rankingPos,
      matchIds: matchIds ?? _matchIds,
      resultIds: resultIds ?? _resultIds,
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
    rankingPos = user.rankingPos;
    setMatchIds(user._matchIds);
    setResultIds(user._resultIds);
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
        matchIds: json[UserFs.matchIds.name]?.cast<String>() ?? [],
        resultIds: json[UserFs.resultIds.name]?.cast<String>() ?? [],
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
      UserFs.rankingPos.name: rankingPos,
      UserFs.matchIds.name: List.from(_matchIds), // generate a copy for inmutability
      UserFs.resultIds.name: List.from(_resultIds), // generate a copy for inmutability
    };
  }

  /// Overrides the equality operator.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MyUser) return false;
    return id == other.id &&
        name == other.name &&
        emergencyInfo == other.emergencyInfo &&
        _email == other._email &&
        userType == other.userType &&
        lastLogin == other.lastLogin &&
        loginCount == other.loginCount &&
        avatarUrl == other.avatarUrl &&
        rankingPos == other.rankingPos &&
        _matchIds == other._matchIds &&
        _resultIds == other._resultIds &&
        true;
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
        rankingPos,
        Object.hashAll(_matchIds),
        Object.hashAll(_resultIds),
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
