import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../utilities/date.dart';
import '../models/debug.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';

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

  List<MyUser> getAllUsers() => _allUsers;

  List<MyUser> get allSortedUsers {
    _allUsers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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

    // convert old users in matches to new users
    _convertUsersInMatches();

    // convert loggedUser
    setLoggedUserById(_loggedUser.userId, notify: false);

    if (notify) notifyListeners();
  }

  // convert old users in matches to new users
  void _convertUsersInMatches() {
    MyLog().log(_classString, '_convertUsersInMatches');
    for (var match in _allMatches) {
      List<String> matchUserIds = match.players.map((player) => player.userId).toList();
      List<MyUser> usersInMatch = matchUserIds
          .map((id) => _allUsers.firstWhereOrNull((user) => user.userId == id))
          .whereType<MyUser>()
          .toList();

      if (matchUserIds.length != usersInMatch.length) {
        MyLog().log(
            _classString,
            '_convertUsersInMatches Match date=${match.date}; original players=${matchUserIds.length}; '
            ' final players=${usersInMatch.length}');
      }
      match.players.clear();
      match.players.addAll(usersInMatch);
    }
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
    for (var newUser in added) {
      removeUserByIdBold(newUser.userId);
      MyLog().log(_classString, 'setChangedUsers adding', myCustomObject: newUser);
      _allUsers.add(newUser);
    }
    for (var newUser in removed) {
      removeUserByIdBold(newUser.userId);
    }

    // convert old users in matches to new users
    _convertUsersInMatches();

    // convert loggedUser
    setLoggedUserById(_loggedUser.userId, notify: false);

    if (notify) notifyListeners();
  }

  void setAllMatches(List<MyMatch> matches, {bool verifyUsers = false, required bool notify}) {
    MyLog().log(_classString, 'setAllMatches In number = ${matches.length}');

    _allMatches.clear();
    _allMatches.addAll(matches.where((element) => isDayPlayable(element.date)));
    MyLog()
        .log(_classString, 'setAllMatches', myCustomObject: _allMatches, debugType: DebugType.info);
    if (verifyUsers) _convertUsersInMatches();
    if (notify) notifyListeners();
  }

  void setChangedMatchesAndNotify(
          List<MyMatch> added, List<MyMatch> modified, List<MyMatch> removed) =>
      setChangedMatches(added, modified, removed, verifyUsers: false, notify: true);

  void setChangedMatches(List<MyMatch> added, List<MyMatch> modified, List<MyMatch> removed,
      {required bool verifyUsers, required bool notify}) {
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
      removeMatchByDateBold(newMatch.date);
      if (isDayPlayable(newMatch.date)) {
        MyLog().log(_classString, 'setChangedMatches adding',
            myCustomObject: newMatch, debugType: DebugType.info);
        _allMatches.add(newMatch);
      }
    }
    for (var newMatch in removed) {
      removeMatchByDateBold(newMatch.date);
    }

    if (verifyUsers) _convertUsersInMatches();
    if (notify) notifyListeners();
  }

  MyUser? getUserByName(String name) {
    for (var element in allUsers) {
      if (element.name == name) {
        return element;
      }
    }
    return null;
  }

  MyUser? getUserById(String id) {
    List<MyUser> _users = _allUsers.where((user) => user.userId == id).toList();
    if (_users.isEmpty) {
      return null;
    } else {
      return _users.first;
    }
  }

  bool removeUserByIdBold(String id) {
    MyLog().log(_classString, 'removeUserByIdBold', myCustomObject: id);

    MyUser? user = getUserById(id);
    if (user == null) return false;
    return _allUsers.remove(user);
  }

  bool removeMatchByDateBold(Date date) {
    MyLog().log(_classString, 'removeMatchByDateBold', myCustomObject: date);

    MyMatch? match = getMatch(date);
    if (match == null) return false;
    return _allMatches.remove(match);
  }

  MyUser? getUserByEmail(String email) {
    for (var element in allUsers) {
      if (element.email == email) {
        return element;
      }
    }
    return null;
  }

  /// return null if exists
  /// unique name, email and id
  MyUser? createNewUserByEmail(String email) {
    MyLog().log(_classString, 'createNewUserByEmail', myCustomObject: email);

    MyUser? user = getUserByEmail(email);
    if (user != null) return null; // already exists

    // get name from email
    List<String> items = email.split('@') ;
    if ( items.length != 2 ) return null; // incorrect format
    String name = items[0];

    user = MyUser(name: name, email: email, userId: name, userType: UserType.basic);
    // check name and userId don't already exist
    MyUser? userExists = getUserByName(user.name);
    if (userExists != null) {
      int i = 0;
      final String baseName = user.name;
      while (userExists != null) {
        user.name = '$baseName${i++}'; // create new name
        userExists = getUserByName(user.name);
      }
    }
    userExists = getUserById(user.userId);
    if (userExists != null) {
      int i = 0;
      final String baseName = user.userId;
      while (userExists != null) {
        user.userId = '$baseName${i++}'; // create new id
        userExists = getUserById(user.userId);
      }
    }
    MyLog().log(_classString, 'createNewUserByEmail new User = $user');
    return user;
  }

  MyMatch? getMatch(Date date) {
    for (var match in allMatches) {
      if (match.date == date) {
        return match;
      }
    }
    return null;
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
