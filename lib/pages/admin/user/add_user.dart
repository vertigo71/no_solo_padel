import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../../database/db_authentication.dart';
import '../../../database/db_firebase_helpers.dart';
import '../../../interface/if_app_state.dart';
import '../../../models/md_debug.dart';
import '../../../models/md_user.dart';
import '../../../utilities/ui_helpers.dart';

final String _classString = 'UserAddPanel'.toUpperCase();

// The uniqueness of a user is checked by its email = username+MyUser.emailSuffix and id = username
enum _FormFieldsEnum {
  name(label: 'Nombre', obscuredText: false),
  username(label: 'Usuario', obscuredText: false),
  pwd(label: 'Contraseña', obscuredText: true),
  checkPwd(label: 'Verificar contraseña', obscuredText: true),
  admin(label: 'Administrador', obscuredText: false),
  superUser(label: 'Super Usuario', obscuredText: false);

  final String label;
  final bool obscuredText;

  const _FormFieldsEnum({required this.label, required this.obscuredText});
}

class UserAddPanel extends StatefulWidget {
  const UserAddPanel({super.key});

  @override
  UserAddPanelState createState() => UserAddPanelState();
}

class UserAddPanelState extends State<UserAddPanel> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  bool _isCreatingUser = false; // Track creation state

  late AppState appState;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);

    appState = context.read<AppState>();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level:Level.FINE);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              // Looping through the enum values to create form fields dynamically
              for (var value in _FormFieldsEnum.values)
                if (value != _FormFieldsEnum.admin && value != _FormFieldsEnum.superUser) _buildFormField(value),

              const SizedBox(height: 30), //SizedBox

              Row(
                children: <Widget>[
                  const SizedBox(width: 10), //SizedBox
                  Text(_FormFieldsEnum.admin.label), //Text
                  const SizedBox(width: 10), //SizedBox
                  _buildCheckBoxField(_FormFieldsEnum.admin),
                  const SizedBox(width: 10),
                  Text(_FormFieldsEnum.superUser.label), //Text
                  const SizedBox(width: 10),
                  _buildCheckBoxField(_FormFieldsEnum.superUser),
                ],
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isCreatingUser ? null : () async => await _formValidate(),
                      child: _isCreatingUser // Show loading indicator
                          ? const CircularProgressIndicator()
                          : const Text('Añadir'), // Disable button while creating
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

  // Function to create each form field based on the enum value
  Widget _buildFormField(_FormFieldsEnum field) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderTextField(
        name: field.name,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        obscureText: field.obscuredText,
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
          if (field == _FormFieldsEnum.username)
            FormBuilderValidators.username(
                allowDash: true,
                allowUnderscore: true,
                allowNumbers: true,
                errorText: 'Utilizar letras, números, guiones y guiones bajos'),
          if (field == _FormFieldsEnum.pwd)
            FormBuilderValidators.minLength(6,
                errorText: 'La longitud tiene que ser superior a 6 caracteres'), // Password length
        ]),
      ),
    );
  }

  Widget _buildCheckBoxField(_FormFieldsEnum field) {
    // Determine the label and initial value based on the field (admin or superUser)
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderField<bool>(
        name: field.name,
        initialValue: false,
        builder: (FormFieldState<bool> field) {
          return UiHelper.myCheckBox(
            context: context,
            value: field.value ?? false,
            onChanged: (newValue) {
              field.didChange(newValue);
            },
          );
        },
      ),
    );
  }

  Future<void> _formValidate() async {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.saveAndValidate()) {
      final formData = _formKey.currentState!.value;

      String name = formData[_FormFieldsEnum.name.name];
      String username = formData[_FormFieldsEnum.username.name];
      String pwd = formData[_FormFieldsEnum.pwd.name];
      String checkPwd = formData[_FormFieldsEnum.checkPwd.name];
      bool isAdmin = formData[_FormFieldsEnum.admin.name] ?? false;
      bool isSuperuser = formData[_FormFieldsEnum.superUser.name] ?? false;

      // check name
      bool ok = _checkName(name);
      if (!ok) return;

      // check username
      ok = _checkUsername(username);
      if (!ok) return;

      // check passwords
      ok = _checkAllPwd(pwd, checkPwd);
      if (!ok) return;

      // confirmation dialog
      const String kYesOption = 'SI';
      const String kNoOption = 'NO';
      String response =
          await UiHelper.myReturnValueDialog(context, '¿Seguro que quieres añadir el usuario?', kYesOption, kNoOption);
      if (response.isEmpty || response == kNoOption) return;
      MyLog.log(_classString, 'dialog response = $response', indent: true);

      setState(() {
        _isCreatingUser = true;
      });

      try {
        bool ok = await _createNewUser(name, username, pwd, isAdmin, isSuperuser);
        if (ok) {
          if (mounted) UiHelper.showMessage(context, 'El usuario ha sido creado');
          _formKey.currentState!.reset();
        }
      } finally {
        setState(() {
          _isCreatingUser = false;
        });
      }

      if (mounted) UiHelper.showMessage(context, 'El usuario ha sido creado');
    }
  }

  bool _checkName(String name) {
    // newName is not somebody else's

    MyLog.log(_classString, 'checkName $name');

    MyUser? myUser = appState.getUserByName(name);
    if (myUser != null) {
      UiHelper.showMessage(context, 'Ya hay un usuario con ese nombre');
      return false;
    }

    return true;
  }

  bool _checkUsername(String username) {
    // newEmail or newId is not somebody else's
    MyLog.log(_classString, 'checkUsername $username');

    if (appState.getUserByEmail(username + MyUser.kEmailSuffix) != null || appState.getUserById(username) != null) {
      UiHelper.showMessage(context, 'Ya hay un jugador con ese nombre de usuario');
      return false;
    }
    return true;
  }

  bool _checkAllPwd(String pwd, String checkPwd) {
    MyLog.log(_classString, 'checkAllPwd');

    if (pwd != checkPwd) {
      UiHelper.showMessage(context, 'Las dos contraseñas no coinciden');
      return false;
    }
    return true;
  }

  Future<bool> _createNewUser(name, username, pwd, isAdmin, isSuperuser) async {
    MyLog.log(_classString, 'createNewUser $name $username $isAdmin $isSuperuser');

    // add user to Firebase Authentication
    String response =
        await AuthenticationHelper.createUserWithEmailAndPwd(email: username + MyUser.kEmailSuffix, pwd: pwd);
    if (response.isNotEmpty) {
      // error creating new user
      MyLog.log(_classString, 'createNewUser ERROR creating user', level: Level.SEVERE, indent: true);
      if (mounted) UiHelper.myAlertDialog(context, response);
      return false;
    }

    // create a user
    MyUser myUser = MyUser(
      id: username,
      name: name,
      email: username + MyUser.kEmailSuffix,
      userType: isSuperuser
          ? UserType.superuser
          : isAdmin
              ? isAdmin
              : UserType.basic,
      loginCount: 0,
    );
    MyLog.log(_classString, 'createNewUser user created=$myUser', indent: true);

    try {
      FbHelpers().updateUser(myUser);
    } catch (e) {
      if (mounted) UiHelper.showMessage(context, 'Error al crear el usuario en la base de datos');
      MyLog.log(_classString, 'Error creating user in Firestore', level: Level.SEVERE, indent: true);
      return false;
    }
    return true;
  }
}
