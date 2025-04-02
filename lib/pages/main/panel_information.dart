import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:no_solo_padel/database/firebase_helpers.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:flutter/foundation.dart';

import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../misc/panel_avatar_selector.dart';

final String _classString = 'InformationPanel'.toUpperCase();

class InformationPanel extends StatelessWidget {
  const InformationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Consumer<AppState>(builder: (context, appState, child) {
      return Scaffold(
        body: ListView(
          children: [
            ...ListTile.divideTiles(
                context: context,
                tiles: appState.users.map(((user) {
                  return UiHelper.userInfoTile(
                      user, appState.isLoggedUserAdminOrSuper ? () => _modifyUser(context, user) : null);
                }))),
          ],
        ),
      );
    });
  }

  Future _modifyUser(BuildContext context, MyUser user) {
    MyLog.log(_classString, '_modifyUser: $user', indent: true);

    Uint8List? selectedImageData;
    UserType selectedUserType = user.userType;
    FbHelpers fbHelpers = context.read<Director>().fbHelpers;

    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8.0,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  AvatarSelector(
                    user: user,
                    onImageSelected: (Uint8List? imageData) {
                      selectedImageData = imageData;
                      MyLog.log(_classString, "Image Selected in modal selected image=${selectedImageData != null}",
                          indent: true);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(46.0, 16, 16.0, 16.0),
                    child: _buildUserTypeDropdown(
                        selectedUserType, setState, (UserType newValue) => selectedUserType = newValue),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _acceptChanges(context, user, selectedUserType, selectedImageData, fbHelpers),
                          child: Text('Aceptar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            MyLog.log(
                                _classString,
                                "Closing modal selected image=${selectedImageData != null},"
                                " type=${selectedUserType.displayName}",
                                indent: true);
                            Navigator.pop(context);
                          },
                          child: Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptChanges(BuildContext context, MyUser user, UserType selectedUserType,
      Uint8List? selectedImageData, FbHelpers fbHelpers) async {
    MyLog.log(
        _classString, "Accept modal selected image=${selectedImageData != null}, type=${selectedUserType.displayName}",
        indent: true);

    // confirm updating the parameters
    const String yesOption = 'SI';
    const String noOption = 'NO';
    String response =
        await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres actualizar los datos?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return;
    MyLog.log(_classString, 'build response = $response', indent: true);

    // update user
    user.userType = selectedUserType;
    try {
      await fbHelpers.updateUser(user, selectedImageData);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      MyLog.log(_classString, 'Error updating user: $user \n$e', level: Level.SEVERE, indent: true);
      if (context.mounted) UiHelper.showMessage(context, 'Error al actualizar el usuario');
    }
  }

  Widget _buildUserTypeDropdown(UserType selectedUserType, StateSetter setState, Function(UserType) onUserTypeChanged) {
    return FormBuilder(
      child: FormBuilderDropdown<UserType>(
        name: 'userType',
        decoration: const InputDecoration(
          labelText: 'Tipo de Usuario',
        ),
        initialValue: selectedUserType,
        items: UserType.values
            .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                ))
            .toList(),
        onChanged: (UserType? newValue) {
          if (newValue != null) {
            setState(() {
              selectedUserType = newValue;
            });
            onUserTypeChanged(newValue);
          }
        },
      ),
    );
  }
}
