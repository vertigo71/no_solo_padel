import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../database/firestore_helpers.dart';
import '../interface/app_state.dart';
import '../interface/director.dart';
import '../models/debug.dart';
import '../models/user_model.dart';
import '../routes/routes.dart';
import '../secret.dart';
import '../utilities/environment.dart';
import '../utilities/misc.dart';
import '../database/authentication.dart';

final String _classString = 'Login'.toUpperCase();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = true; // Initially loading
  String _version = '';
  static const String userId = 'username';
  static const String pwdId = 'password';

  void getVersion() {
    PackageInfo packageInfo = Environment().packageInfo;
    if (Environment().isDevelopment) {
      setState(() => _version = '${packageInfo.appName} ${packageInfo.version}+${packageInfo.buildNumber}');
    } else {
      setState(() => _version = '${packageInfo.version}+${packageInfo.buildNumber}');
    }
  }

  @override
  void initState() {
    super.initState();

    MyLog.log(_classString, 'initState to be called ONLY ONCE');
    _initializeData();
  }

  Future<void> _initializeData() async {
    getVersion();

    Director director = context.read<Director>();
    AppState appState = director.appState;
    FsHelpers fsHelpers = director.fsHelpers;

    // create listeners for users and parameters
    // any changes to those classes will change appState
    MyLog.log(_classString, '_initializeData createListeners for users and parameters. To be called only ONCE');
    await fsHelpers.createListeners(
      parametersFunction: appState.setAllParametersAndNotify,
      usersFunction: appState.setChangedUsersAndNotify,
    );
    // Wait for the initial data to be loaded from Firestore.
    await fsHelpers.dataLoaded;

    // Once data is loaded, update the state to indicate loading is complete.
    setState(() {
      _isLoading = false;
    });
    MyLog.log(_classString, '_initializeData initial data loaded, _isLoading=false', indent: true);
  }

  /// dispose the listeners when the widget is removed
  @override
  void dispose() {
    Director director = context.read<Director>();
    FsHelpers fsHelpers = director.fsHelpers;

    fsHelpers.disposeListeners();
    super.dispose();
  }

  /// build the widget tree
  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    const String image = 'assets/images/no_solo_padel.jpg';

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            bottomNavigationBar: BottomAppBar(
              color: Colors.transparent,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _version,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(30.0),
              children: [
                Image.asset(
                  image,
                  height: 300,
                ),
                const SizedBox(height: 20.0),
                FormBuilder(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // username
                      FormBuilderTextField(
                        name: userId,
                        autofillHints: const [AutofillHints.username],
                        initialValue: getInitialUserName(),
                        onSubmitted: (String? str) => _formValidate(),
                        inputFormatters: [
                          LowerCaseTextFormatter(RegExp(r'[^ @]'), allow: true),
                        ],
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: 'No puede estar vacío'),
                        ]),
                      ),

                      const SizedBox(height: 20.0),

                      // password
                      FormBuilderTextField(
                        name: pwdId,
                        autofillHints: const [AutofillHints.password],
                        initialValue: getInitialPwd(),
                        onSubmitted: (String? str) => _formValidate(),
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: 'No puede estar vacío'),
                        ]),
                      ),

                      const SizedBox(height: 30.0),

                      // Validar
                      ElevatedButton(
                        onPressed: () => _formValidate(),
                        child: const Text('Entrar'),
                      ),
                      const SizedBox(height: 50.0),
                    ],
                  ),
                )
              ],
            ),
          );
  }

  void _formValidate() {
    MyLog.log(_classString, '_formValidate');
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.saveAndValidate()) {
      final formData = _formKey.currentState!.value;
      String email = formData[userId] + MyUser.emailSuffix;

      AuthenticationHelper.signIn(email: email, password: formData[pwdId]).then((result) async {
        if (result == null) {
          // user has signed in
          if (mounted) context.pushNamed(AppRoutes.loading);

          MyLog.log(_classString, '_formValidate Back to login', indent: true);

          _formKey.currentState?.fields[pwdId]?.didChange('');
        } else {
          if (mounted) showMessage(context, result);
        }
      });
    }
  }
}
