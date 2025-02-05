import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  void initState() {
    super.initState();
    getVersion();
    // for development
    emailController.text = getInitialUserName();
    pwdController.text = getInitialPwd();
  }

  @override
  void dispose() {
    emailController.dispose();
    pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog().log(_classString, 'Building');

    const String image = 'assets/images/no_solo_padel.jpg';

    return Scaffold(
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
    MyLog().log(_classString, '_formValidate');
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      String email = emailController.text + MyUser.emailSuffix;
      AuthenticationHelper().signIn(email: email, password: pwdController.text).then((result) async {
        if (result == null) {
          if (mounted) context.pushNamed(AppRoutes.loading);

          MyLog().log(_classString, 'back to login');
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
