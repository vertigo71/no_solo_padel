import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../utilities/date.dart';
import '../models/debug.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/transformation.dart';

final String _classString = 'AppState'.toUpperCase();

class AppState with ChangeNotifier {
  AppState() {
    MyLog().log(_classString, 'Building ');
  }

  MyParameters _parameters = MyParameters();
  MyUser _loggedUser = MyUser();
  final List<MyUser> _allUsers = [];
  final List<MyMatch> _allMatches = [];

  //------------------------------------------------

  void deleteAll() {
    MyLog().log(_classString, 'deleteAll ');
    _loggedUser = MyUser();
    _parameters = MyParameters();
    _allMatches.clear();
    _allUsers.clear();
  }

  String getParameterValue(ParametersEnum parameter) => _parameters.getStrValue(parameter);

  int getIntParameterValue(ParametersEnum parameter) => _parameters.getIntValue(parameter);

  bool getBoolParameterValue(ParametersEnum parameter) => _parameters.getBoolValue(parameter);

  bool isDayPlayable(Date date) => _parameters.isDayPlayable(date);

  void setParameterValue(ParametersEnum parameter, String value, {required bool notify}) {
    MyLog().log(_classString, 'setParameter $parameter $value');
    _parameters.setValue(parameter, value);
    if (notify) notifyListeners();
  }

  void setAllParametersAndNotify(MyParameters? myParameters) =>
      setAllParameters(myParameters, notify: true);

  void setAllParameters(MyParameters? myParameters, {required bool notify}) {
    MyLog().log(_classString, 'setAllParameters $myParameters');
    _parameters = myParameters ?? MyParameters();
    MyLog.minDebugType = _parameters.minDebugLevel;
    MyLog().log(_classString, 'setAllParameters debugType = ${MyLog.minDebugType}');
    if (notify) notifyListeners();
  }

  MyUser getLoggedUser() => _loggedUser;

  void setLoggedUser(MyUser loggedUser, {required bool notify}) {
    MyLog().log(_classString, 'setLoggedUser', myCustomObject: loggedUser);
    _loggedUser = loggedUser;
    if (notify) notifyListeners();
  }

  void setLoggedUserById(String userId, {required bool notify}) {
    MyLog().log(_classString, 'setLoggedUserById In', myCustomObject: userId);

    MyUser? myUser = getUserById(userId);
    if (myUser == null) {
      _loggedUser = MyUser();
    } else {
      _loggedUser = myUser;
    }
    MyLog().log(_classString, 'setLoggedUserById Out', myCustomObject: myUser);
    if (notify) notifyListeners();
  }

  List<MyUser> get allUsers => _allUsers;

  List<MyUser> get allSortedUsers {
    // _allUsers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _allUsers.sort((a, b) => lowCaseNoDiacritics(a.name).compareTo(lowCaseNoDiacritics(b.name)));
    return _allUsers;
  }

  List<MyMatch> get allMatches => _allMatches;

  List<MyMatch> get allSortedMatches {
    _allMatches.sort((a, b) => a.date.compareTo(b.date));
    return _allMatches;
  }

  List<MyMatch> getSortedMatchesIfDayPlayable() {
    _allMatches.sort((a, b) => a.date.compareTo(b.date));
    return _allMatches.where((element) => isDayPlayable(element.date)).toList();
  }

  bool get isLoggedUserAdmin => [UserType.admin, UserType.superuser].contains(_loggedUser.userType);

  bool get isLoggedUserSuper => _loggedUser.userType == UserType.superuser;

  bool get showLog => getBoolParameterValue(ParametersEnum.showLog);

  void setAllUsers(List<MyUser> users, {required bool notify}) {
    MyLog().log(_classString, 'setAllUsers', myCustomObject: users, debugType: DebugType.info);

    _allUsers.clear();
    _allUsers.addAll(users);

    // convert loggedUser
    setLoggedUserById(_loggedUser.userId, notify: false);

    if (notify) notifyListeners();
  }

  void setChangedUsersAndNotify(List<MyUser> added, List<MyUser> modified, List<MyUser> removed) =>
      setChangedUsers(added, modified, removed, notify: true);

  void setChangedUsers(List<MyUser> added, List<MyUser> modified, List<MyUser> removed,
      {required bool notify}) {
    MyLog()
        .log(_classString, 'setChangedUsers ${added.length} ${modified.length} ${removed.length} ');

    if (added.isNotEmpty) {
      MyLog().log(_classString, 'setChangedUsers added $added ');
    }
    if (modified.isNotEmpty) {
      MyLog().log(_classString, 'setChangedUsers modified $modified ');
    }
    if (removed.isNotEmpty) {
      MyLog().log(_classString, 'setChangedUsers removed $removed ');
    }

    added.addAll(modified);
    for (MyUser newUser in added) {
      MyLog().log(_classString, 'setChangedUsers update user: ', myCustomObject: newUser);
      removeUserByIdBold(newUser.userId);
    }
    _allUsers.addAll(added);
    for (var newUser in removed) {
      MyLog().log(_classString, 'setChangedUsers REMOVED!!!: ', myCustomObject: newUser);
      removeUserByIdBold(newUser.userId);
    }

    // convert loggedUser
    setLoggedUserById(_loggedUser.userId, notify: false);

    if (notify) notifyListeners();
  }

  void setChangedMatchesAndNotify(
          List<MyMatch> added, List<MyMatch> modified, List<MyMatch> removed) =>
      setChangedMatches(added, modified, removed, notify: true);

  void setChangedMatches(List<MyMatch> added, List<MyMatch> modified, List<MyMatch> removed,
      {required bool notify}) {
    MyLog().log(
        _classString, 'setChangedMatches ${added.length} ${modified.length} ${removed.length} ');

    if (added.isNotEmpty) {
      MyLog().log(_classString, 'setChangedMatches added $added ');
    }
    if (modified.isNotEmpty) {
      MyLog().log(_classString, 'setChangedMatches modified $modified ');
    }
    if (removed.isNotEmpty) {
      MyLog().log(_classString, 'setChangedMatches removed $removed ');
    }

    added.addAll(modified);
    for (var newMatch in added) {
      MyLog().log(_classString, 'setChangedMatches update match: ', myCustomObject: newMatch);
      removeMatchByDateBold(newMatch.date);
    }
    _allMatches.addAll(added);
    for (var newMatch in removed) {
      MyLog().log(_classString, 'setChangedMatches remove match: ', myCustomObject: newMatch);
      removeMatchByDateBold(newMatch.date);
    }
    if (notify) notifyListeners();
  }

  MyUser? getUserByName(String name) => _allUsers.firstWhereOrNull((user) => user.name == name);

  MyUser? getUserById(String id) => _allUsers.firstWhereOrNull((user) => user.userId == id);

  MyUser? getUserByEmail(String email) => _allUsers.firstWhereOrNull((user) => user.email == email);

  void removeUserByIdBold(String id) => _allUsers.removeWhere((user) => user.userId == id);

  MyMatch? getMatch(Date date) => _allMatches.firstWhereOrNull((match) => match.date == date);

  void removeMatchByDateBold(Date date) => _allMatches.removeWhere((match) => match.date == date);

  /// return null if exists or incorrect format
  /// unique name, email and id
  MyUser? createNewUserByEmail(String email) {
    MyLog().log(_classString, 'createNewUserByEmail', myCustomObject: email);

    MyUser? user = getUserByEmail(email);
    if (user != null) return null; // already exists

    // get name from email
    List<String> items = email.split('@');
    if (items.length != 2) return null; // incorrect format
    String name = items[0];

    user = MyUser(name: name, email: email, userId: name, userType: UserType.basic);
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
    userExists = getUserById(user.userId);
    if (userExists != null) {
      int i = 0;
      final String baseName = user.userId;
      do {
        user.userId = '$baseName${i++}'; // create new id
        userExists = getUserById(user.userId);
      } while (userExists != null);
    }
    MyLog().log(_classString, 'createNewUserByEmail new User = $user');
    return user;
  }

  List<MyUser> userIdsToUsers(Iterable<String> usersId) {
    List<MyUser> users = usersId.map((userId) => getUserById(userId)).whereType<MyUser>().toList();
    if (usersId.length != users.length) {
      MyLog().log(_classString, 'stringToUsers ERROR',
          myCustomObject: users, debugType: DebugType.error);
    }
    return users;
  }

  @override
  String toString() {
    String str = '';
    for (var element in allUsers) {
      str = str + element.toString() + '\n';
    }
    return str;
  }
}
