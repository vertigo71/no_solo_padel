import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/border/gf_border.dart';
import 'package:getwidget/getwidget.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/debug.dart';
import '../models/user_model.dart';
import '../routes/routes.dart';
import '../utilities/misc.dart';
import '../database/authentication.dart';

final String _classString = 'Login'.toUpperCase();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController pwdController = TextEditingController();

  String version = '';

  Future<void> getVersion() async {
    await Environment().initialize();
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

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            version,
            textAlign: TextAlign.end,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(30.0),
        children: [
          Image.asset(
            'assets/images/no_solo_padel.jpg',
            height: 300,
          ),
          const SizedBox(height: 20.0),
          Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                          onFieldSubmitted: (String str) => _formValidate(),
                          keyboardType: TextInputType.text,
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Correo'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'No puede estar vacío';
                            }
                            return null;
                          }),
                    ),
                    const SizedBox(width: 20.0),
                    const Text(MyUser.emailSuffix),
                  ],
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 3,
                      child: Card(
                        color: Theme.of(context).colorScheme.background,
                        elevation: 6,
                        margin: const EdgeInsets.all(10),
                        child: SizedBox(
                          height: 200,
                          child: ListWheelScrollView(
                              itemExtent: 30,
                              magnification: 1.5,
                              useMagnifier: true,
                              diameterRatio: 2,
                              squeeze: 0.8,
                              perspective: 0.01,
                              physics: const FixedExtentScrollPhysics(),
                              scrollBehavior: const MaterialScrollBehavior().copyWith(
                                dragDevices: {
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.stylus,
                                  PointerDeviceKind.unknown
                                },
                              ),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  print(index);
                                });
                              },
                              children: [
                                for (int i = 0; i < 30; i++) Text('Cafe $i'),
                              ]),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                        flex: 2,
                        child: Column(
                          children: [
                            const Text('Apuntar a:'),
                            const SizedBox(height: 10),
                            const Text(''),
                            ElevatedButton(
                              child: const Text('Confirmar'),
                              onPressed: () {},
                            )
                          ],
                        ))
                  ],
                )
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
      String email = emailController.text;
      if (!email.contains('@')) email = email + MyUser.emailSuffix;
      AuthenticationHelper().signIn(email: email, password: pwdController.text).then((result) async {
        if (result == null) {
          await Navigator.of(context).pushNamed(RouteManager.loadingPage);

          MyLog().log(_classString, 'back to login');
          setState(() {
            pwdController.text = '';
          });
        } else {
          showMessage(context, result);
        }
      });
    }
  }
}
