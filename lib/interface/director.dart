import 'package:flutter/foundation.dart';

import '../database/authentication.dart';
import '../database/fields.dart';
import '../database/firestore_helpers.dart';
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
  final FsHelpers _fsHelpers = FsHelpers();

  Director({required AppState appState}) : _appState = appState {
    MyLog.log(_classString, 'Constructor');

    // check Enums parameters in AppState are in FirebaseHelper
    if (kDebugMode) {
      String fieldsValues = DBFields.values.join(';');
      for (var value in ParametersEnum.values) {
        assert(fieldsValues.contains(value.name));
      }
    }
  }

  AppState get appState => _appState;

  FsHelpers get fsHelpers => _fsHelpers;

  /// signOut from all systems
  Future signOut() async {
    MyLog.log(_classString, 'SignOut');
    _appState.resetLoggedUser();
    _fsHelpers.disposeListeners();
    AuthenticationHelper.signOut();
  }

  /// delete old logs and matches
  Future<void> deleteOldData() async {
    // delete old register logs & matches at the Firestore
    MyLog.log(_classString, 'deleteOldData: Deleting old logs and matches');
    fsHelpers.deleteOldData(DBFields.register, _appState.getIntParameterValue(ParametersEnum.registerDaysKeeping));
    fsHelpers.deleteOldData(DBFields.matches, _appState.getIntParameterValue(ParametersEnum.matchDaysKeeping));
  }

  Future<void> createTestData() async {
    MyLog.log(_classString, 'createTestData');

    if (_appState.numUsers == 0) {
      MyLog.log(_classString, 'createTestData: creating users', indent: true );

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
        await fsHelpers.updateUser(myUser);
        // listener will update appState
        MyLog.log(_classString, '>>> createTestData: new user = $myUser', indent: true );
      }
    }

    MyLog.log(_classString, 'createTestData: creating matches', indent: true );
    // wait until there are users in the appState
    while (_appState.numUsers == 0) {
      await Future.delayed(const Duration(milliseconds: 5));
    }
    const int numMatches = 10;
    const int maxUsers = 10;
    final users = _appState.users;
    for (int d = 0; d < numMatches; d++) {
      Date date = Date.now().add(Duration(days: d));
      // if match doesn't exist or is empty, create match
      MyMatch? match = await _fsHelpers.getMatch(date.toYyyyMMdd(), _appState);
      if (match == null || match.players.isEmpty) {
        List<int> randomInts = getRandomList(maxUsers, date);
        MyMatch match = MyMatch(id: date);
        match.comment = 'Las Tablas a las 10h30';
        match.isOpen = randomInts.first.isEven;
        match.courtNames.addAll(randomInts.map((e) => e.toString()).take((d % 4) + 1)); // max 4 courts
        match.players.addAll(randomInts.map((e) => users[e % users.length]).toSet());
        MyLog.log(_classString, 'createTestData: update match = $match', indent: true );
        await fsHelpers.updateMatch(match: match, updateCore: true, updatePlayers: true);
      }
    }
  }
}
