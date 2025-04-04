import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/authentication.dart';
import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../../routes/routes.dart';
import '../../utilities/date.dart';
import '../../utilities/environment.dart';
import '../../utilities/ui_helpers.dart';
import 'panel_games.dart';
import 'panel_information.dart';
import 'panel_profile.dart';
import 'panel_results.dart';

final String _classString = 'MainPage'.toUpperCase();

/// this page is called once a user has logged in
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // AppBar selected item
  bool _isLoading = true; // Initially loading
  String? _errorMessage;
  late Director _director;

  static const List<Widget> _widgetOptions = <Widget>[
    GamesPanel(),
    ResultsPanel(),
    InformationPanel(),
    ProfilePanel(),
  ];

  @override
  void initState() {
    MyLog.log(_classString, 'initState: _isLoading=$_isLoading', level: Level.FINE);
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

    if (_isLoading) {
      if (_errorMessage != null) {
        MyLog.log(_classString, 'build error message =$_errorMessage', indent: true);
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  MyLog.log(_classString, 'build error message button pressed', indent: true);
                  await _director.signOut();
                  // _errorMessage = null;
                  MyLog.log(_classString, 'back to login', indent: true);
                  AppRouter.router.goNamed(AppRoutes.login);
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        );
      } else {
        return _buildLoadingIndicator(); // Still loading, no error
      }
    } else {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          // if back is pressed, user will be signedOut
          // authStateChanges in initialPage will show loginPage
          await _onBackPressed();
        },
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: _widgetOptions.elementAt(_selectedIndex),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Consumer<AppState>(
        builder: (context, appState, _) => Text(appState.getLoggedUser().name),
      ),
      actions: [
        IconButton(
          // Register
          onPressed: () async {
            context.pushNamed(AppRoutes.register);
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
                  context.pushNamed(AppRoutes.admin);
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
        UiHelper.buildNavItem(0, Icon(Icons.home), 'Inicio', _selectedIndex),
        UiHelper.buildNavItem(1, ImageIcon(AssetImage('assets/icons/podium.png')), 'Resultados', _selectedIndex),
        UiHelper.buildNavItem(2, ImageIcon(AssetImage('assets/icons/padel.png')), 'Jugadores', _selectedIndex),
        UiHelper.buildNavItem(3, Icon(Icons.settings), 'Perfil', _selectedIndex),
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
    const String yesOption = 'SI';
    const String noOption = 'NO';
    String response = await UiHelper.myReturnValueDialog(context, '¿Salir?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return;
    MyLog.log(_classString, '_onBackPressed response = $response', indent: true);
    await _director.signOut();
    MyLog.log(_classString, 'back to login', indent: true);
    AppRouter.router.goNamed(AppRoutes.login);
  }

  Future<void> _initialize() async {
    AppState appState = _director.appState;

    MyLog.log(_classString, 'signIn authenticated user = ${AuthenticationHelper.user?.email}');
    MyLog.log(_classString, 'LoggedUser = ${appState.getLoggedUser().email}');

    try {
      // check there is an user logged in the Firebase
      User? fireBaseUser = AuthenticationHelper.user;
      if (fireBaseUser == null || fireBaseUser.email == null) {
        MyLog.log(_classString, '_initialize: User not authenticated = $fireBaseUser',
            level: Level.SEVERE, indent: true);
        throw 'Error: Usuario no registrado en el sistema. Hable con el administrador.';
      }

      // create listeners for users and parameters
      // any changes to those classes will change appState
      MyLog.log(_classString, '_initialize: createListeners for users and parameters.');
      FbHelpers().createListeners(
        parametersFunction: appState.setAllParametersAndNotify,
        usersFunction: appState.setChangedUsersAndNotify,
      );

      // Wait for users and parameters data to be loaded from Firestore.
      MyLog.log(_classString, '_initialize: waiting for users and parameters to load', indent: true);
      await FbHelpers().dataLoaded();

      // link appState.user to AuthenticationHelper.user
      // listener has already loaded all users into appState
      MyUser? appUser = appState.getUserByEmail(fireBaseUser.email!);
      if (appUser == null) {
        // User not found in appState
        MyLog.log(_classString, '_initialize LoggedUser: ${fireBaseUser.email}  not registered in appState. Abort!',
            level: Level.SEVERE, indent: true);
        throw 'Error: No se ha podido acceder al usuario';
      } else {
        // User found in appState.
        MyLog.log(_classString, '_initializeData LoggedUser found in appState = $appUser', indent: true);
        appState.setLoggedUser(appUser, notify: false);
        appUser.lastLogin = Date.now();
        appUser.loginCount++;
        await FbHelpers().updateUser(appUser);

        // Delete old logs and matches.
        // MyLog.log(_classString, '_initializeData deleting old data ...', indent: true);
        // _director.deleteOldData(); // TODO: create a cloud function

        // Create test data in development mode.
        MyLog.log(_classString, '_initializeData creating test data in development ...', indent: true);
        if (Environment().isDevelopment) await _director.createTestData();

        // Once data is loaded, update the state to indicate loading is complete.
        setState(() {
          _isLoading = false;
        });
        MyLog.log(_classString, '_initialize: all data loaded, _isLoading=$_isLoading', indent: true);
      }
    } catch (e) {
      MyLog.log(_classString, '_initialize: ERROR loading initial data: _isLoading=$_isLoading\nerror=${e.toString()}',
          level: Level.SEVERE, indent: true);

      setState(() {
        _errorMessage = e.toString();
      });
    }
  }
}
