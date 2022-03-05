import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../utilities/misc.dart';

final String _classString = 'InformationPage'.toUpperCase();

class InformationPage extends StatelessWidget {
  const InformationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) => ListView(
          children: [
            ...ListTile.divideTiles(
                color: Colors.deepPurple,
                tiles: appState.allSortedUsers.map(((user) => ListTile(
                      tileColor: Theme.of(context).colorScheme.background,
                      leading: CircleAvatar(
                          child: Text(user.userType.name[0].toUpperCase()),
                          backgroundColor: getUserColor(user)),
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    )))),
          ],
        ),
      ),
    );
  }
}
