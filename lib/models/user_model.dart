import 'package:simple_logger/simple_logger.dart';

import '../database/fields.dart';
import '../utilities/date.dart';
import 'debug.dart';

final String _classString = '<md> MyUser'.toLowerCase();

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
  String? avatarUrl;

  MyUser({
    this.id = '',
    this.name = '',
    this.emergencyInfo = '',
    String email = '',
    this.userType = UserType.basic,
    this.lastLogin,
    this.loginCount = 0,
    this.avatarUrl,
  }) : _email = email.toLowerCase();

  MyUser copyWith({
    String? id,
    String? name,
    String? emergencyInfo,
    String? email,
    UserType? userType,
    Date? lastLogin,
    int? loginCount,
    String? avatarUrl,
  }) {
    return MyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      emergencyInfo: emergencyInfo ?? this.emergencyInfo,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      lastLogin: lastLogin ?? this.lastLogin,
      loginCount: loginCount ?? this.loginCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
      avatarUrl: user.avatarUrl,
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
      avatarUrl: json[DBFields.avatarUrl.name],
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
      DBFields.avatarUrl.name: avatarUrl,
    };
  }

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
        avatarUrl == other.avatarUrl;
  }

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
      );
}
