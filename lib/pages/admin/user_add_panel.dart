import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../database/authentication.dart';
import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

final String _classString = 'UserAddPanel'.toUpperCase();

enum _FormFieldsEnum { name, email, pwd, checkPwd, admin, superUser }

class _FormFields {
  static const List<String> text = [
    'Nombre',
    'Correo (@nsp.com)',
    'Contraseña',
    'Verificar contraseña',
    'Administrador',
    'Super Usuario',
  ];

  static const List<bool> obscuredText = [false, false, true, true, true, true];
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
  late FsHelpers fsHelpers;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState');

    appState = context.read<AppState>();
    fsHelpers = context.read<Director>().fsHelpers;
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

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
                  Text(_FormFields.text[_FormFieldsEnum.admin.index]), //Text
                  const SizedBox(width: 10), //SizedBox
                  _buildCheckBoxField(_FormFieldsEnum.admin),

                  const SizedBox(width: 10),
                  Text(_FormFields.text[_FormFieldsEnum.superUser.index]), //Text
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
          labelText: _FormFields.text[field.index],
          border: const OutlineInputBorder(),
        ),
        obscureText: _FormFields.obscuredText[field.index],
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'Este campo es obligatorio'),
          if (field == _FormFieldsEnum.email)
            FormBuilderValidators.email(errorText: 'La dirección de correo tiene que ser válida'), // Email validation
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
          return myCheckBox(
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
      String email = formData[_FormFieldsEnum.email.name];
      String pwd = formData[_FormFieldsEnum.pwd.name];
      String checkPwd = formData[_FormFieldsEnum.checkPwd.name];
      bool isAdmin = formData[_FormFieldsEnum.admin.name] ?? false;
      bool isSuperuser = formData[_FormFieldsEnum.superUser.name] ?? false;

      // check name
      bool ok = checkName(name);
      if (!ok) return;

      // check email
      ok = checkEmail(email);
      if (!ok) return;

      // check passwords
      ok = checkAllPwd(pwd, checkPwd);
      if (!ok) return;

      // confirmation dialog
      const String yesOption = 'SI';
      const String noOption = 'NO';
      String response =
          await myReturnValueDialog(context, '¿Seguro que quieres añadir el usuario?', yesOption, noOption);
      if (response.isEmpty || response == noOption) return;
      MyLog.log(_classString, 'build response = $response', indent: true);

      setState(() {
        _isCreatingUser = true;
      });

      try {
        bool ok = await createNewUser(name, email, pwd, isAdmin, isSuperuser);
        if (ok) {
          if (mounted) showMessage(context, 'El usuario ha sido creado');
          _formKey.currentState!.reset();
        }
      } finally {
        setState(() {
          _isCreatingUser = false;
        });
      }

      if (mounted) showMessage(context, 'El usuario ha sido creado');
    }
  }

  bool checkName(String name) {
    // newName is not somebody else's

    MyLog.log(_classString, 'checkName $name');

    MyUser? myUser = appState.getUserByName(name);
    if (myUser != null) {
      showMessage(context, 'Ya hay un usuario con ese nombre');
      return false;
    }

    return true;
  }

  bool checkEmail(String email) {
    // newEmail is not somebody else's
    MyLog.log(_classString, 'checkEmail $email');

    MyUser? user = appState.getUserByEmail(email);
    if (user != null) {
      showMessage(context, 'Ya hay un usuario con ese correo');
      return false;
    }
    return true;
  }

  bool checkAllPwd(String pwd, String checkPwd) {
    MyLog.log(_classString, 'checkAllPwd');

    if (pwd != checkPwd) {
      showMessage(context, 'Las dos contraseñas no coinciden');
      return false;
    }
    return true;
  }

  Future<bool> createNewUser(name, email, pwd, isAdmin, isSuperuser) async {
    MyLog.log(_classString, 'createNewUser $name $email $isAdmin $isSuperuser');

    MyUser? existingUser = appState.getUserByEmail(email);
    if (existingUser != null) {
      MyLog.log(_classString, 'createNewUser user already exists', level: Level.WARNING, indent: true);
      myAlertDialog(context, 'El correo del usuario ya existe');
      return false;
    }

    String response = await AuthenticationHelper.createUserWithEmailAndPwd(email: email, pwd: pwd);
    if (response.isNotEmpty && mounted) {
      // error creating new user
      MyLog.log(_classString, 'createNewUser ERROR creating user', level: Level.SEVERE, indent: true);
      myAlertDialog(context, response);
      return false;
    }

    // create a user
    MyUser myUser = MyUser(
      id: email.split('@')[0],
      name: name,
      email: email,
      userType: isSuperuser
          ? isSuperuser
          : isAdmin
              ? isAdmin
              : UserType.basic,
      loginCount: 0,
    );
    MyLog.log(_classString, 'createNewUser user created=$myUser', indent: true);

    try {
      fsHelpers.updateUser(myUser);
    } catch (e) {
      if (mounted) showMessage(context, 'Error al crear localmente el usuario');
      MyLog.log(_classString, 'Error creating user in Firestore', level: Level.SEVERE, indent: true);
      return false;
    }
    return true;
  }
}
