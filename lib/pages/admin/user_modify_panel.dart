import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';
import '../../utilities/ui_helpers.dart';

final String _classString = 'ModifyUserPage'.toUpperCase();

class UserModifyPanel extends StatelessWidget {
  const UserModifyPanel({super.key});

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
                        const String option1 = 'Básico';
                        const String option2 = 'Admin';
                        const String option3 = 'Super';
                        const String option4 = 'Cancelar';
                        String response = await myReturnValueDialog(context, '¿Tipo de usuario?', option1, option2,
                            option3: option3, option4: option4);
                        MyLog.log(_classString, 'build response = $response');

                        if (response.isEmpty || response == option4) return;

                        if (response == option1) {
                          user.userType = UserType.basic;
                        } else if (response == option2) {
                          user.userType = UserType.admin;
                        } else if (response == option3) {
                          user.userType = UserType.superuser;
                        }
                        try {
                          if (context.mounted) context.read<Director>().fsHelpers.updateUser(user);
                          MyLog.log(_classString, 'usuario modificado con $response');
                        } catch (e) {
                          if (context.mounted) {
                            showMessage(context, 'No se ha podido modificar al usuario ${user.name}');
                          }
                          MyLog.log(_classString, 'modificar usuario', exception: e, level: Level.SEVERE);
                        }
                      },
                    )))),
          ],
        ),
      ),
    );
  }
}
