import 'package:flutter/material.dart';

import '../../models/debug.dart';
import 'parameters_panel.dart';
import 'user_admin_panel.dart';

final String _classString = 'AdminPage'.toUpperCase();

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
          bottom: TabBar(
            tabs: [
              _tabBarText('Usuarios'),
              _tabBarText('Parámetros'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserAdminPanel(),
            ParametersPanel(),
          ],
        ),
      ),
    );
  }

  Widget _tabBarText(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
