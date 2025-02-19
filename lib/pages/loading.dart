import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../database/authentication.dart';
import '../database/firestore_helpers.dart';
import '../interface/app_state.dart';
import '../interface/director.dart';
import '../models/debug.dart';
import '../models/parameter_model.dart';
import '../models/user_model.dart';
import '../utilities/date.dart';
import '../utilities/environment.dart';
import '../utilities/misc.dart';
import '../routes/routes.dart';

// Class name for logging purposes
final String _classString = 'Loading'.toUpperCase();

/// Loading page widget displayed while the app initializes.
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();

    MyLog.log(_classString, 'initState to be called ONLY ONCE');
    _initialize(); // Call the initialization method.
  }

  /// Initializes the app by checking authentication status and setting up the database.
  Future<void> _initialize() async {
    MyLog.log(_classString, '_initialize');
    try {
      AppState appState = context.read<AppState>();
      // Check if a user is already logged in (unexpected on the loading page).
      if (appState.getLoggedUser().id != "") {
        // there is already an user logged.
        // it shouldn't be logged
        // this happens in web browser going back from mainPAge
        MyLog.log(_classString, 'user=${appState.getLoggedUser().id}. Going back to login page', level: Level.WARNING, indent: true);
        // Sign out the user and navigate to the login page.
        if (mounted) {
          await AuthenticationHelper.signOut();
          appState.resetLoggedUser();
          MyLog.log(_classString, '_initialize Going back to main...', indent: true);
          if (mounted) context.goNamed(AppRoutes.login);
        }
      } else {
        // No user is logged in, proceed with database setup.
        bool ok = await setupDB(context);
        if (mounted) {
          if (!ok) {
            showMessage(context, 'Usuario no registrado. Hable con el administrador.');
            context.pop(); // Navigate back if setup fails.
          } else {
            context.pushReplacementNamed(AppRoutes.main); // Navigate to the main page.
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, 'No se ha podido inicializar. \n$e');
        context.pop(); // Navigate back if an error occurs.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the loading screen UI.
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SpinKitFadingCube( // Loading indicator.
              color: Colors.blue,
              size: 50.0,
            ),
            SizedBox(height: 20),
            Text( // Loading text.
              'Loading...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Sets up the database by authenticating the user and retrieving their data.
  /// Returns `true` if setup is successful, `false` otherwise.
  Future<bool> setupDB(BuildContext context) async {
    MyLog.log(_classString, 'Setting DB');
    AppState appState = context.read<AppState>();
    Director director = context.read<Director>();
    FsHelpers fsHelpers = director.fsHelpers;

    User? user = AuthenticationHelper.user;
    // Check if the user is authenticated.
    if (user == null || user.email == null) {
      MyLog.log(_classString, 'setupDB user not authenticated = $user', level: Level.SEVERE, indent: true);
      throw Exception('Error: No se ha registrado correctamente el usuario. \n'
          'Póngase en contacto con el administrador');
    }
    MyLog.log(_classString, 'setupDB authenticated user = ${user.email}', level: Level.INFO, indent: true);

    director.deleteOldData(); // Delete old logs and matches.

    if (Environment().isDevelopment) await director.createTestData(); // Create test data in development mode.

    MyUser? loggedUser = appState.getUserByEmail(user.email!);
    if (loggedUser == null) {
      // User not found in the database.
      MyLog.log(_classString, 'setupDB user: ${user.email}  not registered. Abort!', level: Level.SEVERE, indent: true);
      await AuthenticationHelper.signOut();
      appState.resetLoggedUser();
      return false;
    } else {
      // User found in the database.
      appState.setLoggedUser(loggedUser, notify: false);
      loggedUser.lastLogin = Date.now();
      loggedUser.loginCount++;
      await fsHelpers.updateUser(loggedUser);

      // Create matches for the next few days.
      for (int days = 0; days < appState.getIntParameterValue(ParametersEnum.matchDaysToView); days++) {
        Date date = Date.now().add(Duration(days: days));
        await fsHelpers.createMatchIfNotExists(matchId: date);
      }

      return true; // Setup successful.
    }
  }
}
