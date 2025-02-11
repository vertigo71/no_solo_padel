import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../database/firebase.dart';
import '../../interface/director.dart';
import '../../interface/match_notifier.dart';
import '../../utilities/http_helper.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../interface/app_state.dart';
import '../../models/parameter_model.dart';
import '../../models/register_model.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

final String _classString = 'ConfigurationPanel'.toUpperCase();

class ConfigurationPanel extends StatefulWidget {
  const ConfigurationPanel({super.key});

  @override
  ConfigurationPanelState createState() {
    return ConfigurationPanelState();
  }
}

class ConfigurationPanelState extends State<ConfigurationPanel> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<SettingsPageState>.
  final _formKey = GlobalKey<FormState>();

  static const int maxNumberOfCourts = 6;
  final List<TextEditingController> _courtControllers =
      List.generate(maxNumberOfCourts, (index) => TextEditingController());

  static const String commentTextField = 'Comentarios';
  final TextEditingController _commentController = TextEditingController();

  // checkBox
  bool _isMatchOpen = false;

  @override
  void initState() {
    super.initState();
    MyLog.log(_classString, 'initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final MyMatch match = context.read<MatchNotifier>().match;
    final AppState appState = context.read<AppState>();
    MyLog.log(_classString, 'didChangeDependencies initial values match=$match', level: Level.INFO);

    _isMatchOpen = match.isOpen;
    // initial comment
    if (match.comment == '') {
      _commentController.text = appState.getParameterValue(ParametersEnum.defaultCommentText);
    } else {
      _commentController.text = match.comment;
    }

    // initial courtValues
    for (int i = 0; i < min(match.courtNames.length, _courtControllers.length); i++) {
      _courtControllers[i].text = match.courtNames[i];
    }
  }

  @override
  void dispose() {
    MyLog.log(_classString, 'dispose');

    _commentController.dispose();
    for (var controller in _courtControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleIsOpenChanged(bool newValue) {
    MyLog.log(_classString, '_handleIsOpenChanged isMatchOpen changed $newValue', level: Level.INFO);

    setState(() {
      _isMatchOpen = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyLog.log(_classString, 'Building Form');

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConfigurationFormWidgets(
              courtControllers: _courtControllers,
              commentController: _commentController,
              formKey: _formKey,
              onIsOpenChanged: _handleIsOpenChanged,
              isMatchOpen: _isMatchOpen,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: const Text('Aceptar'),
                    onPressed: () async => await _formValidate(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _checkConfigurationForm() {
    MyLog.log(_classString, 'check all fields');

    // empty courts
    List<String> courts = [];
    for (var controller in _courtControllers) {
      if (controller.text.isNotEmpty) {
        courts.add(controller.text);
      }
    }
    if (courts.isEmpty) return 'No se puede convocar un partido sin pistas';

    // repeated courts
    if (courts.length != Set.from(courts).length) {
      return 'Pistas repetidas';
    }

    return '';
  }

  Future<void> _formValidate() async {
    MyLog.log(_classString, 'validate the form');

    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      if (_isMatchOpen) {
        // if opening a match, check all fields
        String errorString = _checkConfigurationForm();
        if (errorString.isNotEmpty) {
          myAlertDialog(context, errorString);
          return;
        }
      }

      // all is correct or match is not open
      MyMatch newMatch = MyMatch(date: context.read<MatchNotifier>().match.date);
      // add courts available
      for (var controller in _courtControllers) {
        if (controller.text.isNotEmpty) {
          newMatch.courtNames.add(controller.text);
        }
      }
      newMatch.comment = _commentController.text;
      newMatch.isOpen = _isMatchOpen;
      MyLog.log(_classString, 'update match = $newMatch');
      // Update to Firebase
      String message = 'Los datos han sido actualizados';
      try {
        MyMatch oldMatch = context.read<MatchNotifier>().match;
        FirebaseHelper firebaseHelper = context.read<Director>().firebaseHelper;
        AppState appState = context.read<AppState>();

        /// upload firebase
        await firebaseHelper.updateMatch(match: newMatch, updateCore: true, updatePlayers: false);

        String registerText = '';
        MyUser loggedUser = appState.getLoggedUser();
        int newNumCourts = newMatch.getNumberOfCourts();

        /// detect if the match has been opened or closed
        /// otherwise detect if there is a change in the number of courts
        if (newMatch.isOpen != oldMatch.isOpen) {
          if (newMatch.isOpen) {
            registerText =
                'Nueva convocatoria\n${loggedUser.name} ha abierto ${singularOrPlural(newNumCourts, 'pista')}';
          } else {
            registerText = '${loggedUser.name} ha cerrado la convocatoria';
          }
        } else if (oldMatch.getNumberOfCourts() != newNumCourts && newMatch.isOpen) {
          registerText =
              '${loggedUser.name}  ha modificado el número de pistas\nAhora hay ${singularOrPlural(newNumCourts, 'pista disponible', 'pistas disponibles')}';
        }

        if (registerText.isNotEmpty) {
          firebaseHelper.updateRegister(RegisterModel(date: newMatch.date, message: registerText));
          sendDatedMessageToTelegram(
            message: registerText,
            matchDate: newMatch.date,
          );
        }

        // update notifier
        if (mounted) context.read<MatchNotifier>().updateMatch(newMatch);
      } catch (e) {
        message = 'ERROR en la actualización de los datos. \n\n $e';
        MyLog.log(_classString, 'ERROR en la actualización de los datos', exception: e, level: Level.SEVERE);
      }

      if (mounted) showMessage(context, message);
    }
  }
}

class ConfigurationFormWidgets extends StatelessWidget {
  const ConfigurationFormWidgets({
    required this.courtControllers,
    required this.commentController,
    required this.formKey,
    required this.onIsOpenChanged,
    required this.isMatchOpen,
    super.key,
  });

  final List<TextEditingController> courtControllers;
  final TextEditingController commentController;
  final GlobalKey<FormState> formKey;
  final Function(bool) onIsOpenChanged;
  final bool isMatchOpen;

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'ConfigurationFormWidgets creating widgets. Open=$isMatchOpen', level: Level.INFO);

    return Column(
      children: [
        // Courts
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Pistas'),
            const SizedBox(width: 10.0),
            for (var controller in courtControllers)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ConfigurationFormSingleWidget(
                    fieldName: '',
                    textController: controller,
                    formatter: UpperCaseTextFormatter(RegExp(r'[0-9a-zA-Z]'), allow: true),
                    formKey: formKey,
                  ),
                ),
              ),
          ],
        ),
        // Open match
        const SizedBox(height: 10.0),
        Row(
          children: <Widget>[
            const SizedBox(width: 10),
            const Text('Abrir convocatoria'),
            const SizedBox(width: 10),
            myCheckBox(
              context: context,
              value: isMatchOpen,
              onChanged: (bool? value) {
                onIsOpenChanged(value!);
              },
            ),
          ],
        ),
        // comments
        const SizedBox(height: 10.0),
        ConfigurationFormSingleWidget(
          fieldName: ConfigurationPanelState.commentTextField,
          textController: commentController,
          formKey: formKey,
        )
      ],
    );
  }
}

class ConfigurationFormSingleWidget extends StatelessWidget {
  const ConfigurationFormSingleWidget(
      {required this.fieldName,
      required this.textController,
      required this.formKey,
      this.mayBeEmpty = true,
      this.formatter,
      super.key});

  final String fieldName;
  final TextEditingController textController;
  final GlobalKey<FormState> formKey;
  final bool mayBeEmpty;
  final FilteringTextInputFormatter? formatter;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      inputFormatters: [
        // only accept letters from a to z
        if (formatter != null) formatter!,
      ],
      onFieldSubmitted: (String str) {
        formKey.currentState!.validate(); // Validate using the formKey
      },
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: fieldName,
        contentPadding: const EdgeInsets.all(8.0),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
      controller: textController,
      // The validator receives the text that the user has entered.
      validator: (value) {
        if (!mayBeEmpty && (value == null || value.isEmpty)) {
          return 'No puede estar vacío';
        }
        return null;
      },
    );
  }
}
