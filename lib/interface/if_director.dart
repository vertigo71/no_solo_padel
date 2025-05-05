import 'dart:math';

import 'package:simple_logger/simple_logger.dart';

import '../database/db_authentication.dart';
import '../database/db_firebase_helpers.dart';
import '../models/md_register.dart';
import '../models/md_result.dart';
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

  ///  erase register which date <= toDate
  ///  erase matches which date <= toDate
  ///  save a copy of users to historic
  ///  set all users ranking to default Ranking
  ///  update all users list of matches
  Future<void> resetApplication(int newRanking) async {
    Date toDate = Date.now();

    // keep today's match
    MyMatch? todayMatch = await FbHelpers().getMatch(toDate.toYyyyMmDd(), _appState);

    // erase all past register docs
    await FbHelpers().deleteDocsBatch(collection: RegisterFs.register.name, maxDocId: toDate.toYyyyMmDd());

    // erase all past matches. KEEP today's matches
    await FbHelpers().deleteDocsBatch(
      collection: MatchFs.matches.name,
      maxDocId: toDate.toYyyyMmDd(),
    );

    // erase all past userMatchResults
    await FbHelpers().deleteUserMatchResultTillDateBatch(maxMatchId: toDate.toYyyyMmDd());

    // erase all past results
    await FbHelpers().deleteGameResultsTillDateBatch(maxMatchId: toDate.toYyyyMmDd());

    // save all users to historic
    await FbHelpers().saveAllUsersToHistoric();

    // reset ranking and notify
    await FbHelpers().resetUsersBatch(newRanking: newRanking);
    // await _director.updateAllUsers(true); // no need. Listeners are called

    // create today's match if exited
    if (todayMatch != null) {
      await FbHelpers().createMatchIfNotExists(match: todayMatch, appState: _appState);
    }
  }

  /// a map that for each player gets a list of games won (true) and lost (false)
  Future<Map<MyUser, List<bool>>> playersLastTrophies() async {
    MyLog.log(_classString, 'playersLastTrophies', level: Level.FINE);
    final Map<MyUser, List<bool>> userTrophies = {};

    final List<GameResult> allResults = await FbHelpers().getAllGameResults(appState: _appState)
      ..sort((a, b) => b.id.resultId.compareTo(a.id.resultId)); // reverse order

    for (GameResult result in allResults) {
      MyLog.log(_classString, 'playersLastTrophies result=${result.id}', level: Level.FINE, indent: true);
      List<MyUser> players = result.winningPlayers;
      for (final MyUser player in players) {
        if (!userTrophies.containsKey(player)) userTrophies[player] = [];
        userTrophies[player]?.add(true);
      }
      players = result.loosingPlayers;
      for (final MyUser player in players) {
        if (!userTrophies.containsKey(player)) userTrophies[player] = [];
        userTrophies[player]?.add(false);
      }
    }

    return userTrophies;
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
    final readOnlyUsers = _appState.usersSortedByName;
    final random = Random();
    for (MyUser user in readOnlyUsers) {
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
      if (match == null || match.players.isEmpty) {
        List<int> randomInts = getRandomList(kMaxUsers, date);
        MyMatch match = MyMatch(id: date, comment: 'Partido de prueba');
        match.isOpen = deltaDays < 0 ? true : randomInts.first.isEven;
        match.addAllCourtNames(randomInts.map((e) => e.toString()).take((deltaDays % 4) + 1)); // max 4 courts
        match.addAllPlayers(randomInts.map((e) => readOnlyUsers[e % readOnlyUsers.length]).toSet());
        MyLog.log(_classString, 'createTestData: create match = $match', indent: true);
        await FbHelpers().createMatchIfNotExists(match: match, appState: _appState);
      }
    }
  }
}
