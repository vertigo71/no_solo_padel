import 'package:flutter/material.dart';

import '../models/debug.dart';
import '../models/user_model.dart';
import '../routes/routes.dart';
import '../utilities/misc.dart';
import '../utilities/variables.dart';
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

  @override
  void initState() {
    super.initState();
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
      bottomNavigationBar: const BottomAppBar(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(version, textAlign: TextAlign.end,),
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
                  onPressed: () {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      String email = emailController.text;
                      if (!email.contains('@')) email = email + MyUser.emailSuffix;
                      AuthenticationHelper()
                          .signIn(email: email, password: pwdController.text)
                          .then((result) async {
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
                  },
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
}
