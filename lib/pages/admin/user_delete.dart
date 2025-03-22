import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../utilities/misc.dart';
import '../../utilities/ui_helpers.dart';

final String _classString = 'UserDeletePanel'.toUpperCase();

class UserDeletePanel extends StatefulWidget {
  const UserDeletePanel({super.key});

  @override
  UserDeletePanelState createState() => UserDeletePanelState();
}

class UserDeletePanelState extends State<UserDeletePanel> {
  String dropdownValue = '';

  late FbHelpers fbHelpers;

  @override
  void initState() {
    super.initState();

    MyLog.log(_classString, 'initState');
    fbHelpers = context.read<Director>().fbHelpers;
  }

  @override
  void dispose() {
    MyLog.log(_classString, 'dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) => ListView(
          children: [
            ...ListTile.divideTiles(
                context: context,
                tiles: appState.users.map(((user) => ListTile(
                      leading: CircleAvatar(
                          backgroundColor: getUserColor(user), child: Text(user.userType.name[0].toUpperCase())),
                      title: Text(user.name),
                      subtitle: Text('${user.email}\nÚltima conexión: '
                          '${user.lastLogin ?? 'Nunca'}; '
                          '${singularOrPlural(user.loginCount, 'vez', 'veces')}'),
                      onTap: () async {
                        if (user.id == appState.getLoggedUser().id) {
                          showMessage(context, 'No se puede eliminar el usuario actual');
                          return;
                        }

                        const String option1 = 'Eliminar';
                        const String option2 = 'Cancelar';
                        String response =
                            await myReturnValueDialog(context, '¿Eliminar usuario ${user.name}?', option1, option2);
                        MyLog.log(_classString, 'build response = $response');

                        if (response.isEmpty || response == option2) return;

                        // Delete user
                        try {
                          MyLog.log(_classString, 'Elminando usuario  $user');
                          await fbHelpers.deleteUser(user);
                        } catch (e) {
                          if (context.mounted) showMessage(context, 'No se ha podido eliminar al usuario ${user.name}');
                          MyLog.log(_classString, 'eliminar usuario', exception: e, level: Level.SEVERE);
                        }
                      },
                    )))),
          ],
        ),
      ),
    );
  }
}
