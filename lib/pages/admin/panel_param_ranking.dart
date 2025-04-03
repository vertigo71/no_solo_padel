import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/app_state.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../utilities/misc.dart';

/// Class name identifier for logging
final String _classString = 'RankingParamPanel'.toUpperCase();

/// Helper class to define form fields and their properties
class _FormFields {
  static Map<ParametersEnum, String> label = {
    ParametersEnum.step: 'Mínimo de puntos por juego',
    ParametersEnum.range: 'Rango de puntos por juego',
    ParametersEnum.rankingDiffToHalf: 'Diferencia de rankings para sumar la mitad de puntos por juego',
  };

  static Map<ParametersEnum, String> listAllowedChars = {
    ParametersEnum.step: '[0-9]',
    ParametersEnum.range: '[0-9]',
    ParametersEnum.rankingDiffToHalf: '[0-9]',
  };
}

enum TestFields {
  rankingA(displayName: 'Ranking equipo A', min: 1000, max: 10000),
  rankingB(displayName: 'Ranking equipo B', min: 1000, max: 10000),
  scoreA(displayName: 'Puntuación equipo A', min: 0, max: 10),
  scoreB(displayName: 'Puntuación equipo B', min: 0, max: 10),
  resultA(displayName: 'Resultado equipo A', min: 0, max: 0),
  resultB(displayName: 'Resultado equipo B', min: 0, max: 0),
  ;

  final String displayName;
  final int min;
  final int max;

  const TestFields({required this.displayName, required this.min, required this.max});
}

/// The main widget for the parameters panel
class RankingParamPanel extends StatefulWidget {
  const RankingParamPanel({super.key});

  @override
  RankingParamPanelState createState() => RankingParamPanelState();
}

/// State for ParametersPanel
class RankingParamPanelState extends State<RankingParamPanel> {
  final _formKey = GlobalKey<FormBuilderState>(); // Form key
  final _testFormKey = GlobalKey<FormBuilderState>(); // Form key for test section.

  late AppState _appState;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);

    // Retrieve instances from Provider
    _appState = context.read<AppState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateResult(); // Calculate initial sum after first frame
    });
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building', level: Level.FINE);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: FormBuilder(
          key: _formKey,
          child: ListView(
            children: [
              // Generate text fields dynamically (excluding showLog)
              for (var value in ParametersEnum.valuesByType(ParamType.ranking)) _buildTextField(value),
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
              const Divider(), // Divider for UI separation

              // add test values
              FormBuilder(
                key: _testFormKey,
                child: Column(
                  children: [
                    // title
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Test', style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    // show results
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: _showTestResults(),
                    ),
                    // selectors
                    _buildTestSliderField(TestFields.rankingA),
                    _buildTestSliderField(TestFields.rankingB),
                    Row(
                      children: [
                        Expanded(child: _buildTestSliderField(TestFields.scoreA)),
                        Expanded(child: _buildTestSliderField(TestFields.scoreB)),
                      ],
                    ),
                    const SizedBox(height: 56.0),
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
        ]),
        onChanged: (_) => _updateResult(),
      ),
    );
  }

  /// Validates and submits the form
  Future<void> _formValidate() async {
    MyLog.log(_classString, '_formValidate', level: Level.FINE);

    // Check if the form is valid before proceeding
    if (_formKey.currentState!.saveAndValidate()) {
      MyParameters myParameters = MyParameters();
      final formValues = _formKey.currentState!.value;

      for (var value in ParametersEnum.valuesByType(ParamType.ranking)) {
        myParameters.setValue(value, formValues[value.name]);
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

  Widget _showTestResults() {
    List<int> result;

    if (_formKey.currentState == null || _testFormKey.currentState == null) {
      result = [-1, -1];
    } else {
      final Map<String, dynamic> values = _formKey.currentState!.instantValue;
      final Map<String, dynamic> testValues = _testFormKey.currentState!.instantValue;

      // get all test values
      int rankingA = (testValues[TestFields.rankingA.name] as double? ?? 0).toInt();
      int rankingB = (testValues[TestFields.rankingB.name] as double? ?? 0).toInt();
      int scoreA = (testValues[TestFields.scoreA.name] as double? ?? 0).toInt();
      int scoreB = (testValues[TestFields.scoreB.name] as double? ?? 0).toInt();
      // get parameters values
      int step = int.tryParse(values[ParametersEnum.step.name] as String? ?? '') ?? 0;
      int range = int.tryParse(values[ParametersEnum.range.name] as String? ?? '') ?? 0;
      int rankingDiffToHalf = int.tryParse(values[ParametersEnum.rankingDiffToHalf.name] as String? ?? '') ?? 0;

      result = calculatePoints(step, range, rankingDiffToHalf, rankingA, rankingB, scoreA, scoreB);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20.0,
        children: [
          const Text('Los puntos por juego obtenidos para cada equipo serían:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: _buildSingleResultField(TestFields.resultA, result[0])),
              Expanded(child: _buildSingleResultField(TestFields.resultB, result[1])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleResultField(TestFields field, int result) {
    return Card(
      elevation: 6.0,
      child: ListTile(
        tileColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(field.displayName, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text('\n$result'),
      ),
    );
  }

  Widget _buildTestSliderField(TestFields field) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderSlider(
        name: field.name,
        min: field.min.toDouble(),
        max: field.max.toDouble(),
        initialValue: (field.min + field.max) / 2,
        // Set an initial value
        decoration: InputDecoration(
          labelText: field.displayName,
          border: const OutlineInputBorder(),
        ),
        divisions: field.max - field.min,
        // Make slider discrete
        numberFormat: NumberFormat("#,###", 'es_ES'),
        onChanged: (_) => _updateResult(),
      ),
    );
  }

  void _updateResult() {
    setState(() {}); // Rebuild the widget to update the result
  }
}
