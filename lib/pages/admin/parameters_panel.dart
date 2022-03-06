import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../utilities/misc.dart';

class _FormFields {
  static int numTextFormFields = ParametersEnum.values.length;

  static List<String> text = [
    'Partidos: ver número de días',
    'Partidos: histórico de días a conservar',
    'Registro: ver número de días atrás',
    'Registro: histórico de días a conservar',
    'Debug: nivel mínimo (0 - ${DebugType.values.length - 1})',
    'Días que se pueden jugar (${MyParameters.daysOfWeek})',
    'Mostrar log a todos los usuarios (0/1)',
  ];

  static List<String> listAllowedChars = [
    '[0-9]',
    '[0-9]',
    '[0-9]',
    '[0-9]',
    '[0-${DebugType.values.length - 1}]',
    '[${MyParameters.daysOfWeek.toLowerCase()}${MyParameters.daysOfWeek.toUpperCase()}]',
    '[0-1]',
  ];
}

final String _classString = 'ParametersPanel'.toUpperCase();

class ParametersPanel extends StatefulWidget {
  const ParametersPanel({Key? key}) : super(key: key);

  @override
  _ParametersPanelState createState() => _ParametersPanelState();
}

class _ParametersPanelState extends State<ParametersPanel> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<ParametersPageState>.
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController> listControllers =
      List.generate(_FormFields.numTextFormFields, (index) => TextEditingController());

  late AppState appState;
  late FirebaseHelper firebaseHelper;

  @override
  void initState() {
    MyLog().log(_classString, 'initState');

    appState = context.read<AppState>();
    firebaseHelper = context.read<Director>().firebaseHelper;

    for (int i = 0; i < _FormFields.numTextFormFields; i++) {
      listControllers[i].text = appState.getParameterValue(ParametersEnum.values[i]);
    }
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
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var value in ParametersEnum.values)
                _FormFieldWidget(
                  _FormFields.text[value.index],
                  _FormFields.listAllowedChars[value.index],
                  listControllers[value.index],
                  _formValidate,
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      child: const Text('Actualizar'),
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

  Future<void> _formValidate() async {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      List<String> parameters = [];
      for (var value in ParametersEnum.values) {
        parameters.add(listControllers[value.index].text);
      }
      // check no repeated chars in weekDaysMatch
      parameters[ParametersEnum.weekDaysMatch.index] =
          parameters[ParametersEnum.weekDaysMatch.index]
              .split('')
              .toSet()
              .fold('', (a, b) => '$a$b');

      try {
        await firebaseHelper.uploadParameters(parameters: parameters);
        showMessage(
            context,
            'Los parámetros han sido actualizados. \n'
            'Volver a entrar en la app para que se tengan en cuenta');
      } catch (e) {
        showMessage(context, 'Error actualizando parámetros ');
      }
    }
  }
}

class _FormFieldWidget extends StatelessWidget {
  const _FormFieldWidget(this.fieldName, this.allowedChars, this.textController, this.validate,
      {Key? key})
      : super(key: key);
  final TextEditingController textController;
  final String fieldName;
  final String allowedChars;
  final Future<void> Function() validate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        onFieldSubmitted: (String str) async => await validate(),
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: fieldName,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
          ),
        ),
        inputFormatters: [
          UpperCaseTextFormatter(RegExp(r'' + allowedChars), allow: true),
        ],
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
