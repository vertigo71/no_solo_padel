import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:no_solo_padel/utilities/misc.dart';
import 'package:no_solo_padel/utilities/ui_helpers.dart';
import 'package:provider/provider.dart';
import 'package:simple_logger/simple_logger.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/director.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';

/// Class name identifier for logging
final String _classString = 'RankingParamPanel'.toUpperCase();

/// Helper class to define form fields and their properties
class _FormFields {
  static Map<ParametersEnum, String> label = {
    ParametersEnum.step: 'Mínimo de puntos por juego',
    ParametersEnum.range: 'Rango de puntos por juego',
    ParametersEnum.rankingDiffToHalf: 'Diferencia de rankings para sumar la mitad de puntos por juego',
    ParametersEnum.freePoints: 'Puntos por participar',
  };

  static Map<ParametersEnum, String> listAllowedChars = {
    ParametersEnum.step: '[0-9]',
    ParametersEnum.range: '[0-9]',
    ParametersEnum.rankingDiffToHalf: '[0-9]',
    ParametersEnum.freePoints: '[0-9]',
  };
}

enum TestFields {
  rankingA(displayName: 'Ranking equipo A', min: 1000, max: 15000),
  rankingB(displayName: 'Ranking equipo B', min: 1000, max: 15000),
  scoreA(displayName: 'A', min: 0, max: 15),
  scoreB(displayName: 'B', min: 0, max: 15),
  pointsA(displayName: 'Puntos equipo A', min: 0, max: 0),
  pointsB(displayName: 'Puntos equipo B', min: 0, max: 0),
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
  final _resetFormKey = GlobalKey<FormBuilderState>(); // Form key for the reset section

  late Director _director;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState', level: Level.FINE);

    // Retrieve instances from Provider
    _director = context.read<Director>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateResult(); // Calculate initial result after first frame
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
              _buildResetForm(),

              const Divider(),

              // Generate parameter fields dynamically
              for (var value in ParametersEnum.valuesByType(ParamType.ranking)) _buildTextField(value),
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

              // Test Form
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Spacer(),
                        Expanded(child: _buildTestDropdownField(TestFields.scoreA)),
                        Expanded(child: _buildTestDropdownField(TestFields.scoreB)),
                        Spacer(),
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
        initialValue: _director.appState.getParamValue(parameter),
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
      int freePoints = int.tryParse(values[ParametersEnum.freePoints.name] as String? ?? '') ?? 0;

      result = RankingPoints(
        step: step,
        range: range,
        rankingDiffToHalf: rankingDiffToHalf,
        freePoints: freePoints,
        rankingA: rankingA,
        rankingB: rankingB,
        scoreA: scoreA,
        scoreB: scoreB,
      ).calculatePoints();
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
              Expanded(child: _buildSingleResultField(TestFields.pointsA, result[0])),
              Expanded(child: _buildSingleResultField(TestFields.pointsB, result[1])),
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
        tileColor: Theme.of(context).colorScheme.surfaceBright,
        title: Text(field.displayName, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Center(child: Text('\n$result')),
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

  Widget _buildTestDropdownField(TestFields field) {
    List<int> dropdownValues = List.generate(field.max - field.min + 1, (index) => field.min + index);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilderDropdown<int>(
        name: field.name,
        initialValue: field.min,
        decoration: InputDecoration(
          labelText: field.displayName,
          border: const OutlineInputBorder(),
        ),
        items: dropdownValues.map((value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (_) => _updateResult(),
      ),
    );
  }

  void _updateResult() => setState(() {}); // Rebuild the widget to update the result

  Widget _buildResetForm() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FormBuilder(
        key: _resetFormKey,
        child: Row(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _resetRanking(),
                child: const Text('Reset Ranking'),
              ),
            ),
            Flexible(
              flex: 1,
              child: FormBuilderTextField(
                name: 'resetValue',
                decoration: InputDecoration(
                  labelText: 'Valor',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'No puede estar vacío'),
                  FormBuilderValidators.numeric(errorText: 'Debe ser un número válido'),
                  FormBuilderValidators.integer(errorText: 'Debe ser un número entero'),
                  FormBuilderValidators.min(0, errorText: 'Debe ser mayor o igual a 0'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetRanking() async {
    if (_resetFormKey.currentState!.saveAndValidate()) {
      final resetValue = int.parse(_resetFormKey.currentState!.value['resetValue'].toString());

      final confirmed = await UiHelper.showConfirmationModal(context, 'Confirmar Reset Ranking', 'ranking');
      if (confirmed) {
        // Implement your reset ranking logic here
        MyLog.log(_classString, 'Reset ranking to: $resetValue', indent: true);
        try {
          await FbHelpers().updateAllUserRankings(resetValue);
          await _director.updateAllUsers();

          MyLog.log(_classString, 'Reset ranking success', indent: true);
          if (mounted) UiHelper.showMessage(context, 'Ranking reseteado');
        } catch (e) {
          MyLog.log(_classString, 'Error al resetear ranking \n${e.toString()}', level: Level.SEVERE, indent: true);
          if (mounted) UiHelper.showMessage(context, 'Error al resetear ranking.\n${e.toString()}');
        }
      } else {
        MyLog.log(_classString, "Reset canceled.", level: Level.FINE, indent: true);
      }
    }
  }
}
