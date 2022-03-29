import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../utilities/misc.dart';
import '../../utilities/theme.dart';

final String _classString = 'UserDeletePanel'.toUpperCase();

class UserDeletePanel extends StatefulWidget {
  const UserDeletePanel({Key? key}) : super(key: key);

  @override
  _UserDeletePanelState createState() => _UserDeletePanelState();
}

class _UserDeletePanelState extends State<UserDeletePanel> {
  String dropdownValue = '';

  late FirebaseHelper firebaseHelper;

  @override
  void initState() {
    MyLog().log(_classString, 'initState');
    firebaseHelper = context.read<Director>().firebaseHelper;
    super.initState();
  }

  @override
  void dispose() {
    MyLog().log(_classString, 'dispose');
    super.dispose();
  }

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
                      subtitle: Text('${user.email}\nÚltima conexión: '
                          '${user.lastLogin ?? 'Nunca'}; ${user.loginCount} veces'),
                      onTap: () async {
                        if (user.userId == appState.getLoggedUser().userId){
                          showMessage(context, 'No se puede eliminar el usuario actual');
                          return;
                        }

                        const String option1 = 'Eliminar';
                        const String option2 = 'Cancelar';
                        String response = await myReturnValueDialog(
                            context, '¿Eliminar usuario ${user.name}?', option1, option2);
                        MyLog().log(_classString, 'build response = $response');

                        if (response.isEmpty || response == option2) return;

                        // Delete user from matches
                        for (MyMatch match in appState.allMatches) {
                          bool playerExisted = match.removePlayer(user.userId);
                          if (playerExisted) {
                            MyLog().log(_classString, 'deleting $user from ${match.date}',
                                debugType: DebugType.warning);
                            try {
                              await firebaseHelper.updateMatch(
                                  match: match, updateCore: false, updatePlayers: true);
                            } catch (e) {
                              MyLog().log(_classString, 'error delete from matches',
                                  myCustomObject: user, debugType: DebugType.error);
                            }
                          }
                        }

                        // Delete user
                        try {
                          MyLog().log(_classString, 'Elminando usuario  $user',
                              debugType: DebugType.warning);
                          await firebaseHelper.deleteUser(user);
                        } catch (e) {
                          showMessage(context, 'No se ha podido eliminar al usuario ${user.name}');
                          MyLog().log(_classString, 'eliminar usuario',
                              exception: e, debugType: DebugType.error);
                        }
                      },
                    )))),
          ],
        ),
      ),
    );
  }
}
