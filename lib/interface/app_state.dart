import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:simple_logger/simple_logger.dart';

import '../utilities/date.dart';
import '../models/debug.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/transformation.dart';

final String _classString = '<st> AppState'.toLowerCase();

/// registers the state of the app
/// Saves users and parameters in Cache variables
/// Access to loggedUser
class AppState with ChangeNotifier {
  AppState() {
    MyLog.log(_classString, 'Constructor');
  }

  /// attributes
  MyParameters _parametersCache = MyParameters();
  final List<MyUser> _usersCache = [];
  MyUser _loggedUser = MyUser();

  /// make loggedUser=none
  void resetLoggedUser() => setLoggedUser(MyUser(), notify: false);

  /// parameter methods
  String getParameterValue(ParametersEnum parameter) => _parametersCache.getStrValue(parameter);

  int? getIntParameterValue(ParametersEnum parameter) => _parametersCache.getIntValue(parameter);

  bool getBoolParameterValue(ParametersEnum parameter) => _parametersCache.getBoolValue(parameter);

  bool isDayPlayable(Date date) => _parametersCache.isDayPlayable(date);

  Date get maxDateOfMatchesToView =>
      Date.now().add(Duration(days: getIntParameterValue(ParametersEnum.matchDaysToView) ?? 0));

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

    MyUser loggedUser = getUserById(userId) ??
        () {
          // lambda expression
          MyLog.log(_classString, 'setLoggedUserById ERROR user=$userId not found', indent: true, level: Level.SEVERE);
          return MyUser(id: userId);
        }();

    setLoggedUser(loggedUser, notify: notify);

    MyLog.log(_classString, 'setLoggedUserById loggedUser=$loggedUser', indent: true);
    if (notify) notifyListeners();
  }

  int get numUsers => _usersCache.length;

  List<MyUser> get users => List.from(_usersCache);

  void _sortUsers() => _usersCache.sort((a, b) => lowCaseNoDiacritics(a.name).compareTo(lowCaseNoDiacritics(b.name)));

  bool get isLoggedUserAdmin => [UserType.admin, UserType.superuser].contains(_loggedUser.userType);

  bool get isLoggedUserSuper => _loggedUser.userType == UserType.superuser;

  bool get showLog => getBoolParameterValue(ParametersEnum.showLog);

  void setAllUsers(List<MyUser> users, {required bool notify}) {
    MyLog.log(_classString, 'setAllUsers users=$users');

    _usersCache.clear();
    _usersCache.addAll(users);

    // convert loggedUser
    setLoggedUserById(_loggedUser.id, notify: false);

    // sort
    _sortUsers();

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
        removeUserByIdBold(newUser.id);
      }
    }

    // sort users
    _sortUsers();

    if (notify) notifyListeners();
  }

  MyUser? getUserByName(String name) => _usersCache.firstWhereOrNull((user) => user.name == name);

  MyUser? getUserById(String id) => _usersCache.firstWhereOrNull((user) => user.id == id);

  MyUser? getUserByEmail(String email) => _usersCache.firstWhereOrNull((user) => user.email == email);

  void removeUserByIdBold(String id) => _usersCache.removeWhere((user) => user.id == id);

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
