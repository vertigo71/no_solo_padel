import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../database/authentication.dart';
import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

// fields of the form
enum _FormFieldsEnum { name, emergencyInfo, user, actualPwd, newPwd, checkPwd }

class _FormFields {
  _FormFields() {
    assert(text.length == _FormFieldsEnum.values.length);
    assert(obscuredText.length == _FormFieldsEnum.values.length);
  }

  static const List<String> text = [
    'Nombre (por este te conocerán los demás)',
    'Información de emergencia',
    'Usuario (para conectarte a la aplicación)',
    'Contraseña Actual',
    'Nueva Contraseña',
    'Repetir contraseña'
  ];

  static const List<bool> obscuredText = [false, false, false, true, true, true];
  static const List<bool> mayBeEmpty = [false, true, false, true, true, true];
}

final String _classString = 'SettingsPage'.toUpperCase();

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

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
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  late AppState appState;
  late FsHelpers fsHelpers;

  @override
  void initState() {
    super.initState();

    appState = context.read<AppState>();
    fsHelpers = context.read<Director>().fsHelpers;
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyLog.log(_classString, 'Building');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormField(_FormFieldsEnum.name),
              _buildFormField(_FormFieldsEnum.emergencyInfo),
              _buildFormField(_FormFieldsEnum.user),
              _buildFormField(_FormFieldsEnum.actualPwd),
              _buildFormField(_FormFieldsEnum.newPwd),
              _buildFormField(_FormFieldsEnum.checkPwd),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _formValidate,
                      child: const Text('Actualizar'),
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

  Widget _buildFormField(_FormFieldsEnum formFieldEnum) {
    final fieldName = _FormFields.text[formFieldEnum.index];
    final isPassword = _FormFields.obscuredText[formFieldEnum.index];
    final isOptional = _FormFields.mayBeEmpty[formFieldEnum.index];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderTextField(
        name: formFieldEnum.toString(),
        initialValue: _getInitialValue(formFieldEnum),
        decoration: InputDecoration(
          labelText: fieldName,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        obscureText: isPassword,
        validator: (value) {
          if (isOptional) return null;
          if (value == null || value.isEmpty) return 'No puede estar vacío';
          return null;
        },
      ),
    );
  }

  String _getInitialValue(_FormFieldsEnum formFieldEnum) {
    switch (formFieldEnum) {
      case _FormFieldsEnum.name:
        return appState.getLoggedUser().name;
      case _FormFieldsEnum.emergencyInfo:
        return appState.getLoggedUser().emergencyInfo;
      case _FormFieldsEnum.user:
        return appState.getLoggedUser().email.split('@')[0];
      default:
        return '';
    }
  }

  Future<void> _formValidate() async {
    MyLog.log(_classString, '_formValidate');
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formValues = _formKey.currentState?.value;

      final newName = formValues?[_FormFieldsEnum.name.toString()] ?? '';
      final newEmergencyInfo = formValues?[_FormFieldsEnum.emergencyInfo.toString()] ?? '';
      final newEmail = formValues?[_FormFieldsEnum.user.toString()]?.toLowerCase() + MyUser.emailSuffix ?? '';
      final actualPwd = formValues?[_FormFieldsEnum.actualPwd.toString()] ?? '';
      final newPwd = formValues?[_FormFieldsEnum.newPwd.toString()] ?? '';
      final checkPwd = formValues?[_FormFieldsEnum.checkPwd.toString()] ?? '';

      MyLog.log(_classString, '_formValidate $newName', indent: true);
      MyLog.log(_classString, '_formValidate $newEmergencyInfo', indent: true);
      MyLog.log(_classString, '_formValidate $newEmail', indent: true);
      MyLog.log(_classString, '_formValidate $actualPwd', indent: true);
      MyLog.log(_classString, '_formValidate $newPwd', indent: true);
      MyLog.log(_classString, '_formValidate $checkPwd', indent: true);


      // Validation and Update Logic
      bool isValid = checkName(newName);
      if (!isValid) return;

      isValid = checkEmail(newEmail, actualPwd);
      if (!isValid) return;

      isValid = checkAllPwd(actualPwd, newPwd, checkPwd);
      if (!isValid) return;

      const String yesOption = 'SI';
      const String noOption = 'NO';
      String response = await myReturnValueDialog(context, '¿Seguro que quieres actualizar?', yesOption, noOption);
      if (response.isEmpty || response == noOption) return;

      bool anyUpdatedField = false;

      // Handle name update
      if (newName != appState.getLoggedUser().name) {
        isValid = await updateName(newName);
        anyUpdatedField = true;
        if (!isValid) return;
      }

      // Handle emergency info update
      if (newEmergencyInfo != appState.getLoggedUser().emergencyInfo) {
        isValid = await updateEmergencyInfo(newEmergencyInfo);
        anyUpdatedField = true;
        if (!isValid) return;
      }

      // Handle email update
      if (newEmail != appState.getLoggedUser().email) {
        isValid = await updateEmail(newEmail, actualPwd);
        anyUpdatedField = true;
        if (!isValid) return;
      }

// Handle password update
      if (newPwd.isNotEmpty) {
        isValid = await updatePwd(actualPwd, newPwd);
        anyUpdatedField = true;
        if (!isValid) return;
      }

      if (anyUpdatedField) {
        if (mounted) showMessage(context, 'Los datos han sido actualizados');
      } else {
        if (mounted) showMessage(context, 'Ningún dato para actualizar');
      }
    }
  }

  bool checkName(String newName) {
    // newName is not somebody else's

    MyLog.log(_classString, 'checkName $newName');

    if (newName != appState.getLoggedUser().name) {
      MyUser? user = appState.getUserByName(newName);
      if (user != null) {
        showMessage(context, 'Ya hay un usuario con ese nombre');
        return false;
      }
    }

    return true;
  }

  Future<bool> updateName(String newName) async {
    MyLog.log(_classString, 'updateName $newName');

    MyUser user = appState.getLoggedUser();
    user.name = newName;

    try {
      await fsHelpers.updateUser(user);
    } catch (e) {
      if (mounted) showMessage(context, 'Error al actualizar el nombre del usuario');
      MyLog.log(_classString, 'updateName Error al actualizar el nombre del usuario',
          level: Level.SEVERE, indent: true);
      return false;
    }

    return true;
  }

  bool checkEmail(String newEmail, String actualPwd) {
    // newEmail is not somebody else's
    MyLog.log(_classString, 'checkEmail $newEmail');

    if (newEmail != appState.getLoggedUser().email) {
      MyUser? user = appState.getUserByEmail(newEmail);
      if (user != null) {
        showMessage(context, 'Ya hay un usuario con ese correo');
        return false;
      }
      if (actualPwd.isEmpty) {
        showMessage(context, 'Para cambiar el usuario, introduzca tambien la contraseña actual');
        return false;
      }
    }
    return true;
  }

  Future<bool> updateEmail(String newEmail, String actualPwd) async {
    MyLog.log(_classString, 'updateEmail $newEmail');

    String response = await AuthenticationHelper.updateEmail(newEmail: newEmail, actualPwd: actualPwd);

    if (response.isNotEmpty) {
      if (mounted) myAlertDialog(context, response);
      return false;
    }

    MyUser loggedUser = appState.getLoggedUser();
    loggedUser.email = newEmail;

    try {
      await fsHelpers.updateUser(loggedUser);
    } catch (e) {
      if (mounted) showMessage(context, 'Error al actualizar el correo del usuario en la base de datos');
      MyLog.log(_classString, 'updateEmail Error al actualizar el correo del usuario en la base de datos',
          level: Level.SEVERE, indent: true);
      return false;
    }

    return true;
  }

  bool checkAllPwd(String actualPwd, String newPwd, String checkPwd) {
    MyLog.log(_classString, 'checkAllPwd');

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
    MyLog.log(_classString, 'updatePwd');

    String response = await AuthenticationHelper.updatePwd(actualPwd: actualPwd, newPwd: newPwd);

    if (response.isNotEmpty) {
      if (mounted) myAlertDialog(context, response);
      return false;
    }
    return true;
  }

  Future<bool> updateEmergencyInfo(String newEmergencyInfo) async {
    MyLog.log(_classString, 'updateEmergencyInfo $newEmergencyInfo');

    MyUser user = appState.getLoggedUser();
    user.emergencyInfo = newEmergencyInfo;

    try {
      await fsHelpers.updateUser(user);
    } catch (e) {
      if (mounted) showMessage(context, 'Error al actualizar la información de emergencia del usuario');
      MyLog.log(_classString, 'updateEmergencyInfo Error al actualizar  la información de emergencia del usuario',
          level: Level.SEVERE, indent: true);
      return false;
    }

    return true;
  }
}
