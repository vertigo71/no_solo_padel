import '../utilities/misc.dart';

enum UserType { basic, admin, superuser }

class MyUser {
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

  static const String emailSuffix = '@nsp.com';

  bool hasNotEmptyFields() {
    return userId.isNotEmpty && name.isNotEmpty && email.isNotEmpty;
  }

  String get email => _email;

  set email(String email) => _email = email.toLowerCase();

  @override
  String toString() {
    return ('<$userId, $name>');
  }
}
