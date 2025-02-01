import 'package:flutter/material.dart';

import '../../models/debug.dart';
import 'parameters_panel.dart';
import 'user_admin_panel.dart';


final String _classString = 'AdminPage'.toUpperCase();

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
          bottom: const TabBar(
            tabs: [
              _TabBarText('Usuarios'),
              _TabBarText('Parámetros'),
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
}

class _TabBarText extends StatelessWidget {
  const _TabBarText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
        ),
      ),
    );
  }
}
