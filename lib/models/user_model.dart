import 'package:simple_logger/simple_logger.dart';
import '../database/fields.dart';
import '../utilities/date.dart';
import 'debug.dart';

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

/// Represents a user in the application.
class MyUser {
  /// Suffix added to user emails.
  static const String emailSuffix = '@nsp.com';

  /// Unique identifier of the user.
  String id;

  /// Name of the user.
  String name;

  /// Emergency information for the user.
  String emergencyInfo;

  /// Private email field, accessed via getter and setter.
  String _email;

  /// Type of the user (basic, admin, superuser).
  UserType userType;

  /// Last login date of the user.
  Date? lastLogin;

  /// Number of times the user has logged in.
  int loginCount;

  /// URL of the user's avatar.
  String? avatarUrl;

  /// Ranking position of the user.
  int rankingPos;

  /// Constructor for MyUser class.
  MyUser({
    this.id = '',
    this.name = '',
    this.emergencyInfo = '',
    String email = '',
    this.userType = UserType.basic,
    this.lastLogin,
    this.loginCount = 0,
    this.avatarUrl,
    this.rankingPos = 0,
  }) : _email = email.toLowerCase();

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
      rankingPos: rankingPos ?? this.rankingPos,
    );
  }

  /// Creates a new MyUser object from an existing MyUser object.
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
      rankingPos: user.rankingPos,
    );
  }

  /// Checks if the user has non-empty id, name, and email fields.
  bool hasNotEmptyFields() {
    return id.isNotEmpty && name.isNotEmpty && email.isNotEmpty;
  }

  /// Getter for the user's email.
  String get email => _email;

  /// Setter for the user's email, converting it to lowercase.
  set email(String email) => _email = email.toLowerCase();

  /// Converts an integer to a UserType enum value.
  static UserType intToUserType(int? type) {
    try {
      return UserType.values[type!];
    } catch (e) {
      MyLog.log(_classString, 'Invalid UserType index: $type, Error: $e', level: Level.WARNING);
      return UserType.basic;
    }
  }

  /// Returns a string representation of the MyUser object.
  @override
  String toString() {
    return ('$id:$name');
  }

  /// Creates a MyUser object from a JSON map.
  factory MyUser.fromJson(Map<String, dynamic> json) {
    /// Checks if the userId is null or empty.
    if (json[Fields.userId.name] == null || json[Fields.userId.name] == '') {
      MyLog.log(_classString, 'Missing userId in Firestore document', myCustomObject: json, level: Level.SEVERE);
      throw FormatException('Error de formato. Usuario sin identificador al leer de la base de datos.\n'
          'objeto: $json');
    }

    try {
      /// Creates a MyUser object from the provided data.
      return MyUser(
        id: json[Fields.userId.name],
        name: json[Fields.name.name] ?? '',
        emergencyInfo: json[Fields.emergencyInfo.name] ?? '',
        email: json[Fields.email.name] ?? '',
        userType: intToUserType(json[Fields.userType.name]),
        lastLogin: Date.parse(json[Fields.lastLogin.name]),
        loginCount: json[Fields.loginCount.name] ?? 0,
        avatarUrl: json[Fields.avatarUrl.name],
        rankingPos: json[Fields.rankingPos.name] ?? 0,
      );
    } catch (e) {
      MyLog.log(_classString, 'Error creating MyUser from Firestore: $e', myCustomObject: json, level: Level.SEVERE);
      throw Exception('Error creando un usuario desde la base de datos: $e');
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
      fName(Fields.userId): id,
      Fields.name.name: name,
      Fields.emergencyInfo.name: emergencyInfo,
      Fields.email.name: email,
      Fields.userType.name: userType.index,
      Fields.lastLogin.name: lastLogin?.toYyyyMMdd() ?? '',
      Fields.loginCount.name: loginCount,
      Fields.avatarUrl.name: avatarUrl,
      Fields.rankingPos.name: rankingPos,
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
        rankingPos == other.rankingPos;
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
      );
}
