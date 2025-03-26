import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../interface/match_notifier.dart';
import '../../../models/debug.dart';
import '../../../models/match_model.dart';
import 'subpanel_random.dart';
import 'subpanel_palindromic.dart';
import 'subpanel_ranking.dart';
import 'subpanel_upside_down.dart';

final String _classString = 'SortingPanel'.toUpperCase();

class SortingPanel extends StatefulWidget {
  const SortingPanel({super.key});

  @override
  SortingPanelState createState() => SortingPanelState();
}

class SortingPanelState extends State<SortingPanel> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Form for match=$match');

    return Column(
      children: <Widget>[
        if (match.comment.isNotEmpty)
          Card(
            elevation: 6,
            margin: const EdgeInsets.all(10),
            child: ListTile(
              tileColor: Theme.of(context).appBarTheme.backgroundColor,
              titleTextStyle: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
              title: Text(match.comment),
            ),
          ),
        ToggleButtons(
          renderBorder: false,
          fillColor: Theme.of(context).colorScheme.inversePrimary,
          isSelected: [
            _selectedIndex == 0,
            _selectedIndex == 1,
            _selectedIndex == 2,
            _selectedIndex == 3,
          ],
          onPressed: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Ranking'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Capicúa'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Inverso'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Aleatorio'),
            ),
          ],
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: const <Widget>[
              RankingPanel(),
              PalindromicPanel(),
              UpsideDownPanel(),
              RandomPanel(),
            ],
          ),
        ),
      ],
    );
  }
}
