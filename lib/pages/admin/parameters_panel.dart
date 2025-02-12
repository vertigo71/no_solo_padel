import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../utilities/misc.dart';
import '../../utilities/transformation.dart';

class _FormFields {
  static List<String> text = [
    'Partidos: ver número de días', // matchDaysToView
    'Partidos: histórico de días a conservar', // matchDaysKeeping
    'Registro: ver número de días atrás', // registerDaysAgoToView
    'Registro: histórico de días a conservar', // registerDaysKeeping
    'Enviar telegram si partido es antes de (días)', // fromDaysAgoToTelegram
    'Texto por defecto del comentario', // defaultCommentText
    'Debug: nivel mínimo (0 - ${MyLog.levels.length - 1})', // minDebugLevel
    'Días que se pueden jugar (${MyParameters.daysOfWeek})', // weekDaysMatch
    '', // not a textFormField // showLog
  ];

  static List<String> listAllowedChars = [
    // matchDaysToView
    '[0-9]',
    // matchDaysKeeping
    '[0-9]',
    // registerDaysAgoToView
    '[0-9]',
    // registerDaysKeeping
    '[0-9]',
    // fromDaysAgoToTelegram
    '[0-9]',
    // defaultCommentText free text
    '',
    // minDebugLevel
    '[0-${MyLog.levels.length - 1}]',
    // weekDaysMatch
    '[${MyParameters.daysOfWeek.toLowerCase()}${MyParameters.daysOfWeek.toUpperCase()}]',
    // not a textFormField // showLog
    ''
  ];

  static List<bool> isTextField = [
    true, // matchDaysToView
    true, // matchDaysKeeping
    true, // registerDaysAgoToView
    true, // registerDaysKeeping
    true, // fromDaysAgoToTelegram
    true, // defaultCommentText
    true, // minDebugLevel
    true, // weekDaysMatch
    false, // showLog
  ];

  List<String> initialValues(AppState appState) {
    List<String> values = [];
    assert(ParametersEnum.values.length == text.length);
    for (ParametersEnum parameter in ParametersEnum.values) {
      values.add(appState.getParameterValue(parameter));
    }
    return values;
  }
}

final String _classString = 'ParametersPanel'.toUpperCase();

class ParametersPanel extends StatefulWidget {
  const ParametersPanel({super.key});

  @override
  ParametersPanelState createState() => ParametersPanelState();
}

class ParametersPanelState extends State<ParametersPanel> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<ParametersPageState>.
  final _formKey = GlobalKey<FormState>();
  List<TextEditingController?> listControllers = List.generate(_FormFields.isTextField.length,
      (index) => _FormFields.isTextField[index] ? TextEditingController() : null);

  late AppState appState;
  late FsHelpers fsHelpers;
  bool showLog = false;

  @override
  void initState() {
    MyLog.log(_classString, 'initState');

    appState = context.read<AppState>();
    fsHelpers = context.read<Director>().fsHelpers;

    showLog = appState.showLog;
    List<String> initialValues = _FormFields().initialValues(appState);
    for (int i = 0; i < listControllers.length; i++) {
      listControllers[i]?.text = initialValues[i];
    }

    super.initState();
  }

  @override
  void dispose() {
    MyLog.log(_classString, 'dispose');

    for (var controller in listControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (var value in ParametersEnum.values)
                if (listControllers[value.index] != null)
                  _FormFieldWidget(
                    _FormFields.text[value.index],
                    _FormFields.listAllowedChars[value.index],
                    listControllers[value.index]!,
                    _formValidate,
                  ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  myCheckBox(
                    context: context,
                    value: showLog,
                    onChanged: (bool? value) {
                      setState(() {
                        showLog = value!;
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text('¿Mostrar log a todos los usuarios?'),
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
      MyParameters myParameters = MyParameters();
      for (var value in ParametersEnum.values) {
        if (value == ParametersEnum.showLog) {
          myParameters.setValue(value, boolToStr(showLog));
        } else if (value == ParametersEnum.weekDaysMatch) {
          // delete repeated chars in weekDaysMatch
          myParameters.setValue(value,
              listControllers[value.index]!.text.split('').toSet().fold('', (a, b) => '$a$b'));
        } else if (listControllers[value.index] != null) {
          myParameters.setValue(value, listControllers[value.index]!.text);
        }
      }

      try {
        await fsHelpers.updateParameters(myParameters);
        if (mounted) {
          showMessage(
              context,
              'Los parámetros han sido actualizados. \n'
              'Volver a entrar en la app para que se tengan en cuenta');
        }
      } catch (e) {
        if (mounted) showMessage(context, 'Error actualizando parámetros ');
      }
    }
  }
}

class _FormFieldWidget extends StatelessWidget {
  const _FormFieldWidget(this.fieldName, this.allowedChars, this.textController, this.validate);

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
          if (allowedChars.isNotEmpty)
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
