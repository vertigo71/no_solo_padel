import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:collection/collection.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../utilities/misc.dart';

/// Class name identifier for logging
final String _classString = 'ParametersPanel'.toUpperCase();

/// Helper class to define form fields and their properties
class _FormFields {
  static Map<ParametersEnum, String> label = {
    ParametersEnum.matchDaysToView: 'Partidos: ver número de días',
    ParametersEnum.matchDaysKeeping: 'Partidos: histórico de días a conservar',
    ParametersEnum.registerDaysAgoToView: 'Registro: ver número de días atrás',
    ParametersEnum.registerDaysKeeping: 'Registro: histórico de días a conservar',
    ParametersEnum.fromDaysAgoToTelegram: 'Enviar telegram si partido es antes de (días)',
    ParametersEnum.defaultCommentText: 'Texto por defecto del comentario',
    ParametersEnum.minDebugLevel: 'Debug (${_generateDebugLevelsText()})',
    ParametersEnum.weekDaysMatch: 'Días que se pueden jugar (${MyParameters.daysOfWeek})',
    ParametersEnum.showLog: '', // Not a text field (showLog)
  };

  static String _generateDebugLevelsText() {
    return Level.LEVELS
        .mapIndexed(
            (index, level) => level.name.length <= 5 ? '$index-${level.name}' : '$index-${level.name.substring(0, 5)}')
        .join(',');
  }

  static Map<ParametersEnum, String> listAllowedChars = {
    ParametersEnum.matchDaysToView: '[0-9]',
    ParametersEnum.matchDaysKeeping: '[0-9]',
    ParametersEnum.registerDaysAgoToView: '[0-9]',
    ParametersEnum.registerDaysKeeping: '[0-9]',
    ParametersEnum.fromDaysAgoToTelegram: '[0-9]',
    ParametersEnum.defaultCommentText: '', // free text
    ParametersEnum.minDebugLevel: '[0-${Level.LEVELS.length - 1}]',
    ParametersEnum.weekDaysMatch: '[${MyParameters.daysOfWeek.toLowerCase()}${MyParameters.daysOfWeek.toUpperCase()}]',
    ParametersEnum.showLog: '', // Not a text field (showLog)
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
    MyLog.log(_classString, 'Building', level:Level.FINE);

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
          if (parameter == ParametersEnum.weekDaysMatch) _noDuplicateCharsValidator,
          if (parameter == ParametersEnum.minDebugLevel) _minDebugLevelValidator,
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
          name: ParametersEnum.showLog.name,
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
    MyLog.log(_classString, '_formValidate', level: Level.FINE );

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
