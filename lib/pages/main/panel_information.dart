import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:no_solo_padel/database/firebase_helpers.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:flutter/foundation.dart';

import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../misc/panel_avatar_selector.dart';

final String _classString = 'InformationPanel'.toUpperCase();

enum _FormFields {
  userType(displayName: 'Tipo de usuario'),
  ranking(displayName: 'Ranking'),
  ;

  final String displayName;

  const _FormFields({required this.displayName});
}

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
    final formKey = GlobalKey<FormBuilderState>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.0,
            children: <Widget>[
              // Title
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              // Avatar Selector
              AvatarSelector(
                user: user,
                onImageSelected: (Uint8List? imageData) {
                  selectedImageData = imageData;
                  MyLog.log(_classString, "Image Selected in modal selected image=${selectedImageData != null}",
                      indent: true);
                },
              ),
              // Type of user and Ranking
              Padding(
                padding: const EdgeInsets.fromLTRB(46.0, 16, 16.0, 16.0),
                child: _buildUserForm(formKey, user),
              ),
              Divider(),
              // accept and cancel buttons
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _acceptChanges(context, user, formKey, selectedImageData),
                      child: Text('Aceptar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
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
  }

  Future<void> _acceptChanges(
      BuildContext context, MyUser user, GlobalKey<FormBuilderState> formKey, Uint8List? selectedImageData) async {
    MyLog.log(_classString, "Accept modal selected image=${selectedImageData != null}",
        indent: true, level: Level.FINE);

    // confirm updating the parameters
    const String yesOption = 'SI';
    const String noOption = 'NO';
    String response =
        await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres actualizar los datos?', yesOption, noOption);
    if (response.isEmpty || response == noOption) return;
    MyLog.log(_classString, 'dialog response = $response', indent: true);

    if (formKey.currentState!.saveAndValidate()) {
      final formData = formKey.currentState!.value;
      user.userType = formData[_FormFields.userType.name] ?? user.userType;
      user.rankingPos = int.tryParse(formData[_FormFields.ranking.name] ?? '') ?? user.rankingPos;
      MyLog.log(_classString, '_acceptChanges: type=${user.userType} ranking=${user.rankingPos}', indent: true);

      try {
        await FbHelpers().updateUser(user, selectedImageData);
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        MyLog.log(_classString, 'Error updating user: $user \n$e', level: Level.SEVERE, indent: true);
        if (context.mounted) UiHelper.showMessage(context, 'Error al actualizar el usuario');
      }
    } else {
      MyLog.log(_classString, 'Error updating user: $user', level: Level.SEVERE, indent: true);
      if (context.mounted) UiHelper.showMessage(context, 'Error al actualizar el usuario');
    }
  }

  Widget _buildUserForm(GlobalKey<FormBuilderState> formKey, MyUser user) {
    return FormBuilder(
      key: formKey,
      child: Column(
        spacing: 8.0,
        children: [
          FormBuilderDropdown<UserType>(
            name: _FormFields.userType.name,
            decoration: InputDecoration(
              labelText: _FormFields.userType.displayName,
            ),
            initialValue: user.userType,
            items: UserType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ))
                .toList(),
          ),
          FormBuilderTextField(
            name: _FormFields.ranking.name,
            initialValue: user.rankingPos.toString(),
            decoration: InputDecoration(labelText: _FormFields.ranking.displayName),
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required( errorText: 'Este campo es obligatorio'),
              FormBuilderValidators.numeric(errorText: 'Debe ser un número'),
              FormBuilderValidators.integer(errorText: 'Debe ser un número entero'),
              FormBuilderValidators.min(0, errorText: 'Debe ser mayor o igual que 0'),
            ]),
          ),
        ],
      ),
    );
  }
}
