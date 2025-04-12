import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:provider/provider.dart';

import '../../database/db_firebase_helpers.dart';
import '../../interface/if_match_notifier.dart';
import '../../utilities/ut_http_helper.dart';
import '../../models/md_debug.dart';
import '../../models/md_match.dart';
import '../../interface/if_app_state.dart';
import '../../models/md_register.dart';
import '../../models/md_user.dart';
import '../../utilities/ut_misc.dart';
import '../../utilities/ui_helpers.dart';

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
  static const int kMaxNumberOfCourts = 6;
  static const String kCommentId = 'comment';
  static const String kCourtId = 'court';
  static const String kIsOpenId = 'isOpen';
  static const String kSortingId = 'sorting';

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Form for match=$match', level: Level.FINE);

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
    // to access instant values:
    //        _formKey.currentState?.instantValue['$courtId$i'] <=> _formKey.currentState?.fields['$courtId$i']?.value
    // to access saved values: _formKey.currentState?.value
    //

    // compare fields in case other user has changed any fields
    bool fieldsChanged = false;
    bool areFieldsDifferent(dynamic formValue, dynamic matchValue) => formValue != null && formValue != matchValue;
    fieldsChanged = areFieldsDifferent(_formKey.currentState?.fields[kCommentId]?.value, match.comment);
    fieldsChanged = fieldsChanged || areFieldsDifferent(_formKey.currentState?.fields[kIsOpenId]?.value, match.isOpen);
    fieldsChanged =
        fieldsChanged || areFieldsDifferent(_formKey.currentState?.fields[kSortingId]?.value, match.sortingType);
    fieldsChanged = fieldsChanged ||
        List.generate(
            kMaxNumberOfCourts,
            (i) => areFieldsDifferent(_formKey.currentState?.fields['$kCourtId$i']?.value,
                i < match.courtNamesReference.length ? match.courtNamesReference[i] : '')).any((changed) => changed);

    if (fieldsChanged) {
      // Only use addPostFrameCallback when you're showing a SnackBar (or AlertDialog, showDialog)
      // immediately after a rebuild, particularly within the build method.
      // If you're showing SnackBars in response to user interactions or asynchronous operations,
      // this overhead is unnecessary.
      MyLog.log(_classString, 'Fields have changed', indent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        UiHelper.showMessage(context, '¡Atención! Los datos han sido actualizados por otro usuario');
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
            _buildCourts(),

            const SizedBox(height: 30.0),

            // Open match
            _builtIsOpen(),

            const SizedBox(height: 30.0),

            // type of sorting
            _sortingType(),

            const SizedBox(height: 40.0),

            // Comments
            _buildComments(),

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

  Widget _buildComments() {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Comments', level: Level.FINE, indent: true);

    return FormBuilderTextField(
      name: kCommentId,
      decoration: InputDecoration(
        labelText: 'Comentarios',
        contentPadding: const EdgeInsets.all(8.0),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
      ),
      keyboardType: TextInputType.text,
      initialValue: match.comment,
    );
  }

  Widget _sortingType() {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building sorting type', level: Level.FINE, indent: true);

    return Padding(
      padding: const EdgeInsets.only(right: 18.0),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 10),
          Text('Tipo de sorteo:'),
          const SizedBox(width: 10),
          Expanded(
            child: FormBuilderDropdown<MatchSortingType>(
              name: kSortingId,
              initialValue: match.sortingType,
              items: MatchSortingType.values
                  .map((MatchSortingType type) => DropdownMenuItem<MatchSortingType>(
                        value: type,
                        child: Text(type.label),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourts() {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building Courts', level: Level.FINE, indent: true);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const Text('Pistas'),
        const SizedBox(width: 10.0),
        for (int i = 0; i < kMaxNumberOfCourts; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: FormBuilderTextField(
                name: '$kCourtId$i',
                // Unique name for each field
                decoration: InputDecoration(
                  // labelText: 'Pista ${i + 1}',
                  contentPadding: const EdgeInsets.all(8.0),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4.0)),
                  ),
                ),
                initialValue: i < match.courtNamesReference.length ? match.courtNamesReference[i] : '',
                inputFormatters: [UpperCaseTextFormatter(RegExp(r'[0-9a-zA-Z]'), allow: true)],
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center, // Center the text
              ),
            ),
          ),
      ],
    );
  }

  Widget _builtIsOpen() {
    MyMatch match = context.read<MatchNotifier>().match;
    MyLog.log(_classString, 'Building isOpen', level: Level.FINE, indent: true);

    return Row(
      children: <Widget>[
        const SizedBox(width: 10),
        Text('Abrir convocatoria'),
        const SizedBox(width: 10),
        FormBuilderField<bool>(
          name: kIsOpenId,
          initialValue: match.isOpen,
          builder: (FormFieldState<bool> field) {
            return UiHelper.myCheckBox(
              context: context,
              value: field.value ?? false,
              onChanged: (newValue) {
                field.didChange(newValue);
              },
            );
          },
        ),
      ],
    );
  }

  String _checkForm() {
    MyLog.log(_classString, '_checkForm check all courts', level: Level.FINE);

    // empty courts
    List<String> courts = [];
    for (int i = 0; i < kMaxNumberOfCourts; i++) {
      if (_formKey.currentState?.value['$kCourtId$i'].isNotEmpty) {
        courts.add(_formKey.currentState?.value['$kCourtId$i']);
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
    MyLog.log(_classString, '_formValidate: validate the form', level: Level.FINE);

    var state = _formKey.currentState;

    // Validate returns true if the form is valid, or false otherwise.
    if (state?.validate() ?? false) {
      // save all values
      state!.save();

      MyLog.log(_classString, '_formValidate: open=${state.value[kIsOpenId]}', indent: true);
      if (state.value[kIsOpenId]) {
        // if opening a match, check all fields
        String errorString = _checkForm();
        if (errorString.isNotEmpty) {
          UiHelper.myAlertDialog(context, errorString);
          return;
        }
      }

      // all is correct or match is not open
      MyMatch newMatch = MyMatch(id: context.read<MatchNotifier>().match.id);
      // add courts available
      for (int i = 0; i < kMaxNumberOfCourts; i++) {
        if (state.value['$kCourtId$i'].isNotEmpty) {
          newMatch.courtNamesReference.add(state.value['$kCourtId$i']);
        }
      }
      newMatch.comment = state.value[kCommentId];
      newMatch.isOpen = state.value[kIsOpenId];
      newMatch.sortingType = state.value[kSortingId];
      MyLog.log(_classString, '_formValidate: update match = $newMatch', indent: true);
      // Update to Firestore
      String message = 'Los datos han sido actualizados';
      try {
        MyMatch oldMatch = context.read<MatchNotifier>().match;
        AppState appState = context.read<AppState>();

        // upload firebase
        await FbHelpers().updateMatch(match: newMatch, updateCore: true, updatePlayers: false);
        // do not update notifier as the listener match_notifier will do it

        // logged user
        final MyUser? loggedUser = appState.loggedUser;
        if (loggedUser == null) {
          MyLog.log(_classString, '_formValidate loggedUser is null', level: Level.SEVERE);
          throw Exception('No se ha podido obtener el usuario conectado');
        }

        String registerText = '';
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
          FbHelpers().updateRegister(RegisterModel(date: newMatch.id, message: registerText));
          sendDatedMessageToTelegram(
            message: registerText,
            matchDate: newMatch.id,
          );
        }
      } catch (e) {
        message = 'ERROR en la actualización de los datos. \n\n ${e.toString()}';
        MyLog.log(_classString, '_formValidate ERROR en la actualización de los datos',
            exception: e, level: Level.SEVERE, indent: true);
      }

      if (mounted) UiHelper.showMessage(context, message);
    }
  }
}
