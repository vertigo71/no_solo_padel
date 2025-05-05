import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../models/md_debug.dart';
import '../../utilities/ui_helpers.dart';
import 'check.dart';
import 'param_ranking.dart';
import 'parameters.dart';
import 'user/user.dart';

final String _classString = 'AdminPage'.toUpperCase();

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    try {
      return DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Configuración'),
            bottom: TabBar(
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.all(8.0),
              padding: EdgeInsets.zero,
              tabs: [
                _tabBarText('Usuarios'),
                _tabBarText('Parámetros'),
                _tabBarText('Ranking'),
                _tabBarText('Checking'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              UserAdminPanel(),
              ParametersPanel(),
              RankingParamPanel(),
              CheckPanel(),
            ],
          ),
        ),
      );
    } catch (e) {
      return UiHelper.buildErrorMessage(
          errorMessage: e.toString(),
          buttonText: 'Reintentar',
          onPressed: () async {
            UiHelper.reloadPage();
          });
    }
  }

  Widget _tabBarText(String text) => FittedBox(child: Tab(child: Text(text, style: const TextStyle(fontSize: 15))));
}
