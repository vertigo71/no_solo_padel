import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:no_solo_padel_dev/utilities/environment.dart';
import 'package:provider/provider.dart';

import '../database/authentication.dart';
import '../database/firestore_helpers.dart';
import '../interface/app_state.dart';
import '../interface/director.dart';
import '../models/debug.dart';
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
    // TODO: verify it's called everytime loading is created
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Context Available: addPostFrameCallback ensures that the callback is executed
    //   // after the first frame is built,
    //   // so the BuildContext is available and providers are initialized.
    //   MyLog.log(_classString, '_LoadingState:initState');
    //   _initialize();
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyLog.log(_classString, 'didChangeDependencies to be called ONLY ONCE');
    _initialize();
  }


  Future<void> _initialize() async {
    MyLog.log(_classString, '_initialize');
    try {
      AppState appState = context.read<AppState>();
      if (appState.getLoggedUser().id != "") {
        // there is already an user logged.
        // it shouldn't be logged
        // this happens in web browser going back from mainPAge
        MyLog.log(_classString, 'user=${appState.getLoggedUser().id}. Going back to login page', level: Level.WARNING, indent: true);
        if (mounted) {
          await AuthenticationHelper.signOut();
          appState.resetLoggedUser();
          MyLog.log(_classString, '_initialize Going back to main...', indent: true);
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
    MyLog.log(_classString, 'Setting DB');
    AppState appState = context.read<AppState>();
    Director director = context.read<Director>();
    FsHelpers fsHelpers = director.fsHelpers;

    User? user = AuthenticationHelper.user;
    if (user == null || user.email == null) {
      MyLog.log(_classString, 'setupDB user not authenticated = $user', level: Level.SEVERE, indent: true);
      throw Exception('Error: No se ha registrado correctamente el usuario. \n'
          'Póngase en contacto con el administrador');
    }
    MyLog.log(_classString, 'setupDB authenticated user = ${user.email}', level: Level.INFO, indent: true);

    //  delete old logs and matches
    director.deleteOldData();

    //
    // create test data
    // do only once for populating
    if (Environment().isDevelopment) await director.createTestData( );

    // get loggedUser
    MyUser? loggedUser = appState.getUserByEmail(user.email!);
    if (loggedUser == null) {
      // user is not in the DB
      MyLog.log(_classString, 'setupDB user: ${user.email}  not registered. Abort!', level: Level.SEVERE, indent: true);
      await AuthenticationHelper.signOut();
      appState.resetLoggedUser();
      return false; // user doesn't exist
    } else {
      appState.setLoggedUser(loggedUser, notify: false);
      loggedUser.lastLogin = Date.now();
      loggedUser.loginCount++;
      await fsHelpers.updateUser(loggedUser);

      // (async) check the integrity of the database
      // director.checkUsersInMatches(delete: false); TODO:erase

      // create matches if missing
      // from now to now+matchDaysToView
      for (int days = 0; days < appState.getIntParameterValue(ParametersEnum.matchDaysToView); days++) {
        Date date = Date.now().add(Duration(days: days));
        await fsHelpers.createMatchIfNotExists(matchId: date);
      }

      // all gone ok
      return true;
    }
  }
}
