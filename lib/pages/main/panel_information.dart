import 'package:flutter/material.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';

final String _classString = 'InformationPanel'.toUpperCase();

class InformationPanel extends StatelessWidget {
  const InformationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Scaffold(
      body: ListView(
        children: [
          ...ListTile.divideTiles(
              context: context,
              tiles: context.read<AppState>().users.map(((user) {
                return UiHelper.userInfoTile(user, () => _modifyUser(context, user));
              }))),
        ],
      ),
    );
  }

  Future _modifyUser(BuildContext context, MyUser user) {
    MyLog.log(_classString, '_modifyUser: $user', indent: true);
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Overlapping Panel: user=$user'),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }
}
