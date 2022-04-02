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

  void deleteAll() {
    MyLog().log(_classString, 'deleteAll ');
    setLoggedUser(MyUser(), notify: false);
    setAllParameters(null, notify: false);
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
    MyLog().log(_classString, 'setAllParameters $myParameters', debugType: DebugType.warning);
    _parameters = myParameters ?? MyParameters();
    MyLog.minDebugType = _parameters.minDebugLevel;
    if (notify) notifyListeners();
  }

  MyUser getLoggedUser() => _loggedUser;

  void setLoggedUser(MyUser loggedUser, {required bool notify}) {
    MyLog().log(_classString, 'setLoggedUser $loggedUser', debugType: DebugType.warning);
    _loggedUser = loggedUser;
    // update MyLog name and email
    MyLog.loggedUserId = _loggedUser.userId;

    if (notify) notifyListeners();
  }

  void setLoggedUserById(String userId, {required bool notify}) {
    MyLog().log(_classString, 'setLoggedUserById In', myCustomObject: userId);

    MyUser loggedUser = getUserById(userId) ?? MyUser();
    setLoggedUser(loggedUser, notify: notify);

    MyLog().log(_classString, 'setLoggedUserById Out', myCustomObject: loggedUser);
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
    MyLog().log(_classString, 'setAllUsers #=${users.length}', debugType: DebugType.warning);
    MyLog().log(_classString, 'setAllUsers', myCustomObject: users);

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
    MyLog().log(
        _classString, 'setChangedUsers a=${added.length} m=${modified.length} r=${removed.length} ',
        debugType: DebugType.warning);

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
    MyLog().log(_classString, 'setChangedUsers updating users: $added');
    for (MyUser newUser in added) {
      removeUserByIdBold(newUser.userId);
    }
    _allUsers.addAll(added);
    for (var newUser in removed) {
      MyLog().log(_classString, 'setChangedUsers REMOVED!!!: $newUser');
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
    MyLog().log(_classString,
        'setChangedMatches a=${added.length} m=${modified.length} r=${removed.length} ',
        debugType: DebugType.warning);

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
    MyLog().log(_classString, 'setChangedMatches updating matches: $added');
    for (var newMatch in added) {
      removeMatchByDateBold(newMatch.date);
    }
    _allMatches.addAll(added);
    for (var newMatch in removed) {
      MyLog().log(_classString, 'setChangedMatches remove match: $newMatch ');
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
    MyLog()
        .log(_classString, 'createNewUserByEmail new User = $user', debugType: DebugType.warning);
    return user;
  }

  List<MyUser> userIdsToUsers(Iterable<String> usersId) {
    List<MyUser> users = usersId.map((userId) => getUserById(userId)).whereType<MyUser>().toList();
    if (usersId.length != users.length) {
      MyLog().log(_classString, 'stringToUsers ERROR $usersId',
          myCustomObject: users, debugType: DebugType.error);
    }
    return users;
  }

  // true if nothing deleted
  bool deleteNonUsersInMatch(MyMatch match) {
    List<MyUser> players =
        match.players.map((userId) => getUserById(userId)).whereType<MyUser>().toList();
    if (match.players.length != players.length) {
      MyLog().log(_classString, 'deleteNonUsersInMatch Non existing users $match',
          myCustomObject: players, debugType: DebugType.error);
      match.players.clear();
      match.players.addAll(players.map((player) => player.userId));
      return false;
    }
    return true;
  }

  @override
  String toString() => 'Parameters = $_parameters\n'
      '#users=${_allUsers.length} #matches=${_allMatches.length}\n'
      'loggedUser=$_loggedUser';
}
