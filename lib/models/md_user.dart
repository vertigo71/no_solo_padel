import 'package:no_solo_padel/models/md_exception.dart';
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

  static UserType intToUserType(int? type) {
    try {
      return UserType.values[type!];
    } catch (e) {
      MyLog.log(_classString, 'Invalid UserType index: $type, Error: ${e.toString()}', level: Level.WARNING);
      return UserType.basic;
    }
  }
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
  bool isActive;

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
    bool isActive = false,
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
      isActive: isActive,
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
    this.isActive = false, // Initialize isActive in the private constructor
  }) : _email = email.toLowerCase();

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
      isActive: isActive ?? this.isActive,
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
    isActive = user.isActive;
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
      throw MyException(
          'Error de formato. Usuario sin identificador al leer de la base de datos.\n'
          'Objeto: $json',
          level: Level.SEVERE);
    }

    try {
      /// Creates a MyUser object from the provided data.
      return MyUser._(
        id: json[UserFs.userId.name],
        name: json[UserFs.name.name] ?? '',
        emergencyInfo: json[UserFs.emergencyInfo.name] ?? '',
        email: json[UserFs.email.name] ?? '',
        userType: UserType.intToUserType(json[UserFs.userType.name]),
        lastLogin: Date.parse(json[UserFs.lastLogin.name]),
        loginCount: json[UserFs.loginCount.name] ?? 0,
        avatarUrl: json[UserFs.avatarUrl.name],
        rankingPos: json[UserFs.rankingPos.name] ?? 0,
        isActive: json[UserFs.isActive.name] ?? false,
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creating MyUser from Firestore: ${e.toString()}',
          myCustomObject: json, level: Level.SEVERE);
      throw MyException('Error creando un usuario desde la base de datos', e: e, level: Level.SEVERE);
    }
  }

  /// Converts the MyUser object to a JSON map.
  Map<String, dynamic> toJson() {
    /// Checks if the id is empty.
    if (id == '') {
      MyLog.log(_classString, 'userId is empty', myCustomObject: this, level: Level.SEVERE);
      throw MyException(
          'Error creando los datos para la Base de Datos. \n'
          'Usuario vacío. $this',
          level: Level.SEVERE);
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
      UserFs.isActive.name: isActive,
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
        isActive == other.isActive &&
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
        isActive,
      );
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
