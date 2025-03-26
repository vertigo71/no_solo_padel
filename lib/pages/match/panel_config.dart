import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/firebase_helpers.dart';
import '../../interface/director.dart';
import '../../interface/match_notifier.dart';
import '../../utilities/http_helper.dart';
import '../../models/debug.dart';
import '../../models/match_model.dart';
import '../../interface/app_state.dart';
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
  final _formKey = GlobalKey<FormBuilderState>();
  static const int maxNumberOfCourts = 6;
  static const String commentId = 'comment';
  static const String courtId = 'court';
  static const String isOpenId = 'isOpen';

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Form for match=$match');

    // // initial values for all fields
    // // FormBuilder initial values do not work in case another user updates any field
    // _formKey.currentState?.fields[commentId]?.didChange(match.comment);
    // _formKey.currentState?.fields[isOpenId]?.didChange(match.isOpen);
    // for (int i = 0; i < maxNumberOfCourts; i++) {
    //   if (i < match.courtNames.length) {
    //     _formKey.currentState?.fields['$courtId$i']?.didChange(match.courtNames[i]);
    //   } else {
    //     _formKey.currentState?.fields['$courtId$i']?.didChange('');
    //   }
    // }

    // compare fields in case other user has changed any fields
    bool fieldsChanged = false;
    bool areFieldsDifferent(dynamic formValue, dynamic matchValue) => formValue != null && formValue != matchValue;
    fieldsChanged = areFieldsDifferent(_formKey.currentState?.fields[commentId]?.value, match.comment);
    fieldsChanged = fieldsChanged || areFieldsDifferent(_formKey.currentState?.fields[isOpenId]?.value, match.isOpen);
    fieldsChanged = fieldsChanged ||
        List.generate(
            maxNumberOfCourts,
            (i) => areFieldsDifferent(_formKey.currentState?.fields['$courtId$i']?.value,
                i < match.courtNames.length ? match.courtNames[i] : '')).any((changed) => changed);

    if (fieldsChanged) {
      // Only use addPostFrameCallback when you're showing a SnackBar (or AlertDialog, showDialog)
      // immediately after a rebuild, particularly within the build method.
      // If you're showing SnackBars in response to user interactions or asynchronous operations,
      // this overhead is unnecessary.
      MyLog.log(_classString, 'Fields have changed', indent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage(context, '¡Atención! Los datos han sido actualizados por otro usuario');
      });
    }

    return FormBuilder(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30.0),

            // Courts
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('Pistas'),
                const SizedBox(width: 10.0),
                for (int i = 0; i < maxNumberOfCourts; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: FormBuilderTextField(
                        name: '$courtId$i',
                        // Unique name for each field
                        decoration: InputDecoration(
                          // labelText: 'Pista ${i + 1}',
                          contentPadding: const EdgeInsets.all(8.0),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4.0)),
                          ),
                        ),
                        initialValue: i < match.courtNames.length ? match.courtNames[i] : '',
                        inputFormatters: [UpperCaseTextFormatter(RegExp(r'[0-9a-zA-Z]'), allow: true)],
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center, // Center the text
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 30.0),

            // Open match
            Row(
              children: <Widget>[
                const SizedBox(width: 10),
                Text('Abrir convocatoria ${match.isOpen ? 'SI' : 'NO'}'),
                const SizedBox(width: 10),
                FormBuilderField<bool>(
                  name: isOpenId,
                  initialValue: match.isOpen,
                  builder: (FormFieldState<bool> field) {
                    return myCheckBox(
                      context: context,
                      value: field.value ?? false,
                      onChanged: (newValue) {
                        field.didChange(newValue);
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 40.0),

            // Comments
            FormBuilderTextField(
              name: commentId,
              decoration: InputDecoration(
                labelText: 'Comentarios',
                contentPadding: const EdgeInsets.all(8.0),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4.0)),
                ),
              ),
              keyboardType: TextInputType.text,
              initialValue: match.comment,
            ),

            // Aceptar button
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
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

  String _checkForm() {
    MyLog.log(_classString, '_checkForm check all courts');

    // empty courts
    List<String> courts = [];
    for (int i = 0; i < maxNumberOfCourts; i++) {
      if (_formKey.currentState?.value['$courtId$i'].isNotEmpty) {
        courts.add(_formKey.currentState?.value['$courtId$i']);
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
    MyLog.log(_classString, '_formValidate: validate the form');

    var state = _formKey.currentState;

    // Validate returns true if the form is valid, or false otherwise.
    if (state?.validate() ?? false) {
      // save all values
      state!.save();

      MyLog.log(_classString, '_formValidate: open=${state.value[isOpenId]}', indent: true);
      if (state.value[isOpenId]) {
        // if opening a match, check all fields
        String errorString = _checkForm();
        if (errorString.isNotEmpty) {
          myAlertDialog(context, errorString);
          return;
        }
      }

      // all is correct or match is not open
      MyMatch newMatch = MyMatch(id: context.read<MatchNotifier>().match.id);
      // add courts available
      for (int i = 0; i < maxNumberOfCourts; i++) {
        if (state.value['$courtId$i'].isNotEmpty) {
          newMatch.courtNames.add(state.value['$courtId$i']);
        }
      }
      newMatch.comment = state.value[commentId];
      newMatch.isOpen = state.value[isOpenId];
      MyLog.log(_classString, '_formValidate: update match = $newMatch', indent: true);
      // Update to Firestore
      String message = 'Los datos han sido actualizados';
      try {
        MyMatch oldMatch = context.read<MatchNotifier>().match;
        FbHelpers fbHelpers = context.read<Director>().fbHelpers;
        AppState appState = context.read<AppState>();

        // upload firebase
        await fbHelpers.updateMatch(match: newMatch, updateCore: true, updatePlayers: false);
        // do not update notifier as the listener match_notifier will do it

        String registerText = '';
        MyUser loggedUser = appState.getLoggedUser();
        int newNumCourts = newMatch.getNumberOfCourts();

        // detect if the match has been opened or closed
        // otherwise detect if there is a change in the number of courts
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
          fbHelpers.updateRegister(RegisterModel(date: newMatch.id, message: registerText));
          sendDatedMessageToTelegram(
            message: registerText,
            matchDate: newMatch.id,
          );
        }
      } catch (e) {
        message = 'ERROR en la actualización de los datos. \n\n $e';
        MyLog.log(_classString, '_formValidate ERROR en la actualización de los datos',
            exception: e, level: Level.SEVERE, indent: true);
      }

      if (mounted) showMessage(context, message);
    }
  }
}
