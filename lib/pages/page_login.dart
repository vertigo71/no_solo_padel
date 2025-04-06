import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:no_solo_padel/routes/routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../interface/director.dart';
import '../models/debug.dart';
import '../models/user_model.dart';
import '../secret.dart';
import '../utilities/environment.dart';
import '../database/authentication.dart';
import '../utilities/ui_helpers.dart';

final String _classString = 'Login'.toUpperCase();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  String _version = '';
  static const String userId = 'username';
  static const String pwdId = 'password';

  void getVersion() {
    PackageInfo packageInfo = Environment().packageInfo;
    setState(() => _version = 'v. ${packageInfo.version}');
  }

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE );
    getVersion();

    // this page must only be presented when user is not logged in
    // in some cases, back button comes to this page with a logged user
    // this must be prevented
    context.read<Director>().signOut();
  }

  /// build the widget tree
  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level:Level.FINE);

    return Scaffold(
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
      body: (Environment().isDevelopment || Environment().isStaging)
          ? Banner(
              message: Environment().flavor,
              location: BannerLocation.topEnd,
              child: _buildListView(), // Use the function
            )
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    const String image = 'assets/images/no_solo_padel_2025.png';
    return ListView(
      padding: const EdgeInsets.all(30.0),
      children: [
        Image.asset(
          image,
          height: 300,
        ),
        const SizedBox(height: 40.0),
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
          AppRouter.router.goNamed(AppRoutes.main);
          MyLog.log(_classString, '_formValidate Back to login', indent: true);
        } else {
          if (mounted) UiHelper.showMessage(context, result);
        }
      });

      UiHelper.showMessage(context, 'Cargando la aplicación...');
    }
  }
}
