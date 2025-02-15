import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../database/authentication.dart';
import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../routes/routes.dart';
import '../../utilities/misc.dart';
import '../../utilities/ui_helpers.dart';
import 'home_page.dart';
import 'information_page.dart';
import 'register_page.dart';
import 'settings_page.dart';

final String _classString = 'MainPage'.toUpperCase();

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    RegisterPage(),
    InformationPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    return PopScope(
      canPop: false, // Important: Initially set to false
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // If already popped by system, do nothing
        bool response = await _onBackPressed(); // Your custom logic

        if (response && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            showMessage(context, "Error al pulsar salir de la pantalla.");
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Consumer<AppState>(builder: (context, appState, _) => Text(appState.getLoggedUser().name)),
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

                bool response = await _onBackPressed();
                if (!response) return;

                MyLog.log(_classString, 'Icon SignOut before pop', indent: true);
                if (context.mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    showMessage(context, "Error al pulsar salir de la pantalla.");
                  }
                }
              },
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Salir',
            ),
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            UiHelpers.buildNavItem(0, Icon(Icons.home), 'Inicio', _selectedIndex),
            UiHelpers.buildNavItem(1, ImageIcon(AssetImage('assets/images/list.png')), 'Registro', _selectedIndex),
            UiHelpers.buildNavItem(2, ImageIcon(AssetImage('assets/images/padel.png')), 'Jugadores', _selectedIndex),
            UiHelpers.buildNavItem(3, Icon(Icons.settings), 'Ajustes', _selectedIndex),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    MyLog.log(_classString, '_onBackPressed begin');
    const String yesOption = 'SI';
    const String noOption = 'NO';
    String response = await myReturnValueDialog(context, '¿Salir?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return false;
    MyLog.log(_classString, '_onBackPressed response = $response', indent: true );
    if (mounted) {
      await AuthenticationHelper.signOut();
      if (mounted) context.read<AppState>().resetLoggedUser();
    }
    MyLog.log(_classString, '_onBackPressed before exiting', indent: true);
    return true;
  }
}
