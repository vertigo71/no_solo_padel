import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:no_solo_padel_dev/database/firebase.dart';
import 'package:no_solo_padel_dev/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../interface/director.dart';
import '../../interface/telegram.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../interface/app_state.dart';
import '../../models/parameter_model.dart';
import '../../models/register_model.dart';
import '../../utilities/misc.dart';

final String _classString = 'ConfigurationPanel'.toUpperCase();

class ConfigurationPanel extends StatefulWidget {
  const ConfigurationPanel(this.date, {Key? key}) : super(key: key);

  // arguments
  final Date date;

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

  static const int maxNumberOfCourts = 4;
  List<TextEditingController> courtControllers = [];
  List<String> initialCourtValues = [];

  static const String commentTextField = 'Comentarios';
  TextEditingController commentController = TextEditingController();
  String initialCommentValue = '';

  // checkBox
  bool isMatchOpen = false;

  @override
  void initState() {
    MyMatch match = context.read<AppState>().getMatch(widget.date) ?? MyMatch(date: widget.date);
    MyLog().log(_classString, 'initState arguments = $match');

    isMatchOpen = match.isOpen;
    initialCourtValues.addAll(match.courtNames);
    initialCommentValue = match.comment;

    MyLog().log(_classString, 'initState Initial court values = $initialCourtValues');

    for (var value in initialCourtValues) {
      courtControllers.add(TextEditingController()..text = value);
    }
    while (courtControllers.length < maxNumberOfCourts) {
      courtControllers.add(TextEditingController());
    }
    commentController.text = initialCommentValue;

    super.initState();
  }

  @override
  void dispose() {
    for (var controller in courtControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void refresh(bool isMatchOpen) {
    setState(() {
      this.isMatchOpen = isMatchOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyLog().log(_classString, 'Building');

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConfigurationFormWidgets(courtControllers, commentController, this),
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
    // empty courts
    List<String> courts = [];
    for (var controller in courtControllers) {
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
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      if (isMatchOpen) {
        // if opening a match, check all fields
        String errorString = _checkConfigurationForm();
        if (errorString.isNotEmpty) {
          myAlertDialog(context, errorString);
          return;
        }
      }

      // all is correct or match is not open
      MyMatch newMatch = MyMatch(date: widget.date);
      // add courts available
      for (var controller in courtControllers) {
        if (controller.text.isNotEmpty) {
          newMatch.courtNames.add(controller.text);
        }
      }
      newMatch.comment = commentController.text;
      newMatch.isOpen = isMatchOpen;
      MyLog().log(_classString, 'update match = $newMatch');
      // Update to Firebase
      String message = 'Los datos han sido actualizados';
      try {
        MyMatch? oldMatch = context.read<AppState>().getMatch(widget.date);
        FirebaseHelper firebaseHelper = context.read<Director>().firebaseHelper;
        AppState appState = context.read<AppState>();

        /// upload firebase
        await context
            .read<Director>()
            .firebaseHelper
            .uploadMatch(match: newMatch, updateCore: true, updatePlayers: false);

        if (oldMatch != null) {
          String registerText = '';
          MyUser loggedUser = appState.getLoggedUser();
          int newNumCourts = newMatch.getNumberOfCourts();

          /// detect if the match has been opened or closed
          /// otherwise detect if there is a change in the number of courts
          if (newMatch.isOpen != oldMatch.isOpen) {
            if (newMatch.isOpen) {
              String courtsText =
                  newNumCourts.toString() + (newNumCourts == 1 ? ' pista' : ' pistas');
              registerText = 'Nueva convocatoria\n'
                  '${loggedUser.name} ha abierto $courtsText';
            } else {
              registerText = '${loggedUser.name} ha cerrado la convocatoria';
            }
          } else if (oldMatch.getNumberOfCourts() != newNumCourts && newMatch.isOpen) {
            String courtsText = newNumCourts.toString() +
                (newNumCourts == 1 ? ' pista disponible' : ' pistas disponibles');
            registerText = '${loggedUser.name}  ha modificado el número de pistas\n'
                'Ahora hay $courtsText';
          }

          if (registerText.isNotEmpty) {
            firebaseHelper.uploadRegister(
                register: RegisterModel(date: newMatch.date, message: registerText));
            TelegramHelper.sendFormattedMessage(
                message: registerText,
                matchDate: newMatch.date,
                fromDaysAgoToTelegram:
                    appState.getIntParameterValue(ParametersEnum.fromDaysAgoToTelegram));
          }
        }
      } catch (e) {
        message = 'ERROR en la actualización de los datos. \n\n $e';
        MyLog().log(_classString, 'ERROR en la actualización de los datos',
            exception: e, debugType: DebugType.error);
      }

      showMessage(context, message);
    }
  }
}

class ConfigurationFormWidgets extends StatelessWidget {
  const ConfigurationFormWidgets(
      this.courtControllers, this.commentController, this.configurationPanelState,
      {Key? key})
      : super(key: key);
  final List<TextEditingController> courtControllers;
  final TextEditingController commentController;
  final ConfigurationPanelState configurationPanelState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Courts
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('Pistas'),
            const SizedBox(width: 20.0),
            for (var controller in courtControllers)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ConfigurationFormSingleWidget(
                    fieldName: '',
                    textController: controller,
                    formatter: UpperCaseTextFormatter(RegExp(r'[0-9a-zA-Z]'), allow: true),
                    validate: configurationPanelState._formValidate,
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
              value: configurationPanelState.isMatchOpen,
              onChanged: (bool? value) {
                configurationPanelState.refresh(value!);
              },
            ),
          ],
        ),
        // comments
        const SizedBox(height: 10.0),
        ConfigurationFormSingleWidget(
          fieldName: ConfigurationPanelState.commentTextField,
          textController: commentController,
          validate: configurationPanelState._formValidate,
        )
      ],
    );
  }
}

class ConfigurationFormSingleWidget extends StatelessWidget {
  const ConfigurationFormSingleWidget(
      {required this.fieldName,
      required this.textController,
      required this.validate,
      this.mayBeEmpty = true,
      this.formatter,
      Key? key})
      : super(key: key);
  final String fieldName;
  final TextEditingController textController;
  final bool mayBeEmpty;
  final FilteringTextInputFormatter? formatter;
  final Future<void> Function() validate;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      inputFormatters: [
        // only accept letters from a to z
        if (formatter != null) formatter!,
      ],
      onFieldSubmitted: (String str) async => await validate(),
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
