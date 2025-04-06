import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:simple_logger/simple_logger.dart';

import '../utilities/date.dart';
import '../models/debug.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/misc.dart';

final String _classString = '<st> AppState'.toLowerCase();

// sorting order
enum UsersSortOrder { byName, byRanking }

/// registers the state of the app
/// Saves users and parameters in Cache variables
/// Access to loggedUser
class AppState with ChangeNotifier {
  AppState() {
    MyLog.log(_classString, 'Constructor', level: Level.FINE);
  }

  /// attributes
  MyParameters _parametersCache = MyParameters();
  final List<MyUser> _usersCache = [];
  MyUser _loggedUser = MyUser();
  UsersSortOrder _usersSorting = UsersSortOrder.byName;

  /// make loggedUser=none
  void resetLoggedUser() => setLoggedUser(MyUser(), notify: false);

  void resetParameters() => setAllParameters(MyParameters(), notify: false);

  void resetUsers() => _usersCache.clear();

  /// reset state
  void reset() {
    resetParameters();
    resetUsers();
    resetLoggedUser();
  }

  /// parameter methods
  String getParamValue(ParametersEnum parameter) => _parametersCache.getStrValue(parameter);

  int? getIntParamValue(ParametersEnum parameter) => _parametersCache.getIntValue(parameter);

  bool getBoolParamValue(ParametersEnum parameter) => _parametersCache.getBoolValue(parameter);

  bool isDayPlayable(Date date) => _parametersCache.isDayPlayable(date);

  Date get maxDateOfMatchesToView =>
      Date.now().add(Duration(days: getIntParamValue(ParametersEnum.matchDaysToView) ?? 0));

  void setAllParametersAndNotify(MyParameters? myParameters) => setAllParameters(myParameters, notify: true);

  void setAllParameters(MyParameters? myParameters, {required bool notify}) {
    MyLog.log(_classString, 'setAllParameters $myParameters');
    _parametersCache = myParameters ?? MyParameters();
    MyLog.setDebugLevel(_parametersCache.minDebugLevel); // new level of debugging

    if (notify) notifyListeners();
  }

  /// user methods
  MyUser getLoggedUser() => _loggedUser;

  void setLoggedUser(MyUser user, {required bool notify}) {
    MyLog.log(_classString, 'setLoggedUser $user');

    _loggedUser = user;
    // update MyLog name and email
    MyLog.loggedUserId = _loggedUser.id;

    if (notify) notifyListeners();
  }

  void setLoggedUserById(String userId, {required bool notify}) {
    MyLog.log(_classString, 'setLoggedUserById user=$userId');

    MyUser? loggedUser = getUserById(userId);

    if (loggedUser == null) {
      MyLog.log(_classString, 'setLoggedUserById ERROR user=$userId not found', level: Level.SEVERE);
      throw Exception('User not found. User=$userId');
    }

    setLoggedUser(loggedUser, notify: notify);

    if (notify) notifyListeners();
  }

  void _sortUsersBold(UsersSortOrder sortBy) {
    MyLog.log(_classString, '_sortUsersBold sortBy=$sortBy');
    _usersSorting = sortBy;
    if (sortBy == UsersSortOrder.byName) {
      _usersCache.sort((a, b) => lowCaseNoDiacritics(a.name).compareTo(lowCaseNoDiacritics(b.name)));
    } else {
      _usersCache.sort((a, b) => b.rankingPos.compareTo(a.rankingPos));
    }
  }

  // sort by name or ranking
  void sortUsers({UsersSortOrder sortBy = UsersSortOrder.byName, bool notify = false}) {
    if (_usersSorting != sortBy) {
      _sortUsersBold(sortBy);
      if (notify) notifyListeners();
    } else {
      MyLog.log(_classString, 'sortUsers already sorted', indent: true);
    }
  }

  bool get isUsersSortedByName => _usersSorting == UsersSortOrder.byName;

  int get numUsers => _usersCache.length;

  List<MyUser> get users => List.from(_usersCache);

  // Modifies _usersCache in place
  // get users sorted by name or ranking
  List<MyUser> getSortedUsers({UsersSortOrder sortBy = UsersSortOrder.byName, bool notify = false}) {
    sortUsers(sortBy: sortBy, notify: notify);
    return List.from(_usersCache);
  }

  bool get isLoggedUserAdminOrSuper => [UserType.admin, UserType.superuser].contains(_loggedUser.userType);

  bool get isLoggedUserSuper => _loggedUser.userType == UserType.superuser;

  bool get showLog => getBoolParamValue(ParametersEnum.showLog);

  void setAllUsers(List<MyUser> users, {required bool notify}) {
    MyLog.log(_classString, 'setAllUsers users=$users');

    _usersCache.clear();
    _usersCache.addAll(users);
    _sortUsersBold(_usersSorting);

    // convert loggedUser
    setLoggedUserById(_loggedUser.id, notify: false);

    if (notify) notifyListeners();
  }

  void setChangedUsersAndNotify(List<MyUser> added, List<MyUser> modified, List<MyUser> removed) =>
      setChangedUsers(added, modified, removed, notify: true);

  void setChangedUsers(List<MyUser> added, List<MyUser> modified, List<MyUser> removed, {required bool notify}) {
    MyLog.log(_classString, 'setChangedUsers a=${added.length} m=${modified.length} r=${removed.length} ');

    if (added.isNotEmpty) {
      MyLog.log(_classString, 'setChangedUsers added $added ', indent: true);
      _usersCache.addAll(added);
    }
    if (modified.isNotEmpty) {
      MyLog.log(_classString, 'setChangedUsers modified $modified ', indent: true);
      for (var newUser in modified) {
        bool correct = _updateCachedUser(newUser);
        if (!correct) {
          MyLog.log(_classString, 'setChangedUsers user to modify not found $newUser ',
              level: Level.SEVERE, indent: true);
        }
      }
    }
    if (removed.isNotEmpty) {
      MyLog.log(_classString, 'setChangedUsers removed $removed ', indent: true);
      for (var newUser in removed) {
        MyLog.log(_classString, 'setChangedUsers REMOVED!!!: $newUser', indent: true);
        _usersCache.removeWhere((user) => user.id == newUser.id);
      }
    }

    _sortUsersBold(_usersSorting);
    if (notify) notifyListeners();
  }

  MyUser? getUserByName(String name) => _usersCache.firstWhereOrNull((user) => user.name == name);

  MyUser? getUserById(String id) => _usersCache.firstWhereOrNull((user) => user.id == id);

  MyUser? getUserByEmail(String email) => _usersCache.firstWhereOrNull((user) => user.email == email);

  /// search usersCache for newUserId
  /// if not found, return false
  /// if found copy all data from newUser to User
  bool _updateCachedUser(MyUser newUser) {
    MyLog.log(_classString, '_updateCachedUser. user = $newUser ');
    Set<MyUser> usersFound = _usersCache.where((user) => user.id == newUser.id).toSet();
    if (usersFound.isEmpty) {
      MyLog.log(_classString, '_updateCachedUser. No users found to update = $newUser ',
          level: Level.SEVERE, indent: true);
      return false;
    }
    if (usersFound.length > 1) {
      MyLog.log(_classString, '_updateCachedUser. More than 1 users found = $usersFound ',
          level: Level.SEVERE, indent: true);
    }
    for (var user in usersFound) {
      MyLog.log(_classString, '_updateCachedUser. Updating: $newUser ', indent: true);
      user.copyFrom(newUser);
    }
    return true;
  }

  @override
  String toString() => 'Parameters = $_parametersCache\n'
      '#users=${_usersCache.length}\n'
      'loggedUser=$_loggedUser';
}
