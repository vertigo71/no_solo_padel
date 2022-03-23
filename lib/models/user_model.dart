import '../database/fields.dart';
import '../utilities/date.dart';
import 'debug.dart';

final String _classString = 'MyUser'.toUpperCase();

enum UserType { basic, admin, superuser }

class MyUser {
  static const String emailSuffix = '@nsp.com';

  String userId;
  String name;
  String _email;
  UserType userType;
  Date? lastLogin;
  int loginCount;

  MyUser(
      {this.name = '',
      String email = '',
      this.userType = UserType.basic,
      this.lastLogin,
      this.loginCount = 0,
      this.userId = ''})
      : _email = email.toLowerCase();

  MyUser copyWith({
    String? userId,
    String? name,
    String? email,
    UserType? userType,
    Date? lastLogin,
    int? loginCount,
  }) =>
      MyUser(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        userType: userType ?? this.userType,
        lastLogin: lastLogin ?? this.lastLogin,
        loginCount: loginCount ?? this.loginCount,
      );

  bool hasNotEmptyFields() {
    return userId.isNotEmpty && name.isNotEmpty && email.isNotEmpty;
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
    return ('$userId:$name');
  }

  static MyUser fromJson(Map<String, dynamic> json) {
    if (json[DBFields.userId.name] == null || json[DBFields.userId.name] == '') {
      MyLog()
          .log(_classString, 'fromJson id null ', myCustomObject: json, debugType: DebugType.error);
    }
    return MyUser(
      userId: json[DBFields.userId.name] ?? '',
      name: json[DBFields.name.name] ?? '',
      email: json[DBFields.email.name] ?? '',
      userType: intToUserType(json[DBFields.userType.name]),
      lastLogin: Date.parse(json[DBFields.lastLogin.name]),
      loginCount: json[DBFields.loginCount.name] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    if (userId == '') {
      MyLog()
          .log(_classString, 'toJson id null ', myCustomObject: this, debugType: DebugType.error);
    }
    return {
      DBFields.userId.name: userId,
      DBFields.name.name: name,
      DBFields.email.name: email,
      DBFields.userType.name: userType.index, // int
      DBFields.lastLogin.name: lastLogin?.toYyyyMMdd() ?? '', // String
      DBFields.loginCount.name: loginCount, // int
    };
  }
}
