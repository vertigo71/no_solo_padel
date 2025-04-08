import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../../models/md_user.dart';
import '../../../utilities/ut_avatar_selector.dart';
import '../../../database/db_firebase_helpers.dart';
import '../../../utilities/ui_helpers.dart';
import '../../../models/md_debug.dart';

final String _classString = 'ModifyUserModal'.toUpperCase();

enum _FormFields {
  userType(displayName: 'Tipo de usuario'),
  ranking(displayName: 'Ranking'),
  ;

  final String displayName;

  const _FormFields({required this.displayName});
}

class ModifyUserModal extends StatefulWidget {
  final MyUser user;

  const ModifyUserModal({
    super.key,
    required this.user,
  });

  @override
  State<ModifyUserModal> createState() => _ModifyUserModalState();
}

class _ModifyUserModalState extends State<ModifyUserModal> {
  Uint8List? selectedImageData;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late MyUser user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            child: _buildUserForm(_formKey, user),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptChanges(context), // Call the internal _acceptChanges
                  child: const Text('Aceptar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptChanges(BuildContext context) async {
    MyLog.log(_classString, "Accept modal selected image=${selectedImageData != null}",
        indent: true, level: Level.FINE);

    const String kYesOption = 'SI';
    const String kNoOption = 'NO';
    String response =
        await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres actualizar los datos?', kYesOption, kNoOption);
    if (response.isEmpty || response == kNoOption) return;
    MyLog.log(_classString, 'dialog response = $response', indent: true);

    if (_formKey.currentState!.saveAndValidate()) {
      final formData = _formKey.currentState!.value;
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
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
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
