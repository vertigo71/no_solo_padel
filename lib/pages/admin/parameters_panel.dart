import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:collection/collection.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../utilities/misc.dart';
import '../../utilities/transformation.dart';

/// Class name identifier for logging
final String _classString = 'ParametersPanel'.toUpperCase();

/// Helper class to define form fields and their properties
class _FormFields {
  /// Labels for the form fields
  static List<String> text = [
    'Partidos: ver número de días', // matchDaysToView
    'Partidos: histórico de días a conservar', // matchDaysKeeping
    'Registro: ver número de días atrás', // registerDaysAgoToView
    'Registro: histórico de días a conservar', // registerDaysKeeping
    'Enviar telegram si partido es antes de (días)', // fromDaysAgoToTelegram
    'Texto por defecto del comentario', // defaultCommentText
    'Debug (${_generateDebugLevelsText()})', // minDebugLevel
    'Días que se pueden jugar (${MyParameters.daysOfWeek})', // weekDaysMatch
    '', // Not a text field (showLog)
  ];

  static String _generateDebugLevelsText() {
    return Level.LEVELS
        .mapIndexed(
            (index, level) => level.name.length <= 5 ? '$index-${level.name}' : '$index-${level.name.substring(0, 5)}')
        .join(',');
  }

  /// Allowed characters for input fields (regex)
  static List<String> listAllowedChars = [
    '[0-9]', // matchDaysToView
    '[0-9]', // matchDaysKeeping
    '[0-9]', // registerDaysAgoToView
    '[0-9]', // registerDaysKeeping
    '[0-9]', // fromDaysAgoToTelegram
    '', // defaultCommentText (free text)
    '[0-${Level.LEVELS.length - 1}]', // minDebugLevel
    '[${MyParameters.daysOfWeek.toLowerCase()}${MyParameters.daysOfWeek.toUpperCase()}]', // weekDaysMatch
    '' // Not a text field (showLog)
  ];
}

/// The main widget for the parameters panel
class ParametersPanel extends StatefulWidget {
  const ParametersPanel({super.key});

  @override
  ParametersPanelState createState() => ParametersPanelState();
}

/// State for ParametersPanel
class ParametersPanelState extends State<ParametersPanel> {
  final _formKey = GlobalKey<FormBuilderState>(); // Form key

  late AppState _appState;
  late FbHelpers _fbHelpers;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState');

    // Retrieve instances from Provider
    _appState = context.read<AppState>();
    _fbHelpers = context.read<Director>().fbHelpers;
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building');

    // compare fields in case other user has changed any fields
    bool areFieldsDifferent(dynamic formValue, dynamic realValue) => formValue != null && formValue != realValue;
    // Use ParametersEnum to iterate through fields and compare
    bool fieldsChanged = ParametersEnum.values
        .map((parameter) => areFieldsDifferent(
            _formKey.currentState?.fields[parameter.name]?.value, _appState.getParameterValue(parameter)))
        .any((changed) => changed);

    if (fieldsChanged) {
      MyLog.log(_classString, 'Fields have changed', indent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage(context, '¡Atención! Los datos han sido actualizados por otro usuario');
      });
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              // Generate text fields dynamically (excluding showLog)
              for (var value in ParametersEnum.values)
                if (value != ParametersEnum.showLog) _buildTextField(value),

              // Show Log Checkbox
              _buildShowLogCheckbox(),

              const Divider(), // Divider for UI separation

              // Update Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
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

  /// Builds a FormBuilderTextField for a given parameter
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

        // Apply input formatters if allowed characters are specified
        inputFormatters: _FormFields.listAllowedChars[parameter.index].isNotEmpty
            ? [UpperCaseTextFormatter(RegExp(_FormFields.listAllowedChars[parameter.index]), allow: true)]
            : [],

        // Validation logic
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'No puede estar vacío'),
        ]),
      ),
    );
  }

  /// Builds the Show Log checkbox with FormBuilderField
  Widget _buildShowLogCheckbox() {
    return Row(
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
    );
  }

  /// Validates and submits the form
  Future<void> _formValidate() async {
    MyLog.log(_classString, '_formValidate');

    // Check if the form is valid before proceeding
    if (_formKey.currentState!.saveAndValidate()) {
      MyParameters myParameters = MyParameters();
      final formValues = _formKey.currentState!.value;

      for (var value in ParametersEnum.values) {
        if (value == ParametersEnum.showLog) {
          // Convert bool to string before saving
          myParameters.setValue(value, boolToStr(formValues[value.name] ?? false));
        } else if (value == ParametersEnum.weekDaysMatch) {
          // Remove duplicate characters from weekDaysMatch
          myParameters.setValue(value, formValues[value.name].split('').toSet().join());
        } else {
          myParameters.setValue(value, formValues[value.name]);
        }
      }

      try {
        await _fbHelpers.updateParameters(myParameters);
        if (mounted) {
          showMessage(context, 'Los parámetros han sido actualizados.');
        }
      } catch (e) {
        if (mounted) {
          showMessage(context, 'Error actualizando parámetros.');
        }
      }
    }
  }
}
