import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../models/md_debug.dart';
import 'param_ranking.dart';
import 'parameters.dart';
import 'user/user.dart';

final String _classString = 'AdminPage'.toUpperCase();

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level:Level.FINE);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
          bottom: TabBar(
            tabs: [
              _tabBarText('Usuarios'),
              _tabBarText('Parámetros'),
              _tabBarText('Ranking'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserAdminPanel(),
            ParametersPanel(),
            RankingParamPanel(),
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
