import 'dart:math';

import 'package:simple_logger/simple_logger.dart';

import '../database/db_authentication.dart';
import '../database/db_firebase_helpers.dart';
import '../secret.dart';
import '../models/md_date.dart';
import '../utilities/ut_misc.dart';
import 'if_app_state.dart';
import '../models/md_debug.dart';
import '../models/md_match.dart';
import '../models/md_user.dart';

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

  // set loggedUser
  Future<void> setLoggedUser(MyUser user) async {
    MyLog.log(_classString, 'setLoggedUser user=$user');
    _appState.setLoggedUser(user, notify: false);
    user.lastLogin = Date.now();
    user.loginCount++;
    await FbHelpers().updateUser(user);
  }

  // update all users
  Future<void> updateAllUsers(bool notify) async {
    MyLog.log(_classString, 'updateAllUsers');
    List<MyUser> users = await FbHelpers().getAllUsers();
    _appState.setAllUsers(users, notify: notify);
  }

  Future<void> createTestData() async {
    MyLog.log(_classString, 'createTestData', level: Level.FINE);

    // create users if there are none
    if (_appState.numUsers == 0) {
      MyLog.log(_classString, 'createTestData: creating users', indent: true);

      // users
      const List<String> kUsers = [
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
      for (String user in kUsers) {
        late MyUser myUser;
        if (reg.hasMatch(user)) {
          UserType userType = UserType.values[int.parse(user[0])];
          user = user.substring(1);
          myUser = MyUser(name: user, email: '$user${MyUser.kEmailSuffix}', id: user, userType: userType);
        } else {
          myUser = MyUser(name: user, email: '$user${MyUser.kEmailSuffix}', id: user);
        }
        // create users in Firestore Authentication
        await AuthenticationHelper.createUserWithEmailAndPwd(email: myUser.email, pwd: getInitialPwd());
        // update/create user in the Firestore database
        await FbHelpers().updateUser(myUser);
        // listener will update appState
        MyLog.log(_classString, '>>> createTestData: new user = $myUser', indent: true);
      }
    }

    // update ranking position for every user if ranking = 0
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
    const int kNumMatches = 10;
    const int kMaxUsers = 10;
    for (int i = 0; i < kNumMatches / 2; i++) {
      var deltaDays = -kNumMatches + Random().nextInt(2 * kNumMatches); // between -kNumMatches and kNumMatches
      Date date = Date.now().add(Duration(days: deltaDays));
      // if match doesn't exist or is empty, create match
      MyMatch? match = await FbHelpers().getMatch(date.toYyyyMmDd(), _appState);
      if (match == null || match.playersReference.isEmpty) {
        List<int> randomInts = getRandomList(kMaxUsers, date);
        MyMatch match = MyMatch(id: date, comment: 'Partido de prueba');
        match.isOpen = deltaDays < 0 ? true : randomInts.first.isEven;
        match.courtNamesReference.addAll(randomInts.map((e) => e.toString()).take((deltaDays % 4) + 1)); // max 4 courts
        match.playersReference.addAll(randomInts.map((e) => users[e % users.length]).toSet());
        MyLog.log(_classString, 'createTestData: create match = $match', indent: true);
        await FbHelpers().updateMatch(match: match, updateCore: true, updatePlayers: true);
      }
    }
  }
}
