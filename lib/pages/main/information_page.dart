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
                context: context,
                tiles: appState.allSortedUsers.map(((user) => ListTile(
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
