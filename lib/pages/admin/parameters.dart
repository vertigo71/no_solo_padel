import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:collection/collection.dart';

import '../../database/db_firebase_helpers.dart';
import '../../interface/if_app_state.dart';
import '../../models/md_debug.dart';
import '../../models/md_parameter.dart';
import '../../utilities/ut_misc.dart';
import '../../utilities/ui_helpers.dart';

/// Class name identifier for logging
final String _classString = 'ParametersPanel'.toUpperCase();

/// Helper class to define form fields and their properties
class _FormFields {
  static Map<ParametersEnum, String> label = {
    ParametersEnum.bVersion: 'Versión',
    ParametersEnum.bDefaultRanking: 'Valor al resetear el ranking',
    ParametersEnum.bMatchDaysToView: 'Partidos: ver número de días',
    ParametersEnum.bMatchDaysKeeping: 'Partidos: histórico de días a conservar',
    ParametersEnum.bRegisterDaysAgoToView: 'Registro: ver número de días atrás',
    ParametersEnum.bRegisterDaysKeeping: 'Registro: histórico de días a conservar',
    ParametersEnum.bDefaultCommentText: 'Texto por defecto del comentario',
    ParametersEnum.bMinDebugLevel: 'Debug (${_generateDebugLevelsText()})',
    ParametersEnum.bWeekDaysMatch: 'Días que se pueden jugar (${MyParameters.kDaysOfWeek})',
    ParametersEnum.bShowLog: '', // Not a text field (showLog)
  };

  static String _generateDebugLevelsText() {
    // LEVELS = [  ALL,  FINEST,  FINER,  FINE,  CONFIG,  INFO,  WARNING,  SEVERE,  SHOUT,  OFF]
    return Level.LEVELS
        .mapIndexed(
            (index, level) => level.name.length <= 5 ? '$index-${level.name}' : '$index-${level.name.substring(0, 5)}')
        .join(',');
  }

  static Map<ParametersEnum, String> listAllowedChars = {
    ParametersEnum.bVersion: '[0-9.+]',
    ParametersEnum.bDefaultRanking: '[0-9]',
    ParametersEnum.bMatchDaysToView: '[0-9]',
    ParametersEnum.bMatchDaysKeeping: '[0-9]',
    ParametersEnum.bRegisterDaysAgoToView: '[0-9]',
    ParametersEnum.bRegisterDaysKeeping: '[0-9]',
    ParametersEnum.bDefaultCommentText: '', // free text
    ParametersEnum.bMinDebugLevel: '[0-${Level.LEVELS.length - 1}]',
    ParametersEnum.bWeekDaysMatch:
        '[${MyParameters.kDaysOfWeek.toLowerCase()}${MyParameters.kDaysOfWeek.toUpperCase()}]',
    ParametersEnum.bShowLog: '', // Not a text field (showLog)
  };
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

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);

    // Retrieve instances from Provider
    _appState = context.read<AppState>();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    // compare fields in case other user has changed any fields
    bool areFieldsDifferent(dynamic formValue, dynamic realValue) => formValue != null && formValue != realValue;
    // Use ParametersEnum to iterate through fields and compare
    bool fieldsChanged = ParametersEnum.valuesByType(ParamType.basic)
        .map((parameter) => areFieldsDifferent(
            _formKey.currentState?.fields[parameter.name]?.value, _appState.getParamValue(parameter)))
        .any((changed) => changed);

    if (fieldsChanged) {
      MyLog.log(_classString, 'Fields have changed', indent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UiHelper.showMessage(context, '¡Atención! Los datos han sido actualizados por otro usuario');
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
              for (var value in ParametersEnum.valuesByType(ParamType.basic))
                if (value != ParametersEnum.bShowLog) _buildTextField(value),

              // Show Log Checkbox
              _buildShowLogCheckbox(),

              const Divider(), // Divider for UI separation

              // Update Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
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

  /// Builds a FormBuilderTextField for a given parameter
  Widget _buildTextField(ParametersEnum parameter) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderTextField(
        name: parameter.name,
        initialValue: _appState.getParamValue(parameter),
        decoration: InputDecoration(
          labelText: _FormFields.label[parameter] ?? '',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.text,

        // Apply input formatters if allowed characters are specified
        inputFormatters: (_FormFields.listAllowedChars[parameter] ?? '').isNotEmpty
            ? [UpperCaseTextFormatter(RegExp(_FormFields.listAllowedChars[parameter]!), allow: true)]
            : [],

        // Validation logic
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'No puede estar vacío'),
          if (parameter == ParametersEnum.bWeekDaysMatch) _noDuplicateCharsValidator,
          if (parameter == ParametersEnum.bMinDebugLevel) _minDebugLevelValidator,
        ]),
      ),
    );
  }

  // Custom validator to prevent duplicate characters
  String? _noDuplicateCharsValidator(String? value) {
    if (value == null || value.isEmpty) return null; // Allow empty input

    final chars = value.split('');
    final uniqueChars = chars.toSet();

    if (chars.length != uniqueChars.length) {
      return 'No se permiten caracteres duplicados.';
    }
    return null; // Validation passed
  }

  // Custom validator for minDebugLevel
  String? _minDebugLevelValidator(String? value) {
    if (value == null || value.isEmpty) return null; // Allow empty input

    final int? intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Debe ser un número entero.';
    }

    if (intValue < 0 || intValue > Level.LEVELS.length - 1) {
      return 'Debe estar entre 0 y ${Level.LEVELS.length - 1}.';
    }

    return null; // Validation passed
  }

  /// Builds the Show Log checkbox with FormBuilderField
  Widget _buildShowLogCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FormBuilderField<bool>(
          name: ParametersEnum.bShowLog.name,
          initialValue: _appState.showLog,
          builder: (FormFieldState<bool> field) {
            return UiHelper.myCheckBox(
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
    MyLog.log(_classString, '_formValidate', level: Level.FINE);

    // Check if the form is valid before proceeding
    if (_formKey.currentState!.saveAndValidate()) {
      MyParameters myParameters = _appState.parameters;

      final formValues = _formKey.currentState!.value;

      for (var value in ParametersEnum.valuesByType(ParamType.basic)) {
        if (value == ParametersEnum.bShowLog) {
          // Convert bool to string before saving
          myParameters.setValue(value, boolToStr(formValues[value.name] ?? false));
        } else if (value == ParametersEnum.bWeekDaysMatch) {
          // Remove duplicate characters from weekDaysMatch
          myParameters.setValue(value, formValues[value.name].split('').toSet().join());
        } else {
          myParameters.setValue(value, formValues[value.name]);
        }
      }

      try {
        await FbHelpers().updateParameters(myParameters);
        if (mounted) {
          UiHelper.showMessage(context, 'Los parámetros han sido actualizados.');
        }
      } catch (e) {
        if (mounted) {
          UiHelper.showMessage(context, 'Error actualizando parámetros.');
        }
      }
    }
  }
}
