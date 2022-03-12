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

enum _FormFieldsEnum { name, email, pwd, checkPwd }

class _FormFields {
  static const List<String> text = [
    'Nombre',
    'Correo ',
    'Contraseña',
    'Verificar contraseña',
  ];

  static const List<bool> obscuredText = [false, false, true, true];
}

final String _classString = 'UserAddPanel'.toUpperCase();

class UserAddPanel extends StatefulWidget {
  const UserAddPanel({Key? key}) : super(key: key);

  @override
  _UserAddPanelState createState() => _UserAddPanelState();
}

class _UserAddPanelState extends State<UserAddPanel> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<SettingsPageState>.
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> listControllers =
      List.generate(_FormFieldsEnum.values.length, (index) => TextEditingController());

  // checkBox's
  bool isAdmin = false;
  bool isSuperuser = false;

  late AppState appState;
  late FirebaseHelper firebaseHelper;

  @override
  void initState() {
    MyLog().log(_classString, 'initState');

    appState = context.read<AppState>();
    firebaseHelper = context.read<Director>().firebaseHelper;
    super.initState();
  }

  @override
  void dispose() {
    MyLog().log(_classString, 'dispose');

    for (var controller in listControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (var value in _FormFieldsEnum.values)
                _FormFieldWidget(
                  value,
                  listControllers[value.index],
                  _formValidate,
                ),
              // const SizedBox(height: 10.0),
              Row(
                children: <Widget>[
                  const SizedBox(width: 10), //SizedBox
                  const Text('Administrador'), //Text
                  const SizedBox(width: 10), //SizedBox
                  myGFToggle(
                    context: context,
                    value: isAdmin,
                    onChanged: (bool? value) {
                      setState(() {
                        isAdmin = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text('Superusuario'),
                  const SizedBox(width: 10),
                  myGFToggle(
                    context: context,
                    value: isSuperuser,
                    onChanged: (bool? value) {
                      setState(() {
                        isSuperuser = value!;
                      });
                    },
                  )
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
                      child: const Text('Añadir'),
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

  bool checkName(String name) {
    // newName is not somebody else's

    MyLog().log(_classString, 'checkName $name');

    MyUser? myUser = appState.getUserByName(name);
    if (myUser != null) {
      showMessage(context, 'Ya hay un usuario con ese nombre');
      return false;
    }

    User? user = AuthenticationHelper().user;
    if (user == null) {
      showMessage(context, 'ERROR: el usuario no está identificado correctamente');
      return false;
    }

    return true;
  }

  bool checkEmail(String email) {
    // newEmail is not somebody else's
    MyLog().log(_classString, 'checkEmail $email');

    MyUser? user = appState.getUserByEmail(email);
    if (user != null) {
      showMessage(context, 'Ya hay un usuario con ese correo');
      return false;
    }
    return true;
  }

  bool checkAllPwd(String pwd, String checkPwd) {
    MyLog().log(_classString, 'checkAllPwd');

    if (pwd != checkPwd) {
      showMessage(context, 'Las dos contraseñas no coinciden');
      return false;
    }
    return true;
  }

  Future<bool> createNewUser(name, email, pwd, isAdmin, isSuperuser) async {
    MyLog().log(_classString, 'createNewUser $name $email $isAdmin $isSuperuser');

    MyUser? myUser = appState.createNewUserByEmail(email);
    if (myUser == null) {
      myAlertDialog(context, 'correo del usuario ya existe');
      return false;
    }

    String response =
        await AuthenticationHelper().createUserWithEmailAndPwd(email: email, pwd: pwd);
    if (response.isNotEmpty) {
      myAlertDialog(context, response);
      return false;
    }

    myUser.name = name;
    if (isSuperuser) {
      myUser.userType = UserType.superuser;
    } else if (isAdmin) {
      myUser.userType = UserType.admin;
    } else {
      myUser.userType = UserType.basic;
    }

    try {
      firebaseHelper.uploadUser(myUser);
    } catch (e) {
      showMessage(context, 'Error al crear localmente el usuario');
      MyLog().log(_classString, 'Error al crear localmente el usuario', debugType: DebugType.error);
      return false;
    }
    return true;
  }

  Future<void> _formValidate() async {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      String name = listControllers[_FormFieldsEnum.name.index].text;
      String email = listControllers[_FormFieldsEnum.email.index].text.toLowerCase();
      String pwd = listControllers[_FormFieldsEnum.pwd.index].text;
      String checkPwd = listControllers[_FormFieldsEnum.checkPwd.index].text;

      // check name
      bool ok = checkName(name);
      if (!ok) return;

      // check email
      ok = checkEmail(email);
      if (!ok) return;

      // check passwords
      ok = checkAllPwd(pwd, checkPwd);
      if (!ok) return;

      // check if is a sure thing
      const String yesOption = 'SI';
      const String noOption = 'NO';
      String response = await myReturnValueDialog(
          context, '¿Seguro que quieres añadir el usuario?', yesOption, noOption);
      if (response.isEmpty || response == noOption) return;
      MyLog().log(_classString, 'build response = $response');

      // create new user
      ok = await createNewUser(name, email, pwd, isAdmin, isSuperuser);
      if (!ok) return;

      showMessage(context, 'El usuario ha sido creado');
    }
  }
}

class _FormFieldWidget extends StatelessWidget {
  const _FormFieldWidget(this.fieldsEnum, this.textController, this.validate, {Key? key})
      : super(key: key);

  final _FormFieldsEnum fieldsEnum;
  final TextEditingController textController;
  final Future<void> Function() validate;

  @override
  Widget build(BuildContext context) {
    final String fieldName = _FormFields.text[fieldsEnum.index];
    final bool obscured = _FormFields.obscuredText[fieldsEnum.index];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        onFieldSubmitted: (String str) async => await validate(),
        keyboardType: TextInputType.text,
        obscureText: obscured,
        decoration: InputDecoration(
          labelText: fieldName,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        // inputFormatters: [
        //   FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
        // ],
        controller: textController,
        // The validator receives the text that the user has entered.
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'No puede estar vacío';
          }
          return null;
        },
      ),
    );
  }
}
