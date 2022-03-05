import 'package:flutter/material.dart';

import '../../models/debug.dart';
import 'user_add_panel.dart';
import 'user_modify_panel.dart';

final String _classString = 'UserAdminPanel'.toUpperCase();

class UserAdminPanel extends StatefulWidget {
  const UserAdminPanel({Key? key}) : super(key: key);

  @override
  _UserAdminPanelState createState() => _UserAdminPanelState();
}

class _UserAdminPanelState extends State<UserAdminPanel> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    UserAddPanel(),
    UserModifyPanel(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Theme.of(context).colorScheme.background,
        selectedItemColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_sharp),
            label: 'Añadir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Modificar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
