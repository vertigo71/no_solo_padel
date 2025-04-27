import 'package:flutter/material.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../../interface/if_app_state.dart';
import '../../../interface/if_director.dart';
import '../../../models/md_debug.dart';
import '../../../utilities/ui_helpers.dart';
import '../../../database/db_firebase_helpers.dart';
import '../../../models/md_user.dart';

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
                tiles: appState.usersSortedByName.map(((user) => UiHelper.buildUserInfoTile(context, user,
                    onPressed: () => _onTap(context, user, context.read<Director>()))))),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, MyUser user, Director director) async {
    final MyUser? loggedUser = director.appState.loggedUser;
    if (loggedUser == null) {
      MyLog.log(_classString, '_onTap loggedUser is null', level: Level.SEVERE);
      throw Exception('No se ha podido obtener el usuario conectado');
    }

    if (user.id == loggedUser.id) {
      UiHelper.showMessage(context, 'No se puede eliminar el usuario conectado');
      return;
    }

    const String kOption1 = 'Eliminar';
    const String kOption2 = 'Cancelar';
    String response =
        await UiHelper.myReturnValueDialog(context, '¿Eliminar usuario ${user.name}?', kOption1, kOption2);
    MyLog.log(_classString, 'build response = $response');

    if (response.isEmpty || response == kOption2) return;

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
