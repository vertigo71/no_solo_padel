import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:no_solo_padel_dev/interface/director.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../database/firestore_helpers.dart';
import '../interface/app_state.dart';
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
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  bool _isLoading = true; // Initially loading

  String version = '';

  void getVersion() {
    PackageInfo packageInfo = Environment().packageInfo;
    if (Environment().isDevelopment) {
      setState(() => version = '${packageInfo.appName} ${packageInfo.version}+${packageInfo.buildNumber}');
    } else {
      setState(() => version = '${packageInfo.version}+${packageInfo.buildNumber}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MyLog.log(_classString, 'didChangeDependencies initializing variables ONLY ONCE');
    _initializeData();
  }

  Future<void> _initializeData() async {
    getVersion();
    // for development
    emailController.text = getInitialUserName();
    pwdController.text = getInitialPwd();

    Director director = context.read<Director>();
    AppState appState = director.appState;
    FsHelpers fsHelpers = director.fsHelpers;

    // create listeners for users and parameters
    // any changes to those classes will change appState
    MyLog.log(_classString, 'createListeners. To be called only ONCE');
    await fsHelpers.createListeners(
      parametersFunction: appState.setAllParametersAndNotify,
      usersFunction: appState.setChangedUsersAndNotify,
    );
    await fsHelpers.dataLoaded; //  future completed when initial data is loaded

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    Director director = context.read<Director>();
    FsHelpers fsHelpers = director.fsHelpers;

    emailController.dispose();
    pwdController.dispose();
    fsHelpers.disposeListeners();

    super.dispose();
  }

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
                  version,
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
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                          onFieldSubmitted: (String str) => _formValidate(),
                          inputFormatters: [
                            LowerCaseTextFormatter(RegExp(r'[^ @]'), allow: true),
                          ],
                          keyboardType: TextInputType.text,
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Usuario'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'No puede estar vacío';
                            }
                            return null;
                          }),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: TextFormField(
                            onFieldSubmitted: (String str) => _formValidate(),
                            keyboardType: TextInputType.text,
                            controller: pwdController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'Contraseña'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'No puede estar vacío';
                              }
                              return null;
                            }),
                      ),
                      const SizedBox(height: 10.0),
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
    if (_formKey.currentState!.validate()) {
      String email = emailController.text + MyUser.emailSuffix;
      AuthenticationHelper.signIn(email: email, password: pwdController.text).then((result) async {
        if (result == null) {
          // user has signed in
          if (mounted) context.pushNamed(AppRoutes.loading);

          MyLog.log(_classString, 'Back to login');
          setState(() {
            pwdController.text = '';
          });
        } else {
          if (mounted) showMessage(context, result);
        }
      });
    }
  }
}
