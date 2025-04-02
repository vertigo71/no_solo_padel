import 'package:flutter/material.dart';
import 'package:no_solo_padel/database/firebase_helpers.dart';
import 'package:no_solo_padel/models/user_model.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../utilities/ui_helpers.dart';

final String _classString = 'UserDeletePanel'.toUpperCase();

class UserDeletePanel extends StatelessWidget {
  const UserDeletePanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) => ListView(
          children: [
            ...ListTile.divideTiles(
                context: context,
                tiles: appState.users.map(
                    ((user) => UiHelper.userInfoTile(user, () => _onTap(context, user, context.read<Director>()))))),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, MyUser user, Director director) async {
    if (user.id == director.appState.getLoggedUser().id) {
      UiHelper.showMessage(context, 'No se puede eliminar el usuario actual');
      return;
    }

    const String option1 = 'Eliminar';
    const String option2 = 'Cancelar';
    String response = await UiHelper.myReturnValueDialog(context, '¿Eliminar usuario ${user.name}?', option1, option2);
    MyLog.log(_classString, 'build response = $response');

    if (response.isEmpty || response == option2) return;

    // Delete user
    try {
      MyLog.log(_classString, 'Elminando usuario  $user');
      await FbHelpers().deleteUser(user);
    } catch (e) {
      if (context.mounted) UiHelper.showMessage(context, 'No se ha podido eliminar al usuario ${user.name}');
      MyLog.log(_classString, 'eliminar usuario', exception: e, level: Level.SEVERE);
    }
  }
}
