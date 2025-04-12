import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/db_authentication.dart';
import '../../database/db_firebase_helpers.dart';
import '../../interface/if_app_state.dart';
import '../../interface/if_director.dart';
import '../../models/md_debug.dart';
import '../../models/md_user.dart';
import '../../routes/routes.dart';
import '../../models/md_date.dart';
import '../../utilities/ut_environment.dart';
import '../../utilities/ui_helpers.dart';
import 'games.dart';
import 'information/information.dart';
import 'profile.dart';
import 'results/results.dart';

final String _classString = 'MainPage'.toUpperCase();

/// this page is called once a user has logged in
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // AppBar selected item
  String? _errorMessage;
  late Director _director;

  static const List<Widget> _kWidgetOptions = <Widget>[
    GamesPanel(),
    ResultsPanel(),
    InformationPanel(),
    ProfilePanel(),
  ];

  @override
  void initState() {
    MyLog.log(_classString, 'initState', level: Level.FINE);
    super.initState();
    _director = context.read<Director>();
    // initialize data
    _initialize();
  }

  /// dispose the listeners when the widget is removed
  @override
  void dispose() {
    MyLog.log(_classString, 'dispose');
    FbHelpers().disposeListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Consumer<AppState>(builder: (context, appState, child) {
      if (_errorMessage != null) {
        // there is an error
        MyLog.log(_classString, 'build error message =$_errorMessage', indent: true);
        return _buildErrorMessage();
      } else if (appState.loggedUser == null) {
        // no logged user saved in appState
        MyLog.log(_classString, 'build without logged user', indent: true);
        // set loggedUser if exists
        if (AuthenticationHelper.user != null) {
          // try to link appState.user to AuthenticationHelper.user
          MyUser? user = appState.getUserByEmail(AuthenticationHelper.user!.email!);
          if (user != null) {
            // User found in appState.
            MyLog.log(_classString, 'LoggedUser found in appState = $user', indent: true);
            appState.setLoggedUser(user, notify: false);
            user.lastLogin = Date.now();
            user.loginCount++;
            FbHelpers().updateUser(user); // listener will modify appState and rebuild Consumer

            // Create test data in development mode.
            // MyLog.log(_classString, '_initializeData creating test data in development ...', indent: true);
            if (Environment().isDevelopment) _director.createTestData();
          }
        }
        return _buildLoadingIndicator('Cargando ...'); // Still loading, no error
      } else {
        MyLog.log(_classString, 'build with logged user loggedUser=${appState.loggedUser}', indent: true);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            // if back is pressed, user will be signedOut
            await _onBackPressed();
          },
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: _kWidgetOptions.elementAt(_selectedIndex),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
        );
      }
    });
  }

  Widget _buildErrorMessage() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                MyLog.log(_classString, 'build error message button pressed', indent: true);
                await _director.signOut();
                // _errorMessage = null;
                MyLog.log(_classString, 'back to login', indent: true);
                AppRouter.router.goNamed(AppRoutes.kLogin);
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Consumer<AppState>(
        builder: (context, appState, _) => Text(appState.loggedUser?.name ?? 'Nadie conectado'),
      ),
      actions: [
        IconButton(
          // Register
          onPressed: () async {
            context.pushNamed(AppRoutes.kRegister);
          },
          icon: ImageIcon(AssetImage('assets/icons/list.png')),
          tooltip: 'Registro',
        ),
        Consumer<AppState>(
          // Admin
          builder: (context, appState, _) {
            if (appState.isLoggedUserSuper) {
              return IconButton(
                onPressed: () {
                  context.pushNamed(AppRoutes.kAdmin);
                },
                icon: const Icon(Icons.admin_panel_settings),
                tooltip: 'Configuración',
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        IconButton(
          // Exit
          onPressed: () async {
            MyLog.log(_classString, 'Icon SignOut begin', indent: true);
            // if back is pressed, user will be signedOut
            // authStateChanges in initialPage will show loginPage
            await _onBackPressed();
            MyLog.log(_classString, 'Icon SignOut end', indent: true);
          },
          icon: const Icon(Icons.exit_to_app),
          tooltip: 'Salir',
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: <BottomNavigationBarItem>[
        UiHelper.buildNavItem(context, 0, Icon(Icons.home), 'Inicio', _selectedIndex),
        UiHelper.buildNavItem(
            context, 1, ImageIcon(AssetImage('assets/icons/podium.png')), 'Resultados', _selectedIndex),
        UiHelper.buildNavItem(context, 2, ImageIcon(AssetImage('assets/icons/padel.png')), 'Jugadores', _selectedIndex),
        UiHelper.buildNavItem(context, 3, Icon(Icons.settings), 'Perfil', _selectedIndex),
      ],
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  /// Handles the back button press, prompting the user for confirmation before signing out.
  ///
  /// This method displays a confirmation dialog asking the user if they wish to exit the application.
  /// If the user confirms, they are signed out, triggering an authentication state change.
  /// The `InitialPage` will then navigate to the `LoginPage` due to the `authStateChanges` listener.
  ///
  /// Returns:
  ///   A `Future<void>` that completes after the user's response is processed and, if confirmed,
  ///   after the sign-out operation is completed.
  ///
  /// Side Effects:
  ///   - Displays a confirmation dialog to the user.
  ///   - If confirmed, signs out the currently logged-in user through the `Director`'s `signOut()` method.
  ///   - Triggers an authentication state change that leads to the `LoginPage` being displayed.
  ///
  /// Usage:
  ///   This method should be attached to the back button press event in the relevant widget.
  ///
  /// Example:
  ///   PopScope(
  ///     onPopInvoked: (didPop) async {
  ///       await _onBackPressed();
  ///     },
  ///     child: Scaffold(
  ///       // ... your widget content
  ///     ),
  ///   );
  Future<void> _onBackPressed() async {
    MyLog.log(_classString, '_onBackPressed begin');
    const String kYesOption = 'SI';
    const String kNoOption = 'NO';
    String response = await UiHelper.myReturnValueDialog(context, '¿Salir?', kYesOption, kNoOption);
    if (response.isEmpty || response == kNoOption) return;
    MyLog.log(_classString, '_onBackPressed response = $response', indent: true);
    await _director.signOut();
    MyLog.log(_classString, 'back to login', indent: true);
    AppRouter.router.goNamed(AppRoutes.kLogin);
  }

  void _initialize() {
    AppState appState = _director.appState;

    MyLog.log(_classString, 'signIn authenticated user = ${AuthenticationHelper.user?.email}');
    MyLog.log(_classString, 'LoggedUser = ${appState.loggedUser?.email ?? 'vacío'}');

    try {
      // check there is an user logged in the Firebase
      User? fireBaseUser = AuthenticationHelper.user;
      if (fireBaseUser == null || fireBaseUser.email == null) {
        MyLog.log(_classString, '_initialize: User not authenticated = $fireBaseUser',
            level: Level.SEVERE, indent: true);
        throw 'Error: Usuario no registrado en el sistema. \nHable con el administrador.';
      }

      // create listeners for users and parameters
      // any changes to those classes will change appState
      MyLog.log(_classString, '_initialize: createListeners for users and parameters.');
      FbHelpers().createListeners(
        parametersFunction: appState.setAllParametersAndNotify,
        usersFunction: appState.setChangedUsersAndNotify,
      );

      // Delete old logs and matches.
      // MyLog.log(_classString, '_initializeData deleting old data ...', indent: true);
      // _director.deleteOldData(); // TODO: create a cloud function
    } catch (e) {
      MyLog.log(_classString, '_initialize: ERROR loading initial data\nerror=${e.toString()}',
          level: Level.SEVERE, indent: true);

      _errorMessage = e.toString();
    }
  }

  Widget _buildLoadingIndicator([String title = '']) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitFadingCube(
              color: Colors.blue,
              size: 50.0,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
