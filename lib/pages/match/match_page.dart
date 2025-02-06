import 'package:flutter/material.dart';
import 'package:no_solo_padel_dev/interface/matchNotifier.dart';
import 'package:no_solo_padel_dev/models/match_model.dart';
import 'package:provider/provider.dart';

import '../../models/debug.dart';
import 'players_panel.dart';
import 'config_panel.dart';
import 'sorting_panel.dart';
import '../../interface/app_state.dart';

final String _classString = 'MatchPage'.toUpperCase();

class MatchPage extends StatefulWidget {
  final MyMatch match;

  const MatchPage({super.key, required this.match});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  late final MatchNotifier matchNotifier;

  @override
  void initState() {
    super.initState();
    matchNotifier = MatchNotifier(widget.match);
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    final bool isLoggedUserAdmin = context.read<AppState>().isLoggedUserAdmin;
    return ChangeNotifierProvider<MatchNotifier>.value(
      value: matchNotifier,
      child: DefaultTabController(
        length: isLoggedUserAdmin ? 3 : 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(matchNotifier.match.date.toString()),
            bottom: TabBar(
              tabs: [
                if (isLoggedUserAdmin) const _TabBarText('Configurar'),
                const _TabBarText('Apuntarse'),
                const _TabBarText('Partidos'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              if (isLoggedUserAdmin) ConfigurationPanel(matchNotifier.match),
              PlayersPanel(matchNotifier.match),
              SortingPanel(matchNotifier.match),
            ],
          ),
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
