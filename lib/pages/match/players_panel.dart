import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../database/firestore_helpers.dart';
import '../../interface/app_state.dart';
import '../../interface/director.dart';
import '../../interface/match_notifier.dart';
import '../../utilities/http_helper.dart';
import '../../models/debug.dart';
import '../../models/parameter_model.dart';
import '../../models/register_model.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../utilities/misc.dart';

final String _classString = 'PlayersPanel'.toUpperCase();

class PlayersPanel extends StatefulWidget {
  const PlayersPanel(this.initialMatch, {super.key});

  final MyMatch initialMatch;

  @override
  PlayersPanelState createState() => PlayersPanelState();
}

/// TODO: call updateMatch when match updated in the firebase

class PlayersPanelState extends State<PlayersPanel> {
  late final AppState appState;
  late final MyUser loggedUser;
  late MyUser selectedUser;
  late MyMatch initialMatch;

  final TextEditingController userPositionController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Context Available: addPostFrameCallback ensures that the callback is executed
      // after the first frame is built,
      // so the BuildContext is available and providers are initialized.
      appState = context.read<AppState>();
      initialMatch = widget.initialMatch;

      loggedUser = appState.getLoggedUser();
      selectedUser = appState.sortUsers[0];

      MyLog.log(_classString, 'initState arguments = $initialMatch');
    });
  }

  @override
  void dispose() {
    userPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyLog.log(_classString, 'Building for $loggedUser');

    final matchNotifier = context.watch<MatchNotifier>(); // Watch for changes in the match
    initialMatch = matchNotifier.match;

    return ListView(
      children: [
        actualState(),
        const Divider(thickness: 5),
        signUpForm(),
        const Divider(thickness: 5),
        listOfPlayers(),
        const SizedBox(height: 20),
        if (appState.isLoggedUserAdmin) const Divider(thickness: 5),
        const SizedBox(height: 20),
        if (appState.isLoggedUserAdmin) signUpAdminForm(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget actualState() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Builder(
          builder: (context) {
            String returnText = '';
            initialMatch = context.read<MatchNotifier>().match;
            if (initialMatch.isInTheMatch(loggedUser)) {
              if (initialMatch.isPlaying(loggedUser)) {
                returnText = 'Juegas!!!';
              } else {
                returnText = 'Apuntado\n(pendiente de completar pista)';
              }
            } else {
              returnText = 'No apuntado';
            }
            return Text(
              returnText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            );
          },
        ),
      );

  Widget signUpForm() => Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text('¿Te apuntas?'),
            const SizedBox(width: 20),
            Builder(
              builder: (context) {
                bool loggedUserInTheMatch = context.read<MatchNotifier>().match.isInTheMatch(loggedUser);

                return myCheckBox(
                  context: context,
                  value: loggedUserInTheMatch,
                  onChanged: (bool? value) {
                    setState(() {
                      loggedUserInTheMatch = value!;
                    });
                    validate(
                      user: loggedUser,
                      toAdd: loggedUserInTheMatch, // loggedUserInTheMatch? add Player : delete Player
                      adminManagingUser: false,
                    );
                  },
                );
              },
            ),
          ],
        ),
      );

  Widget listOfPlayers() => Builder(
        builder: (context) {
          int playerNumber = 0;
          MyLog.log(_classString, 'Building listOfPlayers');
          MyMatch match = context.read<MatchNotifier>().match;

          List<MyUser> usersPlaying = match.getPlayers(state: PlayingState.playing);
          List<MyUser> usersSigned = match.getPlayers(state: PlayingState.signedNotPlaying);
          List<MyUser> usersReserve = match.getPlayers(state: PlayingState.reserve);
          List<MyUser> usersFillEmptySpaces = [];
          for (int i = usersPlaying.length + usersSigned.length; i < match.getNumberOfCourts() * 4; i++) {
            usersFillEmptySpaces.add(MyUser());
          }

          String numCourtsText = 'disponible ${singularOrPlural(match.getNumberOfCourts(), 'pista')}';

          return Column(
            children: [
              Card(
                elevation: 6,
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  tileColor: Theme.of(context).appBarTheme.backgroundColor,
                  title: Text('Apuntados ($numCourtsText)'),
                ),
              ),
              Card(
                elevation: 6,
                margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...usersPlaying
                          .map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                      ...usersSigned.map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}',
                          style: const TextStyle(color: Colors.red))),
                      ...usersFillEmptySpaces.map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ')),
                    ],
                  ),
                ),
              ),
              if (usersReserve.isNotEmpty)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    tileColor: Theme.of(context).appBarTheme.backgroundColor,
                    title: const Text('Reservas'),
                  ),
                ),
              if (usersReserve.isNotEmpty)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...usersReserve
                            .map((player) => Text('${(++playerNumber).toString().padLeft(3)} - ${player.name}')),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Future<bool> validate({
    /// add/remove user from Match in Firebase
    required MyUser user,
    required bool toAdd, // add/remove user to match
    required bool adminManagingUser,
  }) async {
    MyLog.log(_classString, 'validate');
    FsHelpers fsHelpers = context.read<Director>().fsHelpers;

    MyMatch? myMatch; // match != null if added or deleted
    String registerText = ''; // text to be added to the register
    // add/remove from Firebase
    try {
      if (toAdd) {
        int listPosition = -1;
        if (adminManagingUser) {
          // get position from the controller (position = controllerText -1)
          listPosition = int.tryParse(userPositionController.text) ?? -1;
          if (listPosition > 0) listPosition--;
        }
        myMatch = await fsHelpers.addPlayerToMatch(
            appState: appState, date: context.read<MatchNotifier>().match.date, player: user, position: listPosition);
        if (myMatch != null) {
          listPosition = myMatch.getPlayerPosition(user);
          if (listPosition == -1) {
            MyLog.log(_classString, 'validate player $user not in match $myMatch', level: Level.SEVERE);
          }
          if (adminManagingUser) {
            registerText = '${loggedUser.name} ha apuntado a ${user.name} (${listPosition + 1})';
          } else {
            registerText = '${user.name} se ha apuntado  (${listPosition + 1})';
          }
        }
      } else {
        if (adminManagingUser) {
          registerText = '${loggedUser.name} ha desapuntado a ${user.name}';
        } else {
          // if not admin mode, certify loggedUser wants to signOff from the match
          bool delete = await _confirmLoggedUserOutOfMatch();
          if (!delete) {
            // abort deletion
            setState(() {
              // loggedUser is still in the match
              // refresh
            });
            if (mounted) showMessage(context, 'Operación anulada');
            return false;
          }
          registerText = '${user.name} se ha desapuntado';
        }
        if (mounted) {
          myMatch = await fsHelpers.deletePlayerFromMatch(
              appState: appState, date: context.read<MatchNotifier>().match.date, user: user);
        }
      }
    } on FirebaseException catch (e) {
      if (mounted) myAlertDialog(context, 'Error!!! Comprueba que estás apuntado/desapuntado\n $e');
      return false;
    } catch (e) {
      if (mounted) {
        myAlertDialog(
            context,
            'Ha habido una incidencia! \n'
            'Comprobar que la operación se ha realizado correctamente\n $e');
      }
    }

    MyLog.log(_classString, 'validate firebase done: Match=$myMatch Register=$registerText', level: Level.INFO);

    if (myMatch == null) {
      // no action has been taken
      if (toAdd) {
        if (mounted) showMessage(context, 'El jugador ya estaba en el partido');
      } else {
        if (mounted) showMessage(context, 'El jugador no estaba en el partido');
      }
      return false;
    } else {
      // notify match has changed
      // this is Key to update all panels
      // if (mounted) context.read<MatchNotifier>().updateMatch(myMatch); // TODO: not to do listener will
    }

    //  state updated via consumers
    // telegram and register
    try {
      MyLog.log(_classString, 'validate $user update register', level: Level.INFO);
      if (mounted) {
        await fsHelpers.updateRegister(RegisterModel(
          date: context.read<MatchNotifier>().match.date,
          message: registerText,
        ));
      }
      MyLog.log(_classString, 'validate $user send telegram', level: Level.INFO);
      if (mounted) {
        sendDatedMessageToTelegram(
            message: '$registerText\n'
                'APUNTADOS: ${myMatch.players.length} de ${myMatch.getNumberOfCourts() * 4}',
            matchDate: context.read<MatchNotifier>().match.date,
            fromDaysAgoToTelegram: appState.getIntParameterValue(ParametersEnum.fromDaysAgoToTelegram));
      }
    } catch (e) {
      MyLog.log(_classString, 'ERROR sending message to telegram or register', exception: e, level: Level.SEVERE);
      if (mounted) {
        myAlertDialog(
            context,
            'Ha habido una incidencia al enviar el mensaje de confirmación\n'
            'Comprueba que se ha enviado el mensaje al registro y al telegram\n'
            'Error = $e');
      }

      return false;
    }

    return true;
  }

  Future<bool> _confirmLoggedUserOutOfMatch() async {
    const String option1 = 'Confirmar';
    const String option2 = 'Anular';
    String response = await myReturnValueDialog(context, '¿Seguro que quieres darte de baja?', option1, option2);
    MyLog.log(_classString, '_confirmLoggedUserOutOfMatch sign off the match = $response');
    return response == option1;
  }

  Widget signUpAdminForm() {
    List<MyUser> users = appState.sortUsers;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 3,
            child: SizedBox(
              height: 260,
              child: ListWheelScrollView(
                itemExtent: 40,
                magnification: 1.3,
                useMagnifier: true,
                diameterRatio: 2,
                squeeze: 0.7,
                offAxisFraction: -0.3,
                perspective: 0.01,
                physics: const FixedExtentScrollPhysics(),
                scrollBehavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown
                  },
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedUser = users[index];
                  });
                },
                children: users
                    .map((u) => Container(
                          margin: const EdgeInsets.fromLTRB(50, 0, 20, 0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25), color: Theme.of(context).colorScheme.surface),
                          child: Center(
                              child: Text(u.name,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ))),
                        ))
                    .toList(),
              ),
            ),
          ),
          const Spacer(),
          Flexible(
              flex: 2,
              child: Builder(
                builder: (context) {
                  bool isSelectedUserInTheMatch = context.read<MatchNotifier>().match.isInTheMatch(selectedUser);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            (isSelectedUserInTheMatch ? 'Dar de baja a:\n\n' : 'Apuntar a:\n\n') + selectedUser.name,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        onPressed: () => validate(
                          user: selectedUser,
                          toAdd: !isSelectedUserInTheMatch,
                          adminManagingUser: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Opacity(
                        opacity: isSelectedUserInTheMatch ? 0 : 1,
                        child: Form(
                            child: TextFormField(
                          enabled: !isSelectedUserInTheMatch,
                          decoration: const InputDecoration(
                            labelText: 'Posición',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(4.0)),
                            ),
                          ),
                          onFieldSubmitted: (String str) async => validate(
                            user: selectedUser,
                            toAdd: true,
                            adminManagingUser: true,
                          ),
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true),
                          ],
                          controller: userPositionController,
                          // The validator receives the text that the user has entered.
                        )),
                      ),
                    ],
                  );
                },
              ))
        ],
      ),
    );
  }
}
