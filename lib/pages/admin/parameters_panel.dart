import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../utilities/misc.dart';
import '../../utilities/transformation.dart';

final String _classString = 'ParametersPanel'.toUpperCase();

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
}

class ParametersPanel extends StatefulWidget {
  const ParametersPanel({super.key});

  @override
  ParametersPanelState createState() => ParametersPanelState();
}

class ParametersPanelState extends State<ParametersPanel> {
  final _formKey = GlobalKey<FormBuilderState>();

  late AppState _appState;
  late FsHelpers _fsHelpers;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState');

    _appState = context.read<AppState>();
    _fsHelpers = context.read<Director>().fsHelpers;
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
              // parameter widgets except showLog
              for (var value in ParametersEnum.values)
                if (value != ParametersEnum.showLog) _buildTextField(value),

              // show log
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FormBuilderField<bool>(
                    name: ParametersEnum.showLog.name,
                    initialValue: _appState.showLog,
                    builder: (FormFieldState<bool> field) {
                      return myCheckBox(
                        context: context,
                        value: field.value ?? false,
                        onChanged: (bool? value) {
                          field.didChange(value); // Updates FormBuilder's state
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text('¿Mostrar log a todos los usuarios?'),
                ],
              ),

              // divider
              const Divider(),

              // Accept button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  // mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildTextField(ParametersEnum parameter) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderTextField(
        name: parameter.name,
        initialValue: _appState.getParameterValue(parameter),
        decoration: InputDecoration(
          labelText: _FormFields.text[parameter.index],
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,
        inputFormatters: _FormFields.listAllowedChars[parameter.index].isNotEmpty
            ? [UpperCaseTextFormatter(RegExp(r'' + _FormFields.listAllowedChars[parameter.index]), allow: true)]
            : [],
        validator: (value) => (value == null || value.isEmpty) ? 'No puede estar vacío' : null,
      ),
    );
  }

  Future<void> _formValidate() async {
    MyLog.log(_classString, '_formValidate');

    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.saveAndValidate()) {
      MyParameters myParameters = MyParameters();
      final formValues = _formKey.currentState!.value;

      for (var value in ParametersEnum.values) {
        if (value == ParametersEnum.showLog) {
          myParameters.setValue(value, boolToStr(formValues[value.name] ?? false));
        } else if (value == ParametersEnum.weekDaysMatch) {
          myParameters.setValue(value, formValues[value.name].split('').toSet().join());
        } else {
          myParameters.setValue(value, formValues[value.name]);
        }
      }

      try {
        await _fsHelpers.updateParameters(myParameters);
        if (mounted) {
          showMessage(context, 'Los parámetros han sido actualizados. \n');
        }
      } catch (e) {
        if (mounted) showMessage(context, 'Error actualizando parámetros ');
      }
    }
  }
}
