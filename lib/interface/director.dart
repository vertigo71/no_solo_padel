
import 'package:cloud_firestore/cloud_firestore.dart';

import '../database/authentication.dart';
import '../database/fields.dart';
import '../database/firebase.dart';
import '../secret.dart';
import '../utilities/date.dart';
import '../utilities/misc.dart';
import 'app_state.dart';
import '../models/debug.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';

final String _classString = 'Director'.toUpperCase();

class Director {
  final AppState _appState;
  final FirebaseHelper firebaseHelper = FirebaseHelper();

  Director({required AppState appState}) : _appState = appState {
    MyLog().log(_classString, 'Building');

    // check Enums parameters in AppState are in FirebaseHelper
    String fieldsValues = DBFields.values.join(';');
    for (var value in ParametersEnum.values) {
      assert(fieldsValues.contains(value.name));
    }
  }

  /// delete local model
  /// download parameters & users
  /// delete old logs
  Future<void> initialize() async {
    MyLog().log(_classString, 'Initializing');

    _appState.deleteAll();

    // download parameters from DB into local
    MyLog().log(_classString, 'Parameters');
    MyParameters? myParameters = await firebaseHelper.downloadParameters();
    _appState.setAllParameters(myParameters, notify: false);

    // download users from DB into local
    MyLog().log(_classString, 'Users');
    List<MyUser> users = await firebaseHelper.downloadUsers();
    _appState.setAllUsers(users, notify: false);

    // matches will be downloaded by createListeners

    // delete old logs & matches
    MyLog().log(_classString, 'Deleting old logs and matches');
    await firebaseHelper.deleteOldData(
        DBFields.register, _appState.getIntParameterValue(ParametersEnum.registerDaysKeeping));
    await firebaseHelper.deleteOldData(
        DBFields.matches, _appState.getIntParameterValue(ParametersEnum.matchDaysKeeping));
  }

  Future<void> createListeners() async {
    MyLog().log(_classString, 'createListeners');
    firebaseHelper.createListeners(
      fromDate: Date.now(),
      numDays: _appState.getIntParameterValue(ParametersEnum.matchDaysToView),
      availableUsers: _appState.getAllUsers,
      parametersFunction: _appState.setAllParametersAndNotify,
      usersFunction: _appState.setChangedUsersAndNotify,
      matchesFunction: _appState.setChangedMatchesAndNotify,
    );
  }

  Future<void> updateDataToNewFormat() async {
    // register
    {
      QuerySnapshot<Map<String, dynamic>> registers =
          await FirebaseFirestore.instance.collection(strDB(DBFields.register)).get();
      MyLog().log(_classString, 'updateDataToNewFormat: processing ${registers.size} registers');
      for (var documentSnapshot in registers.docs) {
        await FirebaseFirestore.instance
            .collection(strDB(DBFields.register))
            .doc(documentSnapshot.id)
            .update({DBFields.date.name: documentSnapshot.id});
      }
    }

    // users
    {
      QuerySnapshot<Map<String, dynamic>> users =
          await FirebaseFirestore.instance.collection(strDB(DBFields.users)).get();
      MyLog().log(_classString, 'updateDataToNewFormat: processing ${users.size} users');
      for (var documentSnapshot in users.docs) {
        await FirebaseFirestore.instance
            .collection(strDB(DBFields.users))
            .doc(documentSnapshot.id)
            .update({DBFields.userId.name: documentSnapshot.id});
      }
    }

    // matches
    {
      QuerySnapshot<Map<String, dynamic>> matches =
          await FirebaseFirestore.instance.collection(strDB(DBFields.matches)).get();
      MyLog().log(_classString, 'updateDataToNewFormat: processing ${matches.size} matches');
      for (var documentSnapshot in matches.docs) {
        await FirebaseFirestore.instance
            .collection(strDB(DBFields.matches))
            .doc(documentSnapshot.id)
            .update({DBFields.date.name: documentSnapshot.id});
      }
    }
  }

  Future<void> createTestData({bool users = false, bool matches = false}) async {
    MyLog().log(_classString, 'createTestData');

    if (users) {
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
          myUser = MyUser(
              name: user, email: '$user${MyUser.emailSuffix}', userId: user, userType: userType);
        } else {
          myUser = MyUser(name: user, email: '$user${MyUser.emailSuffix}', userId: user);
        }
        await AuthenticationHelper()
            .createUserWithEmailAndPwd(email: myUser.email, pwd: initialPwd);
        await firebaseHelper.uploadUser(myUser);
      }
      MyLog().log(_classString, 'Users');
      List<MyUser> allUsers = await firebaseHelper.downloadUsers();
      _appState.setAllUsers(allUsers, notify: false);
    }

    if (matches) {
      List<MyUser> users = _appState.allUsers;
      assert(users.isNotEmpty);
      const int numMatches = 10;
      const int maxUsers = 10;
      for (int d = 0; d < numMatches; d++) {
        Date date = Date.now().add(Duration(days: d));
        List<int> randomInts = getRandomList(maxUsers, date);
        MyMatch match = MyMatch(date: date);
        match.comment = 'Las Tablas a las 10h30';
        match.isOpen = randomInts.first.isEven;
        match.courtNames.addAll(randomInts.map((e) => e.toString()).take((d % 4) + 1));
        match.players.addAll(randomInts.map((e) => users[e % users.length]).toSet());
        MyLog().log(_classString, 'createTestData $match');
        await firebaseHelper.uploadMatch(match: match, updateCore: true, updatePlayers: true);
      }
    }
  }
}
