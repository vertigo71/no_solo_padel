import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/authentication.dart';
import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

// fields of the form
enum _FormFieldsEnum { name, email, actualPwd, newPwd, checkPwd }

class _FormFields {
  _FormFields() {
    assert(text.length == _FormFieldsEnum.values.length);
    assert(obscuredText.length == _FormFieldsEnum.values.length);
  }

  static const List<String> text = [
    'Nombre',
    'Correo',
    'Contraseña Actual',
    'Nueva Contraseña',
    'Repetir contraseña'
  ];

  static const List<bool> obscuredText = [false, false, true, true, true];
  static const List<bool> mayBeEmpty = [false, false, true, true, true];
}

final String _classString = 'SettingsPage'.toUpperCase();

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<SettingsPageState>.
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> listControllers = [];

  late AppState appState;
  late FirebaseHelper firebaseHelper;

  @override
  void initState() {
    appState = context.read<AppState>();
    firebaseHelper = context.read<Director>().firebaseHelper;

    for (var _ in _FormFieldsEnum.values) {
      listControllers.add(TextEditingController());
    }
    listControllers[_FormFieldsEnum.name.index].text = appState.getLoggedUser().name;
    listControllers[_FormFieldsEnum.email.index].text = appState.getLoggedUser().email;
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in listControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyLog().log(_classString, 'Building');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var value in _FormFieldsEnum.values)
                _FormFieldWidget(
                  _FormFields.text[value.index],
                  listControllers[value.index],
                  _FormFields.obscuredText[value.index],
                  _FormFields.mayBeEmpty[value.index],
                  _formValidate,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: const Text('Actualizar'),
                      onPressed: () async => await _formValidate(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool checkName(String newName) {
    // newName is not somebody else's

    MyLog().log(_classString, 'checkName $newName');

    if (newName != appState.getLoggedUser().name) {
      MyUser? user = appState.getUserByName(newName);
      if (user != null) {
        showMessage(context, 'Ya hay un usuario con ese nombre');
        return false;
      }
    }

    User? user = AuthenticationHelper().user;
    if (user == null) {
      showMessage(context, 'ERROR: el usuario no está identificado correctamente');
      return false;
    }

    return true;
  }

  Future<bool> updateName(String newName) async {
    MyLog().log(_classString, 'updateName $newName');

    MyUser user = appState.getLoggedUser();
    user.name = newName;

    try {
      await firebaseHelper.updateUser(user);
    } catch (e) {
      showMessage(context, 'Error al actualizar el nombre del usuario');
      MyLog().log(_classString, 'Error al actualizar el nombre del usuario',
          debugType: DebugType.error);
      return false;
    }

    return true;
  }

  bool checkEmail(String newEmail, String actualPwd) {
    // newEmail is not somebody else's
    MyLog().log(_classString, 'checkEmail $newEmail');

    if (newEmail != appState.getLoggedUser().email) {
      MyUser? user = appState.getUserByEmail(newEmail);
      if (user != null) {
        showMessage(context, 'Ya hay un usuario con ese correo');
        return false;
      }
      if (actualPwd.isEmpty) {
        showMessage(context, 'Para cambiar el correo, introduzca tambien la contraseña actual');
        return false;
      }
    }
    return true;
  }

  Future<bool> updateEmail(String newEmail, String actualPwd) async {
    MyLog().log(_classString, 'updateEmail $newEmail');

    String response =
        await AuthenticationHelper().updateEmail(newEmail: newEmail, actualPwd: actualPwd);

    if (response.isNotEmpty) {
      myAlertDialog(context, response);
      return false;
    }

    MyUser loggedUser = appState.getLoggedUser();
    loggedUser.email = newEmail;

    try {
      await firebaseHelper.updateUser(loggedUser);
    } catch (e) {
      showMessage(context, 'Error al actualizar localmente el correo del usuario');
      MyLog().log(_classString, 'Error al actualizar localmente el correo del usuario',
          debugType: DebugType.error);
      return false;
    }

    return true;
  }

  bool checkAllPwd(String actualPwd, String newPwd, String checkPwd) {
    MyLog().log(_classString, 'checkAllPwd');

    if (newPwd != checkPwd) {
      showMessage(context, 'Las dos contraseñas no coinciden');
      return false;
    }
    if (newPwd.isNotEmpty && actualPwd.isEmpty) {
      showMessage(context, 'Para cambiar la contraseña, introduzca tambien la contraseña actual');
      return false;
    }
    return true;
  }

  Future<bool> updatePwd(String actualPwd, String newPwd) async {
    MyLog().log(_classString, 'updatePwd');

    String response = await AuthenticationHelper().updatePwd(actualPwd: actualPwd, newPwd: newPwd);

    if (response.isNotEmpty) {
      myAlertDialog(context, response);
      return false;
    }
    return true;
  }

  Future<void> _formValidate() async {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      String newName = listControllers[_FormFieldsEnum.name.index].text;
      String newEmail = listControllers[_FormFieldsEnum.email.index].text.toLowerCase();
      String actualPwd = listControllers[_FormFieldsEnum.actualPwd.index].text;
      String newPwd = listControllers[_FormFieldsEnum.newPwd.index].text;
      String checkPwd = listControllers[_FormFieldsEnum.checkPwd.index].text;

      // check name
      bool ok = checkName(newName);
      if (!ok) return;

      // check email
      ok = checkEmail(newEmail, actualPwd);
      if (!ok) return;

      // check passwords
      ok = checkAllPwd(actualPwd, newPwd, checkPwd);
      if (!ok) return;

      // check if is a sure thing
      const String yesOption = 'SI';
      const String noOption = 'NO';
      String response = await myReturnValueDialog(
          context, '¿Seguro que quieres actualizar?', yesOption, noOption);
      if (response.isEmpty || response == noOption) return;
      MyLog().log(_classString, 'build response = $response');

      bool anyUpdatedField = false;

      // update name
      if (newName != appState.getLoggedUser().name) {
        ok = await updateName(newName);
        anyUpdatedField = true;
        if (!ok) return;
      }

      // update email
      if (newEmail != appState.getLoggedUser().email) {
        ok = await updateEmail(newEmail, actualPwd);
        anyUpdatedField = true;
        if (!ok) return;
      }

      // update pwd
      if (newPwd.isNotEmpty) {
        ok = await updatePwd(actualPwd, newPwd);
        anyUpdatedField = true;
        if (!ok) return;
      }

      if (anyUpdatedField) {
        showMessage(context, 'Los datos han sido actualizados');
      } else {
        showMessage(context, 'Ningun dato para actualizar');
      }
    }
  }
}

class _FormFieldWidget extends StatelessWidget {
  const _FormFieldWidget(
      this.fieldName, this.textController, this.protectedField, this.mayBeEmpty, this.validate,
      {Key? key})
      : super(key: key);
  final TextEditingController textController;
  final String fieldName;
  final bool protectedField;
  final bool mayBeEmpty;
  final Future<void> Function() validate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        onFieldSubmitted: (String str) async => await validate(),
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: fieldName,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        controller: textController,
        obscureText: protectedField,
        // The validator receives the text that the user has entered.
        validator: (value) {
          if (mayBeEmpty) return null;
          if (value == null || value.isEmpty) {
            return 'No puede estar vacío';
          }
          return null;
        },
      ),
    );
  }
}
