import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/authentication.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../routes/routes.dart';
import '../../utilities/misc.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope( // TODO: deprecated
      onWillPop: _onBackPressed,
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
                      Navigator.pushNamed(context, RouteManager.adminPage);
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
                MyLog().log(_classString, 'Icon SignOut begin');

                bool response = await _onBackPressed();
                if (!response) return;

                MyLog().log(_classString, 'Icon SignOut before pop');
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Salir',
            ),
          ],
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/list.png')),
              label: 'Registro',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/padel.png')),
              label: 'Jugadores',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    MyLog().log(_classString, '_onBackPressed begin');
    const String yesOption = 'SI';
    const String noOption = 'NO';
    String response = await myReturnValueDialog(context, '¿Salir?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return false;
    MyLog().log(_classString, '_onBackPressed response = $response');
    if (mounted) {
      await AuthenticationHelper().signOut(signedOutFunction: context.read<Director>().firebaseHelper.disposeListeners);
    }
    MyLog().log(_classString, '_onBackPressed before exiting');
    return true;
  }
}
