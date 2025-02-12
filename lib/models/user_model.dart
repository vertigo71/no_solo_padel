import 'package:logging/logging.dart';

import '../database/fields.dart';
import '../utilities/date.dart';
import 'debug.dart';

final String _classString = 'MyUser'.toUpperCase();

enum UserType { basic, admin, superuser }

class MyUser {
  static const String emailSuffix = '@nsp.com';

  String id;
  String name;
  String emergencyInfo;
  String _email;
  UserType userType;
  Date? lastLogin;
  int loginCount;

  MyUser({
    this.id = '',
    this.name = '',
    this.emergencyInfo = '',
    String email = '',
    this.userType = UserType.basic,
    this.lastLogin,
    this.loginCount = 0,
  }) : _email = email.toLowerCase();

  MyUser copyWith({
    String? id,
    String? name,
    String? emergencyInfo,
    String? email,
    UserType? userType,
    Date? lastLogin,
    int? loginCount,
  }) {
    return MyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      emergencyInfo: emergencyInfo ?? this.emergencyInfo,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      lastLogin: lastLogin ?? this.lastLogin,
      loginCount: loginCount ?? this.loginCount,
    );
  }

  MyUser copyFrom(MyUser user) {
    return MyUser(
      id: user.id,
      name: user.name,
      emergencyInfo: user.emergencyInfo,
      email: user.email,
      userType: user.userType,
      lastLogin: user.lastLogin,
      loginCount: user.loginCount,
    );
  }

  bool hasNotEmptyFields() {
    return id.isNotEmpty && name.isNotEmpty && email.isNotEmpty;
  }

  String get email => _email;

  set email(String email) => _email = email.toLowerCase();

  static UserType intToUserType(int? type) {
    try {
      return UserType.values[type!];
    } catch (_) {
      return UserType.basic;
    }
  }

  @override
  String toString() {
    return ('$id:$name');
  }

  factory MyUser.fromJson(Map<String, dynamic> json) {
    if (json[DBFields.userId.name] == null || json[DBFields.userId.name] == '') {
      MyLog.log(_classString, 'fromJson id null ', myCustomObject: json, level: Level.SEVERE);
    }
    return MyUser(
      id: json[DBFields.userId.name] ?? '',
      name: json[DBFields.name.name] ?? '',
      emergencyInfo: json[DBFields.emergencyInfo.name] ?? '',
      email: json[DBFields.email.name] ?? '',
      userType: intToUserType(json[DBFields.userType.name]),
      lastLogin: Date.parse(json[DBFields.lastLogin.name]),
      loginCount: json[DBFields.loginCount.name] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    if (id == '') {
      MyLog.log(_classString, 'toJson id null ', myCustomObject: this, level: Level.SEVERE);
    }
    return {
      DBFields.userId.name: id,
      DBFields.name.name: name,
      DBFields.emergencyInfo.name: emergencyInfo,
      DBFields.email.name: email,
      DBFields.userType.name: userType.index, // int
      DBFields.lastLogin.name: lastLogin?.toYyyyMMdd() ?? '', // String
      DBFields.loginCount.name: loginCount, // int
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Check for identity first
    if (other is! MyUser) return false; // Check for type
    return id == other.id &&
        name == other.name &&
        emergencyInfo == other.emergencyInfo &&
        email == other.email &&
        userType == other.userType &&
        lastLogin == other.lastLogin &&
        loginCount == other.loginCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        emergencyInfo,
        email,
        userType,
        lastLogin,
        loginCount,
      );
}
