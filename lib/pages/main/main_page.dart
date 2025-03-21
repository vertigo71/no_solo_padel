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
import '../../utilities/misc.dart';
import '../../utilities/ui_helpers.dart';
import 'home_page.dart';
import 'information_page.dart';
import 'register_page.dart';
import 'settings_page.dart';

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
    HomePage(),
    RegisterPage(),
    InformationPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    MyLog.log(_classString, 'initState');
    super.initState();
    _director = context.read<Director>();
    // initialize data
    _initializeData();
  }

  /// dispose the listeners when the widget is removed
  @override
  void dispose() {
    MyLog.log(_classString, 'dispose');
    _director.fbHelpers.disposeListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

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
        Consumer<AppState>(
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
        UiHelpers.buildNavItem(0, Icon(Icons.home), 'Inicio', _selectedIndex),
        UiHelpers.buildNavItem(1, ImageIcon(AssetImage('assets/images/list.png')), 'Registro', _selectedIndex),
        UiHelpers.buildNavItem(2, ImageIcon(AssetImage('assets/images/padel.png')), 'Información', _selectedIndex),
        UiHelpers.buildNavItem(3, Icon(Icons.settings), 'Ajustes', _selectedIndex),
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
    String response = await myReturnValueDialog(context, '¿Salir?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return;
    MyLog.log(_classString, '_onBackPressed response = $response', indent: true);
    await _director.signOut();
    MyLog.log(_classString, 'back to login', indent: true);
    AppRouter.router.goNamed(AppRoutes.login);
  }

  Future<void> _initializeData() async {
    MyLog.log(_classString, '_initializeData begin');
    AppState appState = _director.appState;
    FbHelpers fbHelpers = _director.fbHelpers;

    MyLog.log(_classString, '_initializeData signIn LoggedUser = ${AuthenticationHelper.user?.email}', indent: true);
    MyLog.log(_classString, '_initializeData appState LoggedUser = ${appState.getLoggedUser().email}', indent: true);

    try {
      // check there is an user logged in the Firebase
      User? fireBaseUser = AuthenticationHelper.user;
      if (fireBaseUser == null || fireBaseUser.email == null) {
        MyLog.log(_classString, '_initializeData User not authenticated = $fireBaseUser',
            level: Level.SEVERE, indent: true);
        throw Exception('Error: Usuario no registrado en el sistema. Hable con el administrador.');
      }

      // create listeners for users and parameters
      // any changes to those classes will change appState
      MyLog.log(_classString, '_initializeData createListeners for users and parameters.');
      fbHelpers.createListeners(
        parametersFunction: appState.setAllParametersAndNotify,
        usersFunction: appState.setChangedUsersAndNotify,
      );

      // Wait for users and parameters data to be loaded from Firestore.
      try {
        MyLog.log(_classString, '_initializeData waiting for users and parameters to load', indent: true);
        await fbHelpers.dataLoaded();
      } catch (error) {
        MyLog.log(_classString, 'ERROR _initializeData fbHelpers.dataLoaded. Error: $error',
            level: Level.SEVERE, indent: true);
        rethrow;
      }

      // link appState.user to AuthenticationHelper.user
      // listener has already loaded all users into appState
      MyUser? appUser = appState.getUserByEmail(fireBaseUser.email!);
      if (appUser == null) {
        // User not found in appState
        MyLog.log(_classString, '_initializeData user: ${fireBaseUser.email}  not registered in appState. Abort!',
            level: Level.SEVERE, indent: true);
        throw Exception('Error: Usuario no registrado en la aplicación. Hable con el administrador.');
      } else {
        // User found in appState.
        MyLog.log(_classString, '_initializeData user found in appState = $appUser', indent: true);
        appState.setLoggedUser(appUser, notify: false);
        appUser.lastLogin = Date.now();
        appUser.loginCount++;
        await fbHelpers.updateUser(appUser);

        // Delete old logs and matches.
        MyLog.log(_classString, '_initializeData deleting old data ...', indent: true);
        _director.deleteOldData(); // TODO: create a cloud function

        // Create test data in development mode.
        MyLog.log(_classString, '_initializeData creating test data in development ...', indent: true);
        if (Environment().isDevelopment) await _director.createTestData();

        // Once data is loaded, update the state to indicate loading is complete.
        setState(() {
          _isLoading = false;
        });
        MyLog.log(_classString, '_initializeData initial data loaded, _isLoading=$_isLoading', indent: true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }
}
