import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';

import '../utilities/date.dart';
import '../models/debug.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/transformation.dart';

final String _classString = 'AppState'.toUpperCase();

/// registers the state of the app
/// Saves users and parameters in Cache variables
/// Access to loggedUser
class AppState with ChangeNotifier {
  AppState() {
    MyLog.log(_classString, 'Building ');
  }

  /// attributes
  MyParameters _parametersCache = MyParameters();
  final List<MyUser> _usersCache = [];
  MyUser _loggedUser = MyUser();

  /// deleteALL: reset parameters attribute, loggedUser=none
  /// remove all matches and users from memory
  void resetLoggedUser() {
    MyLog.log(_classString, 'resetLoggedUser ');
    setLoggedUser(MyUser(), notify: false);
  }

  /// parameter methods
  String getParameterValue(ParametersEnum parameter) => _parametersCache.getStrValue(parameter);

  int getIntParameterValue(ParametersEnum parameter) => _parametersCache.getIntValue(parameter);

  bool getBoolParameterValue(ParametersEnum parameter) => _parametersCache.getBoolValue(parameter);

  bool isDayPlayable(Date date) => _parametersCache.isDayPlayable(date);

  Date get maxDateOfMatchesToView =>
      Date.now().add(Duration(days: getIntParameterValue(ParametersEnum.matchDaysToView)));

  void setAllParametersAndNotify(MyParameters? myParameters) => setAllParameters(myParameters, notify: true);

  void setAllParameters(MyParameters? myParameters, {required bool notify}) {
    MyLog.log(_classString, 'setAllParameters $myParameters', level: Level.INFO);
    _parametersCache = myParameters ?? MyParameters();
    MyLog.setDebugLevel(_parametersCache.minDebugLevel); // new level of debugging
    if (notify) notifyListeners();
  }

  /// user methods
  MyUser getLoggedUser() => _loggedUser;

  void setLoggedUser(MyUser user, {required bool notify}) {
    MyLog.log(_classString, 'setLoggedUser $user', level: Level.INFO);
    _loggedUser = user;
    // update MyLog name and email
    MyLog.loggedUserId = _loggedUser.id;

    if (notify) notifyListeners();
  }

  void setLoggedUserById(String userId, {required bool notify}) {
    MyLog.log(_classString, 'setLoggedUserById In', myCustomObject: userId);

    MyUser loggedUser = getUserById(userId) ?? MyUser();
    setLoggedUser(loggedUser, notify: notify);

    MyLog.log(_classString, 'setLoggedUserById Out', myCustomObject: loggedUser);
    if (notify) notifyListeners();
  }

  List<MyUser> get usersCopy => List.from(_usersCache);

  int get numUsers => _usersCache.length;

  List<MyUser> get sortUsers {
    _usersCache.sort((a, b) => lowCaseNoDiacritics(a.name).compareTo(lowCaseNoDiacritics(b.name)));
    return _usersCache;
  }

  bool get isLoggedUserAdmin => [UserType.admin, UserType.superuser].contains(_loggedUser.userType);

  bool get isLoggedUserSuper => _loggedUser.userType == UserType.superuser;

  bool get showLog => getBoolParameterValue(ParametersEnum.showLog);

  void setAllUsers(List<MyUser> users, {required bool notify}) {
    MyLog.log(_classString, 'setAllUsers #=${users.length}', myCustomObject: users, level: Level.INFO);

    _usersCache.clear();
    _usersCache.addAll(users);

    // convert loggedUser
    setLoggedUserById(_loggedUser.id, notify: false);

    if (notify) notifyListeners();
  }

  void setChangedUsersAndNotify(List<MyUser> added, List<MyUser> modified, List<MyUser> removed) =>
      setChangedUsers(added, modified, removed, notify: true);

  void setChangedUsers(List<MyUser> added, List<MyUser> modified, List<MyUser> removed, {required bool notify}) {
    MyLog.log(_classString, 'setChangedUsers a=${added.length} m=${modified.length} r=${removed.length} ',
        level: Level.INFO);

    if (added.isNotEmpty) {
      MyLog.log(_classString, 'setChangedUsers added $added ');
      _usersCache.addAll(added);
    }
    if (modified.isNotEmpty) {
      MyLog.log(_classString, 'setChangedUsers modified $modified ');
      for (var newUser in modified) {
        bool correct = copyUserToCache(newUser);
        if (!correct) {
          MyLog.log(_classString, 'setChangedUsers user to modify not found $newUser ', level: Level.SEVERE);
        }
      }
    }
    if (removed.isNotEmpty) {
      MyLog.log(_classString, 'setChangedUsers removed $removed ');
      for (var newUser in removed) {
        MyLog.log(_classString, 'setChangedUsers REMOVED!!!: $newUser');
        removeUserByIdBold(newUser.id);
      }
    }

    if (notify) notifyListeners();
  }

  MyUser? getUserByName(String name) => _usersCache.firstWhereOrNull((user) => user.name == name);

  MyUser? getUserById(String id) => _usersCache.firstWhereOrNull((user) => user.id == id);

  MyUser? getUserByEmail(String email) => _usersCache.firstWhereOrNull((user) => user.email == email);

  void removeUserByIdBold(String id) => _usersCache.removeWhere((user) => user.id == id);

  /// search usersCache for newUserId
  /// if not found, return false
  /// if found copy all data from newUser to User
  bool copyUserToCache(MyUser newUser) {
    Set<MyUser> usersFound = _usersCache.where((user) => user.id == newUser.id).toSet();
    if (usersFound.isEmpty) {
      MyLog.log(_classString, 'copyUserToCache. No users found = $newUser ', level: Level.SEVERE);
      return false;
    }
    if (usersFound.length > 1) {
      MyLog.log(_classString, 'copyUserToCache. More than 1 users found = $newUser ', level: Level.SEVERE);
    }
    for (var user in usersFound) {
      MyLog.log(_classString, 'copyUserToCache. Copying: $newUser ');
      user.copyFrom(newUser);
    }
    return true;
  }

  /// return null if exists or incorrect format
  /// unique name, email and id
  MyUser? createNewUserByEmail(String email) {
    MyLog.log(_classString, 'createNewUserByEmail', myCustomObject: email);

    MyUser? user = getUserByEmail(email);
    if (user != null) return null; // already exists

    // get name from email
    List<String> items = email.split('@');
    if (items.length != 2) return null; // incorrect format
    String name = items[0];

    user = MyUser(name: name, email: email, id: name, userType: UserType.basic);
    // check name and userId don't already exist
    MyUser? userExists = getUserByName(user.name);
    if (userExists != null) {
      int i = 0;
      final String baseName = user.name;
      do {
        user.name = '$baseName${i++}'; // create new name
        userExists = getUserByName(user.name);
      } while (userExists != null);
    }
    userExists = getUserById(user.id);
    if (userExists != null) {
      int i = 0;
      final String baseName = user.id;
      do {
        user.id = '$baseName${i++}'; // create new id
        userExists = getUserById(user.id);
      } while (userExists != null);
    }
    MyLog.log(_classString, 'createNewUserByEmail new User = $user', level: Level.INFO);
    return user;
  }

  @override
  String toString() => 'Parameters = $_parametersCache\n'
      '#users=${_usersCache.length}\n'
      'loggedUser=$_loggedUser';
}
