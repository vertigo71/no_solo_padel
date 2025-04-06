import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../models/debug.dart';
import '../../utilities/ui_helpers.dart';
import 'panel_user_add.dart';
import 'panel_user_delete.dart';

final String _classString = 'UserAdminPanel'.toUpperCase();

class UserAdminPanel extends StatefulWidget {
  const UserAdminPanel({super.key});

  @override
  UserAdminPanelState createState() => UserAdminPanelState();
}

class UserAdminPanelState extends State<UserAdminPanel> {
  int _selectedIndex = 0;
  static const List<Widget> _kWidgetOptions = <Widget>[
    UserAddPanel(),
    UserDeletePanel(),
  ];

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);
    return Scaffold(
      body: Center(
        child: _kWidgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          UiHelper.buildNavItem(0, Icon(Icons.person_add_sharp), 'Añadir', _selectedIndex),
          UiHelper.buildNavItem(1, Icon(Icons.person_remove_sharp), 'Eliminar', _selectedIndex),
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
