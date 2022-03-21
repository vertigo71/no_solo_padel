import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../database/authentication.dart';
import '../database/firebase.dart';
import '../interface/app_state.dart';
import '../interface/director.dart';
import '../models/debug.dart';
import '../models/match_model.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/date.dart';
import '../utilities/misc.dart';
import '../routes/routes.dart';

final String _classString = 'Loading'.toUpperCase();

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  void setupDB(BuildContext context) async {
    MyLog().log(_classString, 'Setting DB', debugType: DebugType.info);

    /// restart error logs
    MyLog().delete;

    User? user = AuthenticationHelper().user;
    if (user == null || user.email == null) {
      throw Exception('Error: No se ha registrado correctamente el usuario. \n'
          'Póngase en contacto con el administrador');
    }
    MyLog()
        .log(_classString, 'setupDB authenticated user = ${user.email}', debugType: DebugType.info);

    AppState appState = context.read<AppState>();
    Director director = context.read<Director>();
    FirebaseHelper firebaseHelper = director.firebaseHelper;

    /// delete local model, download parameters and delete old logs
    await director.initialize();

    ///
    /// create test data
    /// do only once for populating
    ///
    /// await director.createTestData(users: true, matches: false);

    // loggedUser
    MyUser? loggedUser = await firebaseHelper.getUserByEmail(user.email!);
    if (loggedUser == null) {
      // user is not in the DB
      MyLog().log(_classString, 'setupDB user not registered = ${user.email}',
          debugType: DebugType.info);
      await AuthenticationHelper().signOut(signedOutFunction: firebaseHelper.disposeListeners);
      _addPostFrame(function: () {
        showMessage(context, 'Usuario no registrado. Hable con el administrador.');
        Navigator.pop(context);
      });
    } else {
      appState.setLoggedUser(loggedUser, notify: false);
      loggedUser.lastLogin = Date.now();
      loggedUser.loginCount++;
      await firebaseHelper.updateUser(loggedUser);

      /// (async) check the integrity of the database
      director.checkUsersInMatches(delete: true);

      /// create matches if missing
      /// from now to now+matchDaysToView
      for (int days = 0;
          days < appState.getIntParameterValue(ParametersEnum.matchDaysToView);
          days++) {
        Date date = Date.now().add(Duration(days: days));
        await firebaseHelper.createMatchIfNotExists(match: MyMatch(date: date));
      }

      // create listeners
      director.createListeners();

      // wait till build method has completed
      _addPostFrame(
          function: () =>
              Navigator.pushReplacementNamed(context, RouteManager.mainPage, arguments: {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    setupDB(context);
    return Scaffold(
        backgroundColor: Colors.blue[900],
        body: const Center(
            child: SpinKitFadingCube(
          color: Colors.white,
          size: 50.0,
        )));
  }
}

void _addPostFrame({required Function function}) {
  // wait till build method has completed
  var instance = WidgetsBinding.instance;
  if (instance == null) {
    function();
  } else {
    MyLog().log(_classString, '_addPostFrame WidgetsBinding waiting');
    instance.addPostFrameCallback((_) => function());
  }
}
