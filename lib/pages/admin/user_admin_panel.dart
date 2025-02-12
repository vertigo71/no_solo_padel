import 'package:flutter/material.dart';

import '../../models/debug.dart';
import '../../utilities/ui_helpers.dart';
import 'user_add_panel.dart';
import 'user_delete.dart';
import 'user_modify_panel.dart';

final String _classString = 'UserAdminPanel'.toUpperCase();

class UserAdminPanel extends StatefulWidget {
  const UserAdminPanel({super.key});

  @override
  UserAdminPanelState createState() => UserAdminPanelState();
}

class UserAdminPanelState extends State<UserAdminPanel> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    UserAddPanel(),
    UserModifyPanel(),
    UserDeletePanel(),
  ];

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          UiHelpers.buildNavItem(0, Icon(Icons.person_add_sharp), 'Añadir', _selectedIndex),
          UiHelpers.buildNavItem(1, Icon(Icons.person), 'Modificar', _selectedIndex),
          UiHelpers.buildNavItem(2, Icon(Icons.person_remove_sharp), 'Eliminar', _selectedIndex),
        ],
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
