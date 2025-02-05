import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
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

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    MyLog().log(_classString, '_LoadingState:initState', debugType: DebugType.warning);
    _initialize();
  }

  Future<void> _initialize() async {
    MyLog().log(_classString, '_initialize');
    try {
      AppState appState = context.read<AppState>();
      if (appState.getLoggedUser().userId != "") {
        // there is already an user logged.
        // it shouldn't be logged
        // this happens in web browser going back from mainPAge
        MyLog().log(_classString, 'user=${appState.getLoggedUser().userId}. Going back to login page',
            debugType: DebugType.warning);
        if (mounted) {
          await AuthenticationHelper()
              .signOut(signedOutFunction: context.read<Director>().firebaseHelper.disposeListeners);
          appState.deleteAll();
          MyLog().log(_classString, 'Going back to main...');
          if (mounted) context.goNamed(AppRoutes.login);
        }
      } else {
        bool ok = await setupDB(context);
        if (mounted) {
          if (!ok) {
            showMessage(context, 'Usuario no registrado. Hable con el administrador.');
            context.pop();
          } else {
            context.pushReplacementNamed(AppRoutes.main);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'No se ha podido inicializar. \n$e');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SpinKitFadingCube(
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> setupDB(BuildContext context) async {
    MyLog().log(_classString, '_LoadingState:Setting DB', debugType: DebugType.warning);
    AppState appState = context.read<AppState>();
    Director director = context.read<Director>();
    FirebaseHelper firebaseHelper = director.firebaseHelper;

    /// restart error logs
    MyLog().delete;

    User? user = AuthenticationHelper().user;
    if (user == null || user.email == null) {
      throw Exception('Error: No se ha registrado correctamente el usuario. \n'
          'Póngase en contacto con el administrador');
    }
    MyLog().log(_classString, 'setupDB authenticated user = ${user.email}', debugType: DebugType.warning);

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
      MyLog().log(_classString, 'setupDB user: ${user.email}  not registered. Abort!', debugType: DebugType.warning);
      await AuthenticationHelper().signOut(signedOutFunction: firebaseHelper.disposeListeners);
      return false; // user doesn't exist
    } else {
      appState.setLoggedUser(loggedUser, notify: false);
      loggedUser.lastLogin = Date.now();
      loggedUser.loginCount++;
      await firebaseHelper.updateUser(loggedUser);

      /// (async) check the integrity of the database
      director.checkUsersInMatches(delete: false);

      /// create matches if missing
      /// from now to now+matchDaysToView
      for (int days = 0; days < appState.getIntParameterValue(ParametersEnum.matchDaysToView); days++) {
        Date date = Date.now().add(Duration(days: days));
        await firebaseHelper.createMatchIfNotExists(match: MyMatch(date: date));
      }

      // create listeners async
      director.createListeners();

      // all gone ok
      return true;
    }
  }
}
