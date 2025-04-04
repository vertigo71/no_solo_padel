import 'dart:math';

import 'package:no_solo_padel/models/register_model.dart';
import 'package:simple_logger/simple_logger.dart';

import '../database/authentication.dart';
import '../database/firebase_helpers.dart';
import '../secret.dart';
import '../utilities/date.dart';
import '../utilities/misc.dart';
import 'app_state.dart';
import '../models/debug.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';

final String _classString = '<st> Director'.toLowerCase();

/// responsible for the flow of the app
/// knows about all processes
class Director {
  final AppState _appState;

  Director({required AppState appState}) : _appState = appState {
    MyLog.log(_classString, 'Constructor');
  }

  AppState get appState => _appState;

  /// signOut from all systems
  Future signOut() async {
    MyLog.log(_classString, 'SignOut');
    await FbHelpers().disposeListeners();
    _appState.reset();
    await AuthenticationHelper.signOut();
  }

  // update all users
  Future<void> updateAllUsers() async {
    MyLog.log(_classString, 'updateAllUsers', level: Level.FINE );
    List<MyUser> users = await FbHelpers().getAllUsers();
    _appState.setAllUsers(users, notify: true);
  }

  /// delete old logs and matches
  Future<void> deleteOldData() async {
    // delete old register logs & matches at the Firestore
    MyLog.log(_classString, 'deleteOldData: Deleting old logs and matches');
    FbHelpers().deleteOldData(
        RegisterFs.register.name, _appState.getIntParamValue(ParametersEnum.registerDaysKeeping) ?? -1);
    FbHelpers().deleteOldData(
        MatchFs.matches.name, _appState.getIntParamValue(ParametersEnum.matchDaysKeeping) ?? -1);
  }

  Future<void> createTestData() async {
    MyLog.log(_classString, 'createTestData');

    // create users if there are none
    if (_appState.numUsers == 0) {
      MyLog.log(_classString, 'createTestData: creating users', indent: true);

      // users
      const List<String> users = [
        'Victor',
        'Ricardo',
        '2Kram', // 2 means superuser
        'Juli',
        'Jesus',
        'Roberto',
        'Antonio',
        'Angel',
        '1Javi' // 1 means administrator
      ];
      RegExp reg = RegExp(r'^[0-9]');
      for (String user in users) {
        late MyUser myUser;
        if (reg.hasMatch(user)) {
          UserType userType = UserType.values[int.parse(user[0])];
          user = user.substring(1);
          myUser = MyUser(name: user, email: '$user${MyUser.emailSuffix}', id: user, userType: userType);
        } else {
          myUser = MyUser(name: user, email: '$user${MyUser.emailSuffix}', id: user);
        }
        // create users in Firestore Authentication
        await AuthenticationHelper.createUserWithEmailAndPwd(email: myUser.email, pwd: getInitialPwd());
        // update/create user in the Firestore database
        await FbHelpers().updateUser(myUser);
        // listener will update appState
        MyLog.log(_classString, '>>> createTestData: new user = $myUser', indent: true);
      }
    }

    // update ranking position for every user
    final users = _appState.users;
    final random = Random();
    for (MyUser user in users) {
      if (user.rankingPos == 0) {
        user.rankingPos = random.nextInt(10000);
        await FbHelpers().updateUser(user);
      }
    }

    MyLog.log(_classString, 'createTestData: creating matches', indent: true);
    // wait until there are users in the appState
    while (_appState.numUsers == 0) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    const int numMatches = 10;
    const int maxUsers = 10;
    for (int d = 0; d < numMatches; d += 2) {
      Date date = Date.now().add(Duration(days: d));
      // if match doesn't exist or is empty, create match
      MyMatch? match = await FbHelpers().getMatch(date.toYyyyMMdd(), _appState);
      if (match == null || match.playersReference.isEmpty) {
        List<int> randomInts = getRandomList(maxUsers, date);
        MyMatch match = MyMatch(id: date);
        match.comment = 'Las Tablas a las 10h30';
        match.isOpen = randomInts.first.isEven;
        match.courtNamesReference.addAll(randomInts.map((e) => e.toString()).take((d % 4) + 1)); // max 4 courts
        match.playersReference.addAll(randomInts.map((e) => users[e % users.length]).toSet());
        MyLog.log(_classString, 'createTestData: update match = $match', indent: true);
        await FbHelpers().updateMatch(match: match, updateCore: true, updatePlayers: true);
      }
    }
  }
}
